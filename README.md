# debian-latest-nginx

 Script to download and build at once:

  *  <a href="http://nginx.org/download">nginx</a>

  *  <a href="http://github.com/wandenberg/nginx-push-stream-module.git">push-stream-module</a> (optional)

  *  <a href="https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng">nginx-sticky-module</a> (optional)

  *  <a href="https://github.com/Fleshgrinder/nginx-sysvinit-script.git">sysvinit script for debian</a> (optional)


Optionally it allows to change the <b>server string</b> returned in http headers.


It takes less than a minute to download and build everything.


### Usage:

 1. Clone this repo or download the script via curl/wget. <i>Do not copy/paste it from browser.</i>

 2. Review the configure lines. You might want to add/remove modules/options.

 3. Run <code>buildngx.sh</code> and answer the questions. It will ask for push & sticky modules and what server string you want.
 4. :pray:

### Options:
Option | Meaning
------------ | -------------
  -q, --q | Don't ask any questions. Download and build all modules, preserve "nginx" as server string, if -s is not specified.
  -p, --p | Show latest version of nginx from nginx.org and exit
  -s, --s | Set server string to:
  -h, --h | Show help and exit


### Notes:

If you run this script on virgin system, i.e. nginx was not installed before, make sure  directory specified for cache in configure script exists, before attempting to start nginx.
