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
*       Download it via curl/git/wget or patch will probably fail.
*
*
*/

include 'functions.php';

$options            =   getopt("sqhpr",['s','q','h','p','r']);

$current_dir        =   getcwd();

$lv                 =   latest();



$server=!empty($options['s'])?$options['s']:false;

if( isset($options['p'])){
    echo latest()['version'];
    echo(PHP_EOL);
    exit(0);
}

if(isset($options['h'])){
    echo "Options:".PHP_EOL;
    echo "-h, --h  this message.".PHP_EOL;
    echo "-p, --p  Show latest available nginx version and exit".PHP_EOL;
    echo "-q, --q  Ask less and keep server string to nginx.".PHP_EOL;
    echo "-s, --s  Set server string to:".PHP_EOL;
    exit(0);
}


$downloadurl        =   'http://nginx.org/download/' . $lv['file'];

$build_dir          =   $current_dir.DIRECTORY_SEPARATOR.'nginxsrc';
$build_dir_ngx      =   $build_dir . DIRECTORY_SEPARATOR . 'nginx-' . $lv['version'];

$install_init       =   false;
$install_systemd    =   false;



$prefix_dir         =   '/etc/nginx';

$conf_path          =   $prefix_dir.DIRECTORY_SEPARATOR.'nginx.conf';

$cache_dir          =   "/var/cache/nginx";

$www_user           =   "www-data";
$www_group          =   "www-data";


$push_str           =   ask('enable push stream     module?',true,false) ? " --add-module={$build_dir_ngx}/nginx-push-stream-module " : "";
$modsec_str         =   ask('enable mod security    module?',true,false) ? " --add-module={$build_dir_ngx}/ModSecurity/nginx/modsecurity  " : "";
$st_str             =   ask('enable sticky          module?',true,false) ? " --add-module={$build_dir_ngx}/nginx-goodies-nginx-sticky-module " : "";
$pgs_str            =   ask('enable pagespeed       module?',true,false) ? " --add-module={$build_dir_ngx}/ngx_pagespeed " : "";
$NPS_VERSION        =   '1.11.33.2';

$myname             =   `whoami`;     

$nor                =   ($myname=='root')?"":"Please make sure that your user {$myname} can write to the install destinations.";


# reference :   https://www.nginx.com/resources/wiki/start/topics/tutorials/installoptions/

$configure          =   "./configure        \
\
--prefix={$prefix_dir}                      \
--conf-path={$conf_path}                    \
--sbin-path=/usr/sbin/nginx                 \
\
--modules-path=/usr/lib/nginx/modules       \
\
--pid-path=/var/run/nginx.pid               \
--lock-path=/var/run/nginx.lock             \
\
--error-log-path=/var/log/nginx/error.log   \
--http-log-path=/var/log/nginx/access.log   \
\
--http-client-body-temp-path={$cache_dir}/client_temp   \
--http-proxy-temp-path={$cache_dir}/proxy_temp          \
--http-fastcgi-temp-path={$cache_dir}/fastcgi_temp      \
--http-uwsgi-temp-path={$cache_dir}/uwsgi_temp          \
--http-scgi-temp-path={$cache_dir}/scgi_temp            \
\
--user={$www_user} --group={$www_group}                 \
\
--with-ipv6 \
--with-http_v2_module \
--with-http_ssl_module              \
--with-stream_ssl_module            \
--with-http_realip_module           \
--with-http_gunzip_module           \
--with-http_gzip_static_module      \
--with-http_secure_link_module      \
--with-http_stub_status_module      \
--with-http_auth_request_module     \
--with-http_xslt_module=dynamic     \
--with-http_geoip_module=dynamic    \
--with-http_slice_module            \
{$modsec_str}                       \
{$push_str}                         \
{$st_str}                           \
{$pgs_str}                          \
--with-file-aio                     \
--with-threads                      \
--with-stream";

# /lib/systemd/system/nginx.service

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

#OPTIONAL,  READ THE DOCS FIRST:

#The service gets its own instance of /var,/tmp
PrivateTmp=true

#Only exposes API pseudo-devices (/dev/nukk,zero,random)
PrivateDevices=true

#makes /usr/,boot and /etc read-only
ProtectSystem=full

#Prevents access to /home, /root, and /run/user
ProtectHome=true


[Install]
WantedBy=multi-user.target
";


 /* process */

$quiet              =   isset($options['q']);
$rebuild            =   isset($options['r']);

if(!$quiet){
    ask("Latest available NGINX is:" . PHP_EOL . "\t**********\t{$lv['version']}" . PHP_EOL . "Continue building {$downloadurl} ? (Y|n)" . PHP_EOL, true,true);
    // ask to change server string.
    if($server==false){
      $server = trim(ask("Change the server string (nginx) to:"));
    }
} 
system("apt-get -y  install make automake patch gcc geoip-database openssl \
    libssl-dev libpcre3 libpcre3-dev perl-modules libghc-zlib-dev libtool gettext \
    wget curl build-essential zlib1g-dev libperl-dev libjemalloc-dev python-geoip \
    libxml2 libxml2-dev libxml2-utils apache2-threaded-dev libcurl3-dev unzip");

echo PHP_EOL,"Diving to ", $build_dir_ngx, PHP_EOL;

if (file_exists($build_dir_ngx) and !$rebuild) {    
    $stamp = time();
    `mv $build_dir_ngx $build_dir_ngx.'_old_'.$stamp`;
}
if(!$rebuild){
    mkdir($build_dir_ngx, 0664, true) or die('Failed to create '.$build_dir_ngx.PHP_EOL);
}


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



 
if (strlen($push_str) and !$rebuild) {
    passthru("git clone --depth=1  http://github.com/wandenberg/nginx-push-stream-module.git");
} 

if (strlen($st_str)and !$rebuild) {
    passthru('curl  https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/master.tar.gz|tar xz && mv nginx-goodies-nginx-sticky-module-* nginx-goodies-nginx-sticky-module');
}
if (strlen($pgs_str) and !$rebuild) {
    passthru('git clone --depth=1  https://github.com/pagespeed/ngx_pagespeed.git');
    passthru('curl https://dl.google.com/dl/page-speed/psol/'.$NPS_VERSION.'.tar.gz|tar xz && mv psol/ ngx_pagespeed/');
 
}
 


if(strlen($modsec_str)) {
    if(!$rebuild){ 
        
    passthru("git clone https://github.com/SpiderLabs/ModSecurity.git");
    passthru("git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git");

    chdir($build_dir_ngx.'/ModSecurity');
    echo 'apache libs needed by modsecurity, see :https://github.com/SpiderLabs/ModSecurity/issues/661';
    `apt-get install automake autoconf libtool apache2-threaded-dev`;
    
    passthru('./autogen.sh');
    system('./configure --enable-standalone-module --disable-mlogc',$s000);
    system('make && make install',$s001);  
    if(!$s001==0||!$s000==0){        
        echo "Aborted due to errors!!".PHP_EOL;            
        die();                    
    }  
    echo "Returning back to NGINX build  {$build_dir_ngx}";
    
    chdir($build_dir_ngx);
    }
}



 




$savec=getcwd().'/configure.used';

echo $configure.PHP_EOL.PHP_EOL;
 
file_put_contents($savec,$configure);

echo "Saved rules into {$savec}" ;

sleep(2);

system($configure,$s1);

if(!$s1==0){    
    echo "Aborted!".PHP_EOL;
    die();
}

system('make',$s2);           

if(!$s2==0){        
    echo "Aborted due to errors!!".PHP_EOL."Make returned exit code: {$s2}".PHP_EOL;            
    die();                    
}                        
                        

if(!ask("Configure done. Do you want to install it (make install) ?".PHP_EOL.$nor.PHP_EOL."(y|n)", 1,0)){
     echo "Not installing. To install or examine code, go to:".PHP_EOL.$build_dir_ngx.PHP_EOL." and run :".PHP_EOL."make install ".PHP_EOL;
     exit();
}


system('make install',$s3);      

if(!$s3==0){        
    echo "Aborted!".PHP_EOL;
      die();
 }

if(!file_exists($cache_dir)){
    mkdir($cache_dir);
}
if($build_modsec){
    `cp {$build_dir_ngx}/ModSecurity/modsecurity.conf-recommended {$prefix_dir}/modsecurity.conf`;
    `cp {$build_dir_ngx}/ModSecurity/unicode.mapping {$prefix_dir}/`;
    `cp -Rv {$build_dir_ngx}/owasp-modsecurity-crs/base_rules {$prefix_dir}/base_rules`;
    if(!file_exists('/opt/modsecurity/var/audit/')){
        mkdir('/opt/modsecurity/var/audit/',true);
        exec("chown  -R {$www_user}:{$www_group} /opt/modsecurity/var/audit");
    }
    
    if(ask('Do you want to do basic configuration on ModSecurity?',true,false)){
        cfg("SecRuleEngine","On",true,"{$prefix_dir}/modsecurity.conf");
        cfg("SecRequestBodyLimit","100000000",true,"{$prefix_dir}/modsecurity.conf");
        cfg("SecAuditLogType","Concurrent",true,"{$prefix_dir}/modsecurity.conf");
        cfg("SecAuditLogStorageDir","/opt/modsecurity/var/audit/",true,"{$prefix_dir}/modsecurity.conf");
        cfg("SecDefaultAction",'"log,deny,phase:1"',true,"{$prefix_dir}/modsecurity.conf");
        cfg("Include",'"log,deny,phase:1"',true,"{$prefix_dir}/modsecurity.conf");
    }
}

if ($install_init) {    
    if(!file_exists('/etc/init.d/nginx') and file_exists($current_dir.'/etc/init.d/nginx')){        
        copy($current_dir.'/etc/init.d/nginx','/etc/init.d/nginx');
        passthru('chmod +x /etc/init.d/nginx');
        passthru('update-rc.d nginx defaults');
        passthru('invoke-rc.d nginx configtest');        
    }else{
        echo PHP_EOL."Skipping init script creation.".PHP_EOL;
    }  
}

if($install_systemd ){                
        if(file_exists('/lib/systemd/system/nginx.service')){
            echo PHP_EOL.'/lib/systemd/system/nginx.service EXISTS, not changed'.PHP_EOL;
        }else{        
            file_put_contents('/lib/systemd/system/nginx.service',$systemdconf);        
            passthru('systemctl daemon-reload');
            passthru('systemctl enable nginx.service');
            passthru('systemctl unmask nginx.service');
            passthru('systemctl status nginx');       
        }
}


echo "Recommendation: set worker_processes to ";
echo `grep processor /proc/cpuinfo | wc -l`;

echo "Don't forget to restart the nginx. I.e. service nginx restart'";

exit(PHP_EOL);
