#!/bin/bash
sh_ver=43

path=${0%/*}
bashname=${0##*/}
bashpid=$$

name=opt
dirtmp=/tmp/${name}
diretc=$dirtmp
dirconf=${path}/${name}
tmp=/tmp
file_cron=/etc/storage/cron/crontabs/admin
file_wan=/etc/storage/post_wan_script.sh

[ "${path}" = "sh" -a "${bashname}" = "sh" -o "${path}" = "bash" -a "${bashname}" = "bash" ] && echo -e \\n"❗ \e[1;37m获取不到脚本真实路径path与脚本名字bashname，其值为$path。依赖路径与名字的功能将会失效。请下载脚本到本地再运行。\e[0m❗"\\n

[ ! -d $diretc ] && mkdir -p $diretc
[ ! -d $dirtmp ] && mkdir -p $dirtmp
cd $dirtmp

#alias
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'

curl_proxy () {
if [ ! -z "$(ps -w |grep -v grep| grep "clash -d")" -a ! -z "$(netstat -anp 2>/dev/null | grep clash)" ] ; then
	echo "* 走clash本地http代理 *"
	export http_proxy=http://127.0.0.1:8005 && export https_proxy=http://127.0.0.1:8005
else
	echo "* 走直连 *"
fi
echo "OLD：$PATH"
PATH=/etc/storage/bin:/tmp/script:/etc/storage/script:/opt/usr/sbin:/opt/usr/bin:/opt/sbin:/opt/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin:/etc/storage:/etc/storage/pdcn
echo "NEW：$PATH"
}


update () {
echo -e \\n"$(timenow)"\\n
[ "$(nvram get opt_force_enable)" != "1" ] && echo ">>启用opt环境..." && nvram set opt_force_enable=1 && nvram set upscript_enable=1 && nvram set optinstall=1 && nvram commit
#[ "$(free | awk '/Mem/{print $2}')" -ge "400000" ] && [ "$(nvram get size_tmpfs)" != "1" ] && echo ">>调整/tmp最大空间..." && nvram set size_tmpfs=1 && nvram commit
[ ! -z "$(nvram get opt_force_www | grep 'cdn.jsdelivr.net')" ] && set_opt1 1
[ -z "$(nvram get opt_force_file)" ] && set_opt2 1
[ -z "$(which opkg)" ] && [ ! -s /opt/bin/opkg ] && echo "✖未检测到opkg主程序文件$(which opkg)，重置opt文件..." && /etc/storage/script/Sh01_mountopt.sh reopt
curl_proxy
[ ! -z "$(ls /opt/tmp)" ] && echo ">>清空/opt/tmp..." && rm -rf /opt/tmp/*
echo -e \\n"\e[1;32m ▶更新opkg列表...\e[0m "
opkg update && opkg install wget
echo -e "\e[1;32m ...更新opkg列表結束...\e[0m "\\n
}
upgrade () {
echo -e \\n"\e[1;32m ▶升級opkg upgrade...\e[0m "
opkg upgrade
echo -e "\e[1;32m ...升級opkg upgrade結束...\e[0m "\\n
}
install () {
echo -e \\n"\e[1;7;36m ▶批量安装...\e[0m "
echo -e \\n"\e[1;33m★安装mtr \e[0m" && opkg install mtr && echo -e "\e[1;33m✔安装mtr \e[0m"
echo -e \\n"\e[1;33m★安装nmap \e[0m" && opkg install nmap && echo -e "\e[1;33m✔安装nmap \e[0m"
echo -e \\n"\e[1;33m★安装iperf3 \e[0m" && opkg install iperf3 && echo -e "\e[1;33m✔安装iperf3 \e[0m"
echo -e \\n"\e[1;33m★安装openssh-server \e[0m" && opkg install openssh-server && echo -e "\e[1;33m✔安装openssh-server \e[0m"
echo -e \\n"\e[1;33m★安装iftop \e[0m" && opkg install iftop && echo -e "\e[1;33m✔安装iftop \e[0m"
echo -e \\n"\e[1;33m★安装curl \e[0m" && opkg install curl && echo -e "\e[1;33m✔安装curl \e[0m"
echo -e \\n"\e[1;33m★更新openssl \e[0m" && opkg install openssl-util libopenssl && echo -e "\e[1;33m✔更新openssl \e[0m"
echo -e \\n"\e[1;33m★安装coreutils split \e[0m" && opkg install coreutils-split && echo -e "\e[1;33m✔安装coreutils split \e[0m"
echo -e \\n"\e[1;33m★安装coreutils sort \e[0m" && opkg install coreutils-sort && echo -e "\e[1;33m✔安装coreutils sort \e[0m"
echo -e \\n"\e[1;33m★安装unzip \e[0m" && opkg install unzip && echo -e "\e[1;33m✔安装unzip \e[0m"
echo -e \\n"\e[1;33m★安装bind-dig \e[0m" && opkg install bind-dig && echo -e "\e[1;33m✔安装bind-dig \e[0m"
#wait
echo -e \\n"\e[1;7;36m ...批量安装結束...\e[0m "\\n
}


set_opt1 () {
opt_url1=https://fastly.jsdelivr.net/gh/hiboyhiboy
opt_url2=https://originfastly.jsdelivr.net/gh/hiboyhiboy
opt_url3=https://gcore.jsdelivr.net/gh/hiboyhiboy
opt_url4=https://testingcf.jsdelivr.net/gh/hiboyhiboy
num=$1
if [ -z "$num" ] ; then
echo -e \\n\\n"\e[1;36m 当前opt_force_www URL：\e[1;33m$(nvram get opt_force_www) \e[0m"\\n
allopturl=$(set | grep -E "^opt_url[0-9]+=" | sed '/"/d' | sed -E "s/'//g")
for u in $allopturl
do
n=$(echo $u | grep -Eo "^opt_url[0-9]+=" | sed 's/opt_url//;s/=$//')
m=$(echo $u | sed -E "s/^opt_url[0-9]+=//g")
echo -e "\e[1;32m【$n】\e[0m\e[1;36m$m \e[0m"
done
echo -e "\e[1;32m【0】\e[0m\e[1;36m关闭opt \e[0m"\\n
read -n 1 -p "请输入数字:" num
fi
opturl=$(set | grep -E "^opt_url${num}=" | sed '/"/d' | sed -E "s/'//g;s/^opt_url[0-9]+=//g")
if [ "$num" = "0" ] ; then
	echo -e "\e[1;36m 关闭opt \e[0m"\\n
	nvram set opt_force_enable=0 && nvram commit
else
	if [ ! -z "$opturl" ] ; then
		echo -e \\n\\n"\e[1;36m 设置opt_force_www URL ：\e[1;33m$opturl \e[0m"\\n
		nvram set opt_force_enable=1
		nvram set upopt_enable=1
		nvram set upscript_enable=1
		nvram set optinstall=1
		[ "$(free | awk '/Mem/{print $2}')" -ge "400000" ] && nvram set size_tmpfs=1 || nvram set size_tmpfs=0
		nvram set opt_force_www=$opturl
		nvram commit
	fi
fi
}

set_opt2 () {
opt_url1=https://fastly.jsdelivr.net/gh/hiboyhiboy/opt-file
opt_url2=https://originfastly.jsdelivr.net/gh/hiboyhiboy/opt-file
opt_url3=https://gcore.jsdelivr.net/gh/hiboyhiboy/opt-file
opt_url4=https://testingcf.jsdelivr.net/gh/hiboyhiboy/opt-file
opt_url5=https://raw.githubusercontents.com/hiboyhiboy/opt-file/master
opt_url6=https://rrr.ariadl.eu.org/hiboyhiboy/opt-file/master
num=$1
if [ -z "$num" ] ; then
echo -e \\n\\n"\e[1;36m 当前opt_force_file URL：\e[1;33m$(nvram get opt_force_file) \e[0m"
echo -e "\e[1;36m 当前opt_force_script URL：\e[1;33m$(nvram get opt_force_script) \e[0m"\\n
allopturl=$(set | grep -E "^opt_url[0-9]+=" | sed '/"/d' | sed -E "s/'//g")
for u in $allopturl
do
n=$(echo $u | grep -Eo "^opt_url[0-9]+=" | sed 's/opt_url//;s/=$//')
m=$(echo $u | sed -E "s/^opt_url[0-9]+=//g")
echo -e "\e[1;32m【$n】\e[0m\e[1;36m$m \e[0m"
done
echo -e "\e[1;32m【0】\e[0m\e[1;36m关闭opt \e[0m"\\n
read -n 1 -p "请输入数字:" num
fi
opturl=$(set | grep -E "^opt_url${num}=" | sed '/"/d' | sed -E "s/'//g;s/^opt_url[0-9]+=//g")
if [ "$num" = "0" ] ; then
	echo -e "\e[1;36m 关闭opt \e[0m"\\n
	nvram set opt_force_enable=0 && nvram commit
else
	if [ ! -z "$opturl" ] ; then
		opt_force_script=$(echo $opturl | sed 's/opt-file/opt-script/')
		echo -e \\n\\n"\e[1;36m 设置opt_force_file URL ：\e[1;33m$opturl \e[0m"
		echo -e "\e[1;36m 设置opt_force_script URL ：\e[1;33m$opt_force_script \e[0m"\\n
		nvram set opt_force_enable=1
		nvram set upopt_enable=1
		nvram set upscript_enable=1
		nvram set optinstall=1
		[ "$(free | awk '/Mem/{print $2}')" -ge "400000" ] && nvram set size_tmpfs=1 || nvram set size_tmpfs=0
		nvram set opt_force_file=$opturl
		nvram set opt_force_script=$opt_force_script
		nvram commit
	fi
fi
}

set_dns () {
nvram showall | grep wan_dns
echo -e "\e[1;36m▶set ipv4 DNS\e[0m"
nvram set wan_dnsenable_x=0
nvram set wan_dns1_x=223.5.5.5
nvram set wan_dns2_x=120.53.53.53
nvram set wan_dns3_x=1.0.0.2
nvram showall | grep wan_dns
echo "-------"
nvram showall | grep ip6_dns
echo -e "\e[1;36m▶set ipv6 DNS\e[0m"
nvram set ip6_dns_auto=0
nvram set ip6_dns1=2400:3200::1
nvram set ip6_dns2=2400:3200:baba::1
nvram showall | grep ip6_dns
nvram commit
}

#开机自启
stop_wan () {
[ -f ${path}/START_WAN.SH -a ! -z "$(cat ${path}/START_WAN.SH | grep ${bashname})" ] && echo -e \\n"\e[1;36m▷删除开机自启任务...\e[0m" && sed -i "/${bashname}/d" ${path}/START_WAN.SH
}
start_wan () {
[ -z "$(cat $file_wan | grep START_WAN.SH)" ] && echo "sh ${path}/START_WAN.SH &" >> $file_wan
[ ! -f ${path}/START_WAN.SH ] && > ${path}/START_WAN.SH
if [ "$(cat ${path}/START_WAN.SH | grep ${bashname} | wc -l)" != "1" ] ; then
stop_wan
echo -e \\n"\e[1;36m▶创建开机自启任务...\e[0m" && echo "sleep 120 && sh ${path}/${bashname} restart > $tmp/${bashname}_start_wan1.txt 2>&1 &" >> ${path}/START_WAN.SH
fi
}

#定时任务
stop_cron () {
[ -f ${path}/START_CRON.SH -a ! -z "$(cat ${path}/START_CRON.SH | grep ${bashname})" ] && echo -e \\n"\e[1;36m▷删除定时任务crontab...\e[0m" && sed -i "/${bashname}/d" ${path}/START_CRON.SH
}
start_cron () {
[ -z "$(cat $file_cron | grep START_CRON.SH)" ] && echo "1 5 * * * sh ${path}/START_CRON.SH &" >> $file_cron
[ ! -f ${path}/START_CRON.SH ] && > ${path}/START_CRON.SH
if [ "$(cat ${path}/START_CRON.SH | grep ${bashname} | wc -l)" != "1" ] ; then
stop_cron
echo -e \\n"\e[1;36m▶创建定时任务crontab...\e[0m" && echo "sleep 120 && sh ${path}/${bashname} 2 > $tmp/${bashname}_start_cron2.txt 2>&1 &" >> ${path}/START_CRON.SH
fi
}

start () {
[ -z "`ps -w|grep -v grep|grep iperf3`" ] && echo -e "\e[1;36m✦运行iperf3 \e[0m" && iperf3 -s -D
start_wan
start_cron
}

stop () {
stop_cron
stop_wan
}

restart () {
update && upgrade &
}

view_all_logs () {
log_file=${bashname}_start_wan1.txt && [ -s $tmp/$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && cat $tmp/$log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
log_file=${bashname}_start_cron2.txt && [ -s $tmp/$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && cat $tmp/$log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
}

toilet_font () {
echo "
┌─────────────┐
│░█▀█░█▀█░▀█▀░│
│░█░█░█▀▀░░█░░│
│░▀▀▀░▀░░░░▀░░│
└─────────────┘
"
}

zhuangtai () {
toilet_font
echo -e "\e[1;33m当前状态：\e[0m"\\n
if [ ! -z "$(which opkg)" ] ; then
	echo -e "★ \e[1;36m ${name} 环境：\e[1;32m【已存在】\e[0m"
else
	echo -e "☆ \e[1;36m ${name} 环境：\e[1;31m【不存在】\e[0m"
fi
if [ ! -z "$(cat ${path}/START_CRON.SH | grep ${bashname})" ] ; then
	echo -e \\n"● \e[1;36m ${name} 定时重启2：\e[1;32m【已启用】\e[0m"
else
	echo -e \\n"○ \e[1;36m ${name} 定时重启：\e[1;31m【未启用】\e[0m"
fi
if [ ! -z "$(cat ${path}/START_WAN.SH | grep ${bashname})" ] ; then
	echo -e "● \e[1;36m ${name} 开机自启3：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 开机自启：\e[1;31m【未启用】\e[0m"
fi
}


case $1 in
0)
	stop &
	;;
1)
	update && install && start &
	;;
2)
	update && upgrade && install && start &
	;;
3)
	update && upgrade &
	;;
4)
	set_opt1
	;;
5)
	set_opt2
	;;
6)
	set_dns
	;;
restart)
	restart
	;;
update)
	update
	;;
upgrade)
	upgrade
	;;
install)
	install
	;;
log)
	view_all_logs
	;;
stop_wan_cron)
	stop_wan
	stop_cron
	;;
start_wan_cron)
	start_wan
	start_cron
	;;
*)
	#状态
	zhuangtai
	#
	echo -e \\n"\e[1;33m脚本管理：\e[0m\e[37m『 \e[0m\e[1;37m$sh_ver\e[0m\e[37m 』\e[0m"\\n
	echo -e "\e[1;32m【0】\e[0m\e[1;36m stop：取消自启\e[0m"
	echo -e "\e[1;32m【1】\e[0m\e[1;36m all ：update+批量安装+自启 \e[0m"
	echo -e "\e[1;32m【2】\e[0m\e[1;36m all ：update+upgrade+批量安装+自启\e[0m "
	echo -e "\e[1;32m【3】\e[0m\e[1;36m less：update+upgrade \e[0m"
	echo -e "\e[1;32m【4】\e[0m\e[1;36m 切换opt源1(旧) \e[0m"
	echo -e "\e[1;32m【5】\e[0m\e[1;36m 切换opt源2\e[0m"
	echo -e "\e[1;32m【6】\e[0m\e[1;36m 设置ipv4/ipv6 DNS\e[0m"\\n
	read -n 1 -p "请输入数字:" num
	if [ "$num" = "0" ] ; then
		stop &
	elif [ "$num" = "1" ] ; then
		update && install && start &
	elif [ "$num" = "2" ] ; then
		update && upgrade && install && start &
	elif [ "$num" = "3" ] ; then
		update && upgrade &
	elif [ "$num" = "4" ] ; then
		set_opt1
	elif [ "$num" = "5" ] ; then
		set_opt2
	elif [ "$num" = "6" ] ; then
		set_dns
	else
		echo -e \\n"\e[1;31m输入错误。\e[0m "\\n
	fi
	;;
esac