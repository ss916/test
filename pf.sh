#!/bin/sh
dir=/etc/storage/pdcn
[ ! -d $dir ] && mkdir -p $dir

if [ ! -s /etc/storage/profile -o -z "`grep "storage/pdcn" /etc_ro/profile`" ] ; then
	[ ! -z "`grep "storage/pdcn" /etc_ro/profile`" ] && umount /etc_ro/profile
	oldpath=`cat /etc_ro/profile |awk -F\' '/export PATH/{print $2}'|tail -n 1`
	newpath="/etc/storage/dnsmasq:/etc/storage/dnsmasq/dns:/etc/storage/pdcn"
	cp -f /etc_ro/profile /etc/storage/profile
	sed -i "/export PATH/s@$oldpath@$oldpath:$newpath@g" /etc/storage/profile
	mount --bind /etc/storage/profile /etc_ro/profile
	source /etc/profile
	if [ ! -z "`df -h|grep profile`" ] ; then
		echo "✔ 环境变量profile挂载成功！" && logger -t "【pf】" "✔ 环境变量profile挂载成功！"
	else
		echo "✖ 环境变量profile挂载失败！" && logger -t "【pf】" "✖ 环境变量profile挂载失败！"
	fi
fi

#开机自启
file_wan=/etc/storage/post_wan_script.sh
[ -z "$(cat $file_wan | grep pf.sh)" ] && echo "添加开机自启 " &&  echo "sh /etc/storage/pf.sh" >> $file_wan

