#!/usr/bin/php
#
#       
#       WARNING -  Do not copy/paste this script from browser. Download it via curl/git/wget or patch will fail.
#   
<?php
/*    
*                                   https://github.com/p34eu/debian-latest-nginx
*       
*       Check  build dir and configure options. Change as you need. do not leave empty lines, leave space before ending \
* 
*/

$build_dir = '/opt/nginxsrc';  // where this script should operate. 


$push_str = '';     //leave empty.
$st_str = '';       //leave empty.

$configure = "./configure \
--prefix=/etc/nginx \
--sbin-path=/usr/sbin/nginx \
--modules-path=/usr/lib/nginx/modules \
--conf-path=/etc/nginx/nginx.conf \
--pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock \
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

/*                            end of config
------------------------------------------------------------------------------
*/


$n = [];
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

// get current nginx version
exec("curl -s http://nginx.org/download/|grep \"tar.gz<\"|grep nginx|sed 's/.*href=\"//'|sed 's/\".*//'|grep '^[a-zA-Z].*'", $out);
foreach ($out as $k => $v) {
    $t = str_replace(['.tar.gz', 'nginx-'], '', $v);
    list($major, $minor, $patch) = explode('.', $t);
    $n[sprintf('%02s', $major) . sprintf('%02s', $minor) . sprintf('%02s', $patch)] = ['version' => $t, 'file' => $v];
}
ksort($n);
$lv = end($n);

$downloadurl = 'http://nginx.org/download/' . $lv['file'];

ask("Latest available NGINX is:" . PHP_EOL . "\t**********\t{$lv['version']}" . PHP_EOL . "Continue building {$downloadurl} ? (y|n)" . PHP_EOL, true);

// ask to change server string.

$server = trim(ask("Change the server string (nginx) to:"));

if (!$build_push = ask('Build push stream module from http://github.com/wandenberg/nginx-push-stream-module.git?(y|n)', true, false)) {
    echo 'Skipping.' . PHP_EOL;
};
if (!$build_sticky = ask('Build sticky upstream module from https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng?(y|n)', true, false)) {
    echo 'Skipping.' . PHP_EOL;
}
if (!$build_init = ask('Build sysvinit script from https://github.com/Fleshgrinder/nginx-sysvinit-script.git? (y|n)', true, false)) {
    echo 'Skipping.' . PHP_EOL;
}

$build_dir_ngx = $build_dir . DIRECTORY_SEPARATOR . 'nginx-' . $lv['version'];

echo PHP_EOL,"Diving to ", $build_dir_ngx, PHP_EOL;

if (file_exists($build_dir_ngx)) {
    $stamp = time();
    `mv $build_dir_ngx $build_dir_ngx.'_old_'.$stamp`;
}
mkdir($build_dir_ngx, 0664, true);

chdir($build_dir);
`curl {$downloadurl}|tar xz`;
chdir($build_dir_ngx);

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
    chdir($build_dir_ngx);
    passthru('git clone https://github.com/Fleshgrinder/nginx-sysvinit-script.git');
    echo "INIT script downloaded at:", PHP_EOL;
    echo $build_dir_ngx . DIRECTORY_SEPARATOR . 'nginx-sysvinit-script', PHP_EOL;
    echo 'To install, go there and type "make"', PHP_EOL;
}

if (!file_exists('/var/cache/nginx')) {
    echo "WARNING: /var/cache/nginx does not exits. You might need to create it by hand, or nginx will not start", PHP_EOL;
}

echo "Recommendation: set worker_processes to ";

echo `grep processor /proc/cpuinfo | wc -l`;

exit(PHP_EOL);
