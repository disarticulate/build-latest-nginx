# build-latest-nginx   [![Build Status](https://travis-ci.org/p34eu/build-latest-nginx.svg?branch=master)](https://travis-ci.org/p34eu/build-latest-nginx)

 Tool to download and build nginx + custom modules list

  *  <a href="http://nginx.org/download">NGINX for linux</a>

  *  <a href="https://developers.google.com/speed/pagespeed/module/">page speed module</a>  

  *  <a href="http://github.com/wandenberg/nginx-push-stream-module.git">push stream module</a> 

  *  <a href="https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng"> sticky module</a> 

  
Optionally it allows to change the <b>server string</b> returned in http headers.

Tested on Debian 8.4 (jessie). With  small changes works also on Centos.

Required packages for tool to operate and build above modules:

```sh
apt-get install build-essential libpcre3-dev  libssl-dev curl unzip php5-cli libgeoip-dev libxslt1-dev
```
         


### Usage:

 1. Clone this repo or download the script  and functions.php via curl/wget. <i>Do not copy/paste it from browser.</i>

 2. Review the configure lines inside <code>buildngx.sh</code>. You might want to <b>add/remove</b> modules/options.

 3. Run <code>buildngx.sh</code>. and answer the questions. It will ask for which modules to be made and for server to use, unless -q is specified.
 
 4. If compile is ok, it will ask to <code>make install</code>.
 
 5. If you had nginx before on the same server, systemd and sysv configurations can be used without any change. 
 If not, they can be installed if the script is configured to do so. 
 
 6. Provided configure options correspond to debian defaults. 
 Systemd service file contains some standart systemd unit features added on top of the default debian ones.
 Please review them.
 


### Options:
Option | Meaning
------------ | -------------
  -q, --q | Don't ask many questions. Download and build all modules, preserve "nginx" as server string, if -s is not specified. Ask only for <code>make install</code> at the end.
  -p, --p | Show latest version of nginx from nginx.org and exit
  -r, --r | do not download again sources, just re-run configure and compile process.
  -s, --s | Set server string to:
  -h, --h | Show help and exit


### Notes:

If you run this script on virgin system, i.e. nginx was not installed before, make sure  directory specified for cache in configure script exists, 
before attempting to start nginx. It is also possible to first install debian nginx to create all  structure.
 
### FAQ:
 Q. Why is this?

 A. Most of the comunity NGINX modules can only be enabled / disabled by recompiling NGINX. This tool was made to speedup collecting sources and building them.
 
