# debian-latest-nginx   [![Build Status](https://travis-ci.org/p34eu/debian-latest-nginx.svg?branch=master)](https://travis-ci.org/p34eu/debian-latest-nginx)

 Script to download and build at once :

  *  <a href="http://nginx.org/download">nginx</a>

  *  <a href="http://github.com/wandenberg/nginx-push-stream-module.git">push-stream-module</a> (optional)

  *  <a href="https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng">nginx-sticky-module</a> (optional)

Optionally it allows to change the <b>server string</b> returned in http headers.

It takes less than a minute to download and build everything.

Tested on Debian 8.4 (jessie). Required packages:  <code>build-essentials libpcre3-dev  libssl-dev curl php5-cli libgeoip-dev libxslt1-dev </code> (apt-get install)
         


### Usage:

 1. Clone this repo or download the script via curl/wget. <i>Do not copy/paste it from browser.</i>

 2. Review the configure lines. You might want to add/remove modules/options.

 3. Run <code>buildngx.sh</code>. and answer the questions. It will ask for push & sticky modules and what server string you want, unless -q is specified.
 
 4. If compile is ok, it will ask to <code>make install</code>.
 
 5. If you had nginx before on the same server, systemd and sysv configurations can be used without any change. If not, they will be installed, unless answer is no. Provided configure options correspond to debian defaults. Systemd service file contains some standart systemd unit features added on top of the default debian ones. Please review them.
 


### Options:
Option | Meaning
------------ | -------------
  -q, --q | Don't ask any questions. Download and build all modules, preserve "nginx" as server string, if -s is not specified. Ask only for <code>make install</code> at the end.
  -p, --p | Show latest version of nginx from nginx.org and exit
  -s, --s | Set server string to:
  -h, --h | Show help and exit


### Notes:

If you run this script on virgin system, i.e. nginx was not installed before, make sure  directory specified for cache in configure script exists, before attempting to start nginx.
Also, have look at provided etc/ subfolder, where are the important files from debian package, i.e. for logrotate and /etc/default
 
### FAQ:
 Q. Why is this?

 A. Main reason: enable/disable modules at compile time and play with the latest version.
 
### Example output of nginx -V

nginx -V
nginx version: nginx/1.10.0
<code><pre>
built by gcc 4.9.2 (Debian 4.9.2-10) 
built with OpenSSL 1.0.1k 8 Jan 2015
TLS SNI support enabled
configure arguments: --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules
--conf-path=/etc/nginx/nginx.conf
--pid-path=/var/run/nginx.pid
--lock-path=/var/run/nginx.lock
--error-log-path=/var/log/nginx/error.log
--http-log-path=/var/log/nginx/access.log
--http-client-body-temp-path=/var/cache/nginx/client_temp
--http-proxy-temp-path=/var/cache/nginx/proxy_temp
--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp
--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp
--http-scgi-temp-path=/var/cache/nginx/scgi_temp
--user=www-data
--group=www-data
--with-http_ssl_module
--with-stream_ssl_module
--with-http_realip_module
--with-http_gunzip_module
--with-http_gzip_static_module
--with-http_secure_link_module
--with-http_stub_status_module
--with-http_auth_request_module 
--with-http_xslt_module=dynamic
--with-http_geoip_module=dynamic 
--with-http_slice_module
--with-http_v2_module 
--with-file-aio
--with-threads 
--with-stream
</pre></code>
