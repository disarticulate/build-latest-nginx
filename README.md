# build-latest-nginx   [![Build Status](https://travis-ci.org/p34eu/debian-latest-nginx.svg?branch=master)](https://travis-ci.org/p34eu/debian-latest-nginx)

 Script to download and build at once :
 
  *  <a href="https://developers.google.com/speed/pagespeed/module/">page speed module</a>
  
  *  <a href="http://nginx.org/download">nginx</a>

  *  <a href="http://github.com/wandenberg/nginx-push-stream-module.git">push stream module</a> (optional)

  *  <a href="https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng">nginx sticky module</a> (optional)

  
Optionally it allows to change the <b>server string</b> returned in http headers.

It takes less than a minute to download and build everything.

Tested on Debian 8.4 (jessie). With  small changes works also on Centos.

Required packages:  (apt-get install)

<code>build-essential libpcre3-dev  libssl-dev curl php5-cli libgeoip-dev libxslt1-dev </code>
         


### Usage:

 1. Clone this repo or download the script via curl/wget. <i>Do not copy/paste it from browser.</i>

 2. Review the configure lines inside <code>buildngx.sh</code>. You might want to <b>add/remove</b> modules/options.

 3. Run <code>buildngx.sh</code>. and answer the questions. It will ask for push & sticky modules and what server string you want, unless -q is specified.
 
 4. If compile is ok, it will ask to <code>make install</code>.
 
 5. If you had nginx before on the same server, systemd and sysv configurations can be used without any change. 
 If not, they will be installed, unless answer is no. 
 Provided configure options correspond to debian defaults. 
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

 A. Most of the comunity NGINX modules can only be enabled / disabled by recompiling NGINX. 
 