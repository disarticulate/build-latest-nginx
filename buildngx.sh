#!/usr/bin/php
<?php
/*
*       https://github.com/p34eu/debian-latest-nginx
*
*       Check  build dir and configure options.
*       Change as you need. do not leave empty lines, leave space before ending \
*
*
*       WARNING -  Do not copy/paste this script from browser.
*       Download it via curl/git/wget or patch will fail.
*
*
*/
$current_dir=getcwd();

$build_dir          =   '/opt/nginxsrc';  // where this script should operate.

$install_systemd    =   true; //install systemd service file? Valid when -s


$push_str = '';     //leave empty.
$st_str = '';       //leave empty.

$configure          =   "./configure \
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib/nginx/modules \
--conf-path=/etc/nginx/nginx.conf \
--pid-path=/var/run/nginx.pid \
--lock-path=/var/run/nginx.lock \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--http-client-body-temp-path=/var/cache/nginx/client_temp \
--http-proxy-temp-path=/var/cache/nginx/proxy_temp \
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
--http-scgi-temp-path=/var/cache/nginx/scgi_temp \
--user=www-data --group=www-data \
--with-http_ssl_module \
--with-stream_ssl_module \
--with-http_realip_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_secure_link_module \
--with-http_stub_status_module \
--with-http_auth_request_module \
--with-http_xslt_module=dynamic \
--with-http_geoip_module=dynamic \
--with-http_slice_module \
--with-http_v2_module $push_str $st_str  --with-file-aio \
--with-threads \
--with-stream";

// /lib/systemd/system/nginx.service
$systemdconf="# Stop dance for nginx
# =======================
#
# ExecStop sends SIGSTOP (graceful stop) to the nginx process.
# If, after 5s (--retry QUIT/5) nginx is still running, systemd takes control
# and sends SIGTERM (fast shutdown) to the main process.
# After another 5s (TimeoutStopSec=5), and if nginx is alive, systemd sends
# SIGKILL to all the remaining processes in the process group (KillMode=mixed).
#
# nginx signals reference doc:
# http://nginx.org/en/docs/control.html
#
[Unit]
Description=A high performance web server and a reverse proxy server
After=network.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
";


/*                            end of config
------------------------------------------------------------------------------
*/


$options=getopt("sqhp",['s','q','h','p']);

$quiet      =   isset($options['q']);
$showonly   =   isset($options['p']);
$server=!empty($options['s'])?$options['s']:false;

if($showonly){
    echo latest()['version'];
    echo(PHP_EOL);
    exit(0);
}

if(isset($options['h'])){
    echo "Options:".PHP_EOL;
    echo "-h, --h  this message.".PHP_EOL;
    echo "-p, --p  Show latest available nginx version and exit".PHP_EOL;
    echo "-q, --q  Don't ask any questions. Build all modules, do not change server string.".PHP_EOL;
    echo "-s, --s  Set server string to:".PHP_EOL;
    exit(0);
}


function ask($q, $yn = false, $abort = true)
{
    echo $q . PHP_EOL;
    $handle = fopen("php://stdin", "r");
    $line = fgets($handle);
    fclose($handle);
    $line = preg_replace('~[[:cntrl:]]~', '', $line);
    if ($yn) {
        if (substr(strtolower(trim($line)), 0, 1) !== 'y') {
            if ($abort) {
                echo "Script aborted!", PHP_EOL;
                die();
            } else {
                return false;
            }
        } else {
            return true;
        }
    }
    return $line;
}
function latest(){
    // get current nginx version
    $n = [];
    exec("curl -s http://nginx.org/download/|grep \"tar.gz<\"|grep nginx|sed 's/.*href=\"//'|sed 's/\".*//'|grep '^[a-zA-Z].*'", $out);
    foreach ($out as $k => $v) {
        $t = str_replace(['.tar.gz', 'nginx-'], '', $v);
        list($major, $minor, $patch) = explode('.', $t);
        $n[sprintf('%02s', $major) . sprintf('%02s', $minor) . sprintf('%02s', $patch)] = ['version' => $t, 'file' => $v];
    }
    ksort($n);
    $lv=end($n);
    if(empty($lv)){
        die('failed to get the latest version from nginx.org');
    }
    return $lv;
}

$lv=latest();
$downloadurl = 'http://nginx.org/download/' . $lv['file'];

if(!$quiet){
    ask("Latest available NGINX is:" . PHP_EOL . "\t**********\t{$lv['version']}" . PHP_EOL . "Continue building {$downloadurl} ? (y|n)" . PHP_EOL, true);

    // ask to change server string.
    if($server==false){
      $server = trim(ask("Change the server string (nginx) to:"));
    }
    if (!$build_push = ask('Build push stream module from http://github.com/wandenberg/nginx-push-stream-module.git?(y|n)', true, false)) {
        echo 'Skipping.' . PHP_EOL;
    };
    if (!$build_sticky = ask('Build sticky upstream module from https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng?(y|n)', true, false)) {
        echo 'Skipping.' . PHP_EOL;
    }
    if (!$build_init = ask('Install /etc/init.d/nginx and systemd files? (y|n)', true, false)) {
        echo 'Skipping.' . PHP_EOL;
    }
}else{
    $build_push=true;
    $build_sticky=true;
    $build_init=true;
}

$build_dir_ngx = $build_dir . DIRECTORY_SEPARATOR . 'nginx-' . $lv['version'];

echo PHP_EOL,"Diving to ", $build_dir_ngx, PHP_EOL;

if (file_exists($build_dir_ngx)) {
    $stamp = time();
    `mv $build_dir_ngx $build_dir_ngx.'_old_'.$stamp`;
}
mkdir($build_dir_ngx, 0664, true) or die('Failed to create '.$build_dir_ngx.PHP_EOL);

chdir($build_dir) or die('failed to change direcory to '.$build_dir.PHP_EOL);
`curl {$downloadurl}|tar xz`;
chdir($build_dir_ngx) or die('failed to change direcory to '.$build_dir_ngx.PHP_EOL);

if (!empty($server) && strlen($server) > 0) {
    $patch1 = '--- src/http/ngx_http_header_filter_module.c
+++ src/http/ngx_http_header_filter_module.c
@@ -46,8 +46,8 @@
 };


-static char ngx_http_server_string[] = "Server: nginx" CRLF;
-static char ngx_http_server_full_string[] = "Server: " NGINX_VER CRLF;
+static char ngx_http_server_string[] = "Server: ' . $server . '" CRLF;
+static char ngx_http_server_full_string[] = "Server: ' . $server . '" CRLF;


 static ngx_str_t ngx_http_status_lines[] = {
';


    $patch2 = '--- src/http/ngx_http_special_response.c
+++ src/http/ngx_http_special_response.c
@@ -19,14 +19,12 @@


 static u_char ngx_http_error_full_tail[] =
-"<hr><center>" NGINX_VER "</center>" CRLF
 "</body>" CRLF
 "</html>" CRLF
 ;


 static u_char ngx_http_error_tail[] =
-"<hr><center>nginx</center>" CRLF
 "</body>" CRLF
 "</html>" CRLF
 ;
';
    file_put_contents('patch1.patch', $patch1);
    file_put_contents('patch2.patch', $patch2);
    passthru('patch -p0<patch1.patch');
    passthru('patch -p0<patch2.patch');
    echo 'Server string set to: ' . $server . PHP_EOL;
}

if ($build_push) {
    passthru("git clone http://github.com/wandenberg/nginx-push-stream-module.git");
}

if ($build_sticky) {
    passthru('curl  https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/master.tar.gz|tar xz && mv nginx-goodies-nginx-sticky-module-* nginx-goodies-nginx-sticky-module');
}

$push_str = $build_push ? " --add-module=$build_dir_ngx/nginx-push-stream-module " : "";

$st_str = $build_sticky ? " --add-module=$build_dir_ngx/nginx-goodies-nginx-sticky-module " : "";

passthru($configure);
passthru('make');

$nor=$_SERVER['USERNAME']=='root'?"":"Please make sure that your user {$_SERVER['USERNAME']} can write to the install destinations.";

if(ask("Configure done. Do you want to install it (make install) ?".PHP_EOL.$nor.PHP_EOL."(y|n)", 1,0)){
    passthru('make install');
}else{
    echo "Not installing. To install or examine code, go to:".PHP_EOL.$build_dir_ngx.PHP_EOL;
}

if ($build_init) {
    
    if(!file_exists('/etc/init.d/nginx') and file_exists($current_dir.'/etc/init.d/nginx')){
        
        copy($current_dir.'/etc/init.d/nginx','/etc/init.d/nginx');
        passthru('update-rc.d nginx defaults');
        passthru('invoke-rc.d nginx configtest');
        
    }else{
        echo PHP_EOL."Skipping init script creation.".PHP_EOL;
    }

    if($install_systemd ){
                
        if(file_exists('/lib/systemd/system/nginx.service')){
            echo PHP_EOL.'/lib/systemd/system/nginx.service EXISTS'.PHP_EOL; 
        }else{        
            file_put_contents('/lib/systemd/system/nginx.service',$systemdconf);        
            passthru('systemctl daemon-reload');
            passthru('systemctl enable nginx.service');
            passthru('systemctl unmask nginx.service');
            passthru('systemctl start nginx.service');
            passthru('systemctl status nginx');       
        }
    }
}


echo "Recommendation: set worker_processes to ";
echo `grep processor /proc/cpuinfo | wc -l`;

exit(PHP_EOL);
