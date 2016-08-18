# build-latest-nginx   [![Build Status](https://travis-ci.org/p34eu/build-latest-nginx.svg?branch=master)](https://travis-ci.org/p34eu/build-latest-nginx)

 Tool to download and build nginx + custom <b><u>dynamic</u></b> modules  

  *     <a href="http://nginx.org/download">NGINX for linux</a>
  *     <a href="https://nchan.slact.net/">Nchan</a>  
  *     <a href="https://www.nginx.com/resources/wiki/modules/headers_more/">ngx_headers_more</a>  
  *     <a href="https://www.nginx.com/resources/wiki/modules/fair_balancer/?highlight=upstream%20fair">ngx_http_upstream_fair_module</a> 
  *     <a href="https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng">nginx_sticky_module</a> 
  *     geoip_module
  *     image_filter_module
  *     perl_module
  *     xslt_module


Optionally it allows to change the <b>server string returned in http headers</b> .

Tested on Debian 8.4 (jessie). With  small changes works also on Centos.

Required packages for tool to operate and build above modules:

```sh
apt-get install build-essential libpcre3-dev  libssl-dev curl unzip php5-cli libgeoip-dev libxslt1-dev
```
         

### Usage:

 1. Clone this repo or download the script  and functions.php via curl/wget. <i>Do not copy/paste it from browser.</i>

 2. Review the configure lines inside <code>buildngx.sh</code>. You might want to <b>add/remove</b> the default modules/options.

 3. Run <code>buildngx.sh</code>. and answer the questions. It will ask for which modules to be made and for <b>server string</b> to use, unless -q is specified.
 
 4. If compile is ok, it will ask to <code>make install</code>.
 

### Options:
Option | Meaning
------------ | -------------
  -p, --p | Show latest version of nginx from nginx.org and exit
  -r, --r | do not download again sources, just re-run configure and compile process.
  -s, --s | Set server string to:
    check | Show existing NGINX version and modules
  -h, --h | Show help and exit


### Notes:

If you run this script on virgin system, i.e. nginx was not installed before, make sure  directory specified for cache in configure script exists, 
before attempting to start nginx. It is also possible to first install debian nginx to create all defaults.

 
### FAQ:
 Q. Why is this?

 A. Most of the comunity NGINX modules can only be enabled / disabled by recompiling NGINX. This tool was made to speedup collecting sources and building them.
 
