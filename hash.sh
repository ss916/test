#!/bin/sh
path=${0%/*}
bashname=${0##*/}

cd $path


cat $path/payload/global_web_* | sed '/payload:/d' | sed "1 i\payload:" > $path/payload/global_web.txt
cat $path/payload/global_video_* | sed '/payload:/d' | sed "1 i\payload:" > $path/payload/global_video.txt

z=SHA1 && filename="${z}.TXT" && find $path -type f -print0 | xargs -0 openssl $z | sed "s@$z($path@@g;s@)=@=@g" | sed "/$filename/d" | sort | sed "1 i\# //【$(date "+%Y-%m-%d %H:%M:%S")】" > $path/$filename
z=SHAKE128 && filename="${z}.TXT" && find $path -type f -print0 | xargs -0 openssl $z | sed "s@$z($path@@g;s@)=@=@g" | sed "/$filename/d" | sort | sed "1 i\# //【$(date "+%Y-%m-%d %H:%M:%S")】" > $path/$filename

