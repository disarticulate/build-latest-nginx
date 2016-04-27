# debian-latest-nginx

 Script to download and build at once:

  *  <a href="http://nginx.org/download">nginx</a>
  
  *  <a href="http://github.com/wandenberg/nginx-push-stream-module.git">push-stream-module</a> (optional)
  
  *  <a href="https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng">nginx-sticky-module</a> (optional)
  
  *  <a href="https://github.com/Fleshgrinder/nginx-sysvinit-script.git">sysvinit script for debian</a> (optional)
  
  
Optionally it allows to change the server string.

It takes less than a minute to download and build everything.


Usage:

 1. Clone this repo or download the script via curl/wget. <i>Do not copy/paste it from browser.</i>

 2. Review the configure lines. You might want to add/remove modules/options.

 3. Run and answer the questions. It will ask for push & sticky modules and what server string you want.


