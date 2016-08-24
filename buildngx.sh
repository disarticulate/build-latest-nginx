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






/******************************************************************************/

$NCHAN_RELEASE="0.99.16";


$prefix_dir         =   '/etc/nginx';

$conf_path          =   $prefix_dir.DIRECTORY_SEPARATOR.'nginx.conf';

$cache_dir          =   "/var/cache/nginx";

$www_user           =   "www-data";

$www_group          =   "www-data";

/******************************************************************************/

$options            =   getopt("sqhpr",['s','q','h','p','r']);

if(in_array('check',$argv)){
    echo `2>&1 nginx -V |cut -d "-"  -f1`;
    echo PHP_EOL;
    echo `2>&1 nginx -V |tr ' '  '\n'|grep -e '--'`;
    exit();
}

chdir('/usr/local/src/');

$current_dir        =   getcwd();

system("apt-get    make automake patch gcc geoip-database openssl libhiredis-dev  libssl-dev libpcre3 
libpcre3-dev perl-modules libghc-zlib-dev libtool gettext  wget curl build-essential zlib1g-dev libperl-dev 
libgd2-xpm-dev libjemalloc-dev python-geoip libxml2 libxml2-dev libxml2-utils apache2-threaded-dev 
libcurl3-dev unzip");

include 'functions.php';

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

    echo "-s, --s  Set server string to:".PHP_EOL;
    echo "check  : Show existing nginx compile options (nginx -V pretty printed)".PHP_EOL;

    exit(0);
}

$downloadurl        =   'http://nginx.org/download/' . $lv['file'];
$build_dir          =   $current_dir.DIRECTORY_SEPARATOR.'nginxsrc';
$build_dir_ngx      =   $build_dir . DIRECTORY_SEPARATOR . 'nginx-' . $lv['version'];


$push_str           =   ask("Build NCHAN {$NCHAN_RELEASE} ?"    ,true,false) ? " --add-dynamic-module={$build_dir_ngx}/nchan-$NCHAN_RELEASE " : "";
$st_str             =   ask('Build sticky module ?'              ,true,false) ? " --add-dynamic-module={$build_dir_ngx}/nginx-goodies-nginx-sticky-module " : "";
$hm_str             =   ask("Build headers more  ?"             ,true,false) ? " --add-dynamic-module={$build_dir_ngx}/headers-more-nginx-module " : "";
$upf_str            =   ask("Build upstream fair ?"             ,true,false) ? " --add-dynamic-module={$build_dir_ngx}/nginx-upstream-fair " : "";



$myname             =   `whoami`;     

$nor                =   ($myname=='root')?"":"Please make sure that your user {$myname} can write to the install destinations.";


# reference :   https://www.nginx.com/resources/wiki/start/topics/tutorials/installoptions/

$configure          =   "./configure        \
--prefix={$prefix_dir}                      \
--conf-path={$conf_path}                    \
--sbin-path=/usr/sbin/nginx                 \
--modules-path=/usr/lib/nginx/modules       \
--pid-path=/var/run/nginx.pid               \
--lock-path=/var/run/nginx.lock             \
--error-log-path=/var/log/nginx/error.log   \
--http-log-path=/var/log/nginx/access.log   \
--http-client-body-temp-path={$cache_dir}/client_temp   \
--http-proxy-temp-path={$cache_dir}/proxy_temp          \
--http-fastcgi-temp-path={$cache_dir}/fastcgi_temp      \
--http-uwsgi-temp-path={$cache_dir}/uwsgi_temp          \
--http-scgi-temp-path={$cache_dir}/scgi_temp            \
--user={$www_user} --group={$www_group}                 \
--with-pcre-jit \
--with-ipv6 \
--with-file-aio \
--with-http_ssl_module \
--with-stream_ssl_module \
--with-http_stub_status_module \
--with-http_realip_module \
--with-http_auth_request_module \
--with-http_v2_module \
--with-threads \
--with-http_geoip_module=dynamic \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_image_filter_module=dynamic \
--with-http_mp4_module \
--with-http_perl_module=dynamic \
--with-http_secure_link_module \
--with-http_xslt_module=dynamic \
{$push_str} \
{$st_str}  \
{$hm_str} \
{$upf_str} \
";


/*--with-http_gunzip_module
--with-http_slice_module         \\
--with-http_gzip_static_module      \
--with-http_secure_link_module      \
--with-http_stub_status_module      \
--with-http_auth_request_module
nginx-cache-purge
*/

 /* process */

$quiet              =   isset($options['q']);
$rebuild            =   isset($options['r']);

echo PHP_EOL,"Latest available NGINX is:" , PHP_EOL , "\t**********\t{$lv['version']}" , PHP_EOL;


if($server==false){
 $server = trim(ask("Change the server string (nginx) to:"));
}




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
        passthru("curl -L https://github.com/slact/nchan/archive/v{$NCHAN_RELEASE}.tar.gz|tar xz");


} 

if (strlen($st_str)and !$rebuild) {
    passthru('curl  https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/master.tar.gz|tar xz && mv nginx-goodies-nginx-sticky-module-* nginx-goodies-nginx-sticky-module');
}

if (strlen($hm_str) and !$rebuild) {
    passthru('git clone --depth=1    https://github.com/openresty/headers-more-nginx-module.git');
}

if (strlen($upf_str) and !$rebuild) {
    passthru('git clone --depth=1    https://github.com/p34eu/nginx-upstream-fair.git');
}



$savec=getcwd().'/configure.used';

echo $configure.PHP_EOL.PHP_EOL;
 
file_put_contents($savec,$configure);

echo "Saved rules into {$savec}".PHP_EOL ;

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
if(ask('run make install? (y)',true,0)){

    system('make install',$s3);

    if(!$s3==0){
        echo "Aborted!".PHP_EOL;
        die();
    }else{
        echo "ALL DONE!".PHP_EOL;
        echo `2>&1 nginx -V |cut -d "-"  -f1`;
    }

}else{

    echo "Compilation is done. Run \"make install\" to install".PHP_EOL;
}

if(!file_exists($cache_dir)){
    mkdir($cache_dir);
}

echo "Recommendation: set worker_processes to ";

echo `grep processor /proc/cpuinfo | wc -l`;

echo "Don't forget to restart the nginx. I.e. service nginx restart'";

exit(PHP_EOL);
