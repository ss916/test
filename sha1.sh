#!/bin/sh
dir9=$(dirname $0)
cd $dir9


cat $dir9/payload/global_web_* | sed '/payload:/d' | sed "1 i\payload:" > $dir9/payload/global_web.txt

z=SHA1 && filename="${z}.TXT" && find $dir9 -type f -print0 | xargs -0 openssl $z | sed "s@$z($dir9@@g;s@)=@=@g" | sed "/$filename/d" | sort | sed "1 i\# //【$(date "+%Y-%m-%d %H:%M:%S")】" > $dir9/$filename
z=SHAKE128 && filename="${z}.TXT" && find $dir9 -type f -print0 | xargs -0 openssl $z | sed "s@$z($dir9@@g;s@)=@=@g" | sed "/$filename/d" | sort | sed "1 i\# //【$(date "+%Y-%m-%d %H:%M:%S")】" > $dir9/$filename

