#!/bin/bash
sh_ver=3

#程序名字
name=opt
#内存根目录
tmp=/tmp
#闪存根目录
etc=/etc/storage

#内存目录文件夹
dirtmp=$tmp/${name}
#脚本目录
pdcn=$etc/pdcn
#闪存配置文件夹
dirconf=$pdcn/${name}

#系统定时任务文件
file_cron=$etc/cron/crontabs/admin
#开机自启文件
file_wan=$etc/post_wan_script.sh

#alias
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'

curl_proxy () {
if [ ! -z "$(ps -w |grep -v grep| grep "clash -d")" -a ! -z "$(netstat -anp | grep clash)" ] ; then
	echo "* 走clash本地http代理 *"
	export http_proxy=http://127.0.0.1:8005 && export https_proxy=http://127.0.0.1:8005
else
	echo "* 走直连 *"
fi
}


update () {
echo -e \\n"$(timenow)"\\n
curl_proxy
echo -e \\n"\e[1;32m ▶更新opkg列表...\e[0m "
/opt/bin/opkg update && /opt/bin/opkg install wget
echo -e "\e[1;32m ...更新opkg列表結束...\e[0m "\\n
}
upgrade () {
echo -e \\n"\e[1;32m ▶升級opkg upgrade...\e[0m "
/opt/bin/opkg upgrade
echo -e "\e[1;32m ...升級opkg upgrade結束...\e[0m "\\n
}
install () {
echo -e \\n"\e[1;7;36m ▶批量安装...\e[0m "
echo -e \\n"\e[1;33m★安装mtr \e[0m" && /opt/bin/opkg install mtr && echo -e "\e[1;33m✔安装mtr \e[0m"
echo -e \\n"\e[1;33m★安装nmap \e[0m" && /opt/bin/opkg install nmap && echo -e "\e[1;33m✔安装nmap \e[0m"
echo -e \\n"\e[1;33m★安装iperf3 \e[0m" && /opt/bin/opkg install iperf3 && echo -e "\e[1;33m✔安装iperf3 \e[0m"
echo -e \\n"\e[1;33m★安装openssh-server \e[0m" && /opt/bin/opkg install openssh-server && echo -e "\e[1;33m✔安装openssh-server \e[0m"
echo -e \\n"\e[1;33m★安装iftop \e[0m" && /opt/bin/opkg install iftop && echo -e "\e[1;33m✔安装iftop \e[0m"
echo -e \\n"\e[1;33m★安装curl \e[0m" && /opt/bin/opkg install curl && echo -e "\e[1;33m✔安装curl \e[0m"
echo -e \\n"\e[1;33m★更新openssl \e[0m" && /opt/bin/opkg install openssl-util libopenssl && echo -e "\e[1;33m✔更新openssl \e[0m"
echo -e \\n"\e[1;33m★安装coreutils split \e[0m" && /opt/bin/opkg install coreutils-split && echo -e "\e[1;33m✔安装coreutils split \e[0m"
echo -e \\n"\e[1;33m★安装coreutils sort \e[0m" && /opt/bin/opkg install coreutils-sort && echo -e "\e[1;33m✔安装coreutils sort \e[0m"
echo -e \\n"\e[1;33m★安装unzip \e[0m" && /opt/bin/opkg install unzip && echo -e "\e[1;33m✔安装unzip \e[0m"
#wait
echo -e \\n"\e[1;7;36m ...批量安装結束...\e[0m "\\n
}

#开机自启
stop_wan () {
[ -f $pdcn/START_WAN.SH -a ! -z "$(cat $pdcn/START_WAN.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▷删除开机自启任务...\e[0m" && sed -i "/${name}.sh/d" $pdcn/START_WAN.SH
}
start_wan () {
[ -z "$(cat $file_wan | grep START_WAN.SH)" ] && echo "sh $pdcn/START_WAN.SH &" >> $file_wan
[ ! -f $pdcn/START_WAN.SH ] && > $pdcn/START_WAN.SH
[ -z "$(cat $pdcn/START_WAN.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▶创建开机自启任务...\e[0m" && echo "sh $pdcn/${name}.sh restart > $tmp/${name}_start_wan.txt &" >> $pdcn/START_WAN.SH
}

#定时任务
stop_cron () {
[ -f $pdcn/START_CRON.SH -a ! -z "$(cat $pdcn/START_CRON.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▷删除定时任务crontab...\e[0m" && sed -i "/${name}.sh/d" $pdcn/START_CRON.SH
}
start_cron () {
[ -z "$(cat $file_cron | grep START_CRON.SH)" ] && echo "1 5 * * * sh $pdcn/START_CRON.SH &" >> $file_cron
[ ! -f $pdcn/START_CRON.SH ] && > $pdcn/START_CRON.SH
[ -z "$(cat $pdcn/START_CRON.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▶创建定时任务crontab...\e[0m" && echo "sh $pdcn/${name}.sh restart > $tmp/${name}_start_cron.txt &" >> $pdcn/START_CRON.SH
}

start () {
[ -z "`ps -w|grep -v grep|grep iperf3`" ] && echo -e "\e[1;36m✦运行iperf3 \e[0m" && iperf3 -s -D
start_wan
#start_cron
}

restart () {
update && upgrade && install && start &
}

case $1 in
0)
	update && upgrade &
	;;
1)
	update && install && start &
	;;
2)
	update && upgrade && install && start &
	;;
restart)
	restart
	;;
*)
	echo -e \\n"\e[1;33m脚本管理：\e[0m\e[37m『 \e[0m\e[1;37m$sh_ver\e[0m\e[37m 』\e[0m"\\n
	echo -e "\e[1;32m【0】\e[0m\e[1;36m update： opkg update upgrade \e[0m"
	echo -e "\e[1;32m【1】\e[0m\e[1;36m all： update.批量安装opkg.. \e[0m"
	echo -e "\e[1;32m【2】\e[0m\e[1;36m all：update upgrade.批量安装opkg\e[0m "\\n
	read -n 1 -p "请输入数字:" num
	[ "$num" = "0" ] && update &
	[ "$num" = "1" ] && update && install && start &
	[ "$num" = "2" ] && update && upgrade && install && start &
	;;
esac