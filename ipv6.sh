#!/bin/bash
sh_ver=22

path=${0%/*}
bashname=${0##*/}
bashpid=$$

name=ipv6
dirtmp=/tmp/${name}
diretc=$dirtmp
dirconf=${path}/${name}
[ ! -d $dirconf ] && mkdir -p $dirconf
tmp=/tmp
file_cron=/etc/storage/cron/crontabs/admin
file_wan=/etc/storage/post_wan_script.sh
file_wan2=/etc/storage/post_iptables_script.sh

[ "${path}" = "sh" -a "${bashname}" = "sh" -o "${path}" = "bash" -a "${bashname}" = "bash" ] && echo -e \\n"❗ \e[1;37m获取不到脚本真实路径path与脚本名字bashname，其值为$path。依赖路径与名字的功能将会失效。请下载脚本到本地再运行。\e[0m❗"\\n

[ ! -d $diretc ] && mkdir -p $diretc
[ ! -d $dirtmp ] && mkdir -p $dirtmp
cd $dirtmp

#初始化settings.txt
settings () {
echo -e \\n"\e[1;36m>>>初始化设置<<<\e[0m"
echo -e \\n"\e[1;36m↓↓ 开放防火墙iptables/ip6tables端口，输入1开启 ↓↓\e[0m"\\n
read -p "是否开放防火墙端口：" firewall
if [ "$firewall" != "1" ] ; then
firewall=0
elif [ "$firewall" = "1" ] ; then
echo -e \\n"\e[1;36m↓↓ 放行防火墙iptables/ip6tables端口，为空时将默认使用端口55555 ↓↓\e[0m"\\n
read -p "放行防火墙端口：" port
fi
###
echo -e \\n"\e[1;37m你输入了：\\n\\n${name}开放防火墙端口: $firewall \\n \\n${name} 端口: $port \\n \e[0m"\\n
echo "firewall=$firewall
port=$port
" > $dirconf/settings.txt
sed -i '/^.*=$/'d $dirconf/settings.txt
}
#读取参数
read_settings () {
##读取配置文件全部参数
for a in $(cat $dirconf/settings.txt | grep '=' | grep -Ev '^#' | sed '1!G;h;$!d') ; do n=$(echo $a | awk -F= '{print $1}') ; b=$(echo $a | sed "s/${n}=//g") ; eval $n=$b ; done
##缺省参数补全
#防火墙开关iptables
[ -z "$firewall" ] && firewall=0 && echo "firewall=$firewall" >> $dirconf/settings.txt
[ ! -z "$port" ] && all_port="55555,$port" || all_port="55555"
}
if [ ! -z "$2" -a ! -z "$3" ] ; then
	echo "$@" | sed 's/ /\n/g' | grep "=" > $dirconf/settings.txt
	read_settings
else
	if [ -s $dirconf/settings.txt ] ; then
		read_settings
	else
		settings
	fi
fi


#网卡类型
wan1=$(ps -w| grep -v grep | grep dhcp6 | awk -F' ' '{print $NF}')
wan2=$(ps -w| grep -v grep | grep dhcpc | grep -Eo '\-i.*' | awk -F' ' '{print $2}')
wan3=$(nvram get wan0_ifname)
if [ ! -z "${wan1}" ] ; then
	wan=$wan1
elif [ ! -z "${wan2}" ] ; then
	wan=$wan2
elif [ ! -z "${wan3}" ] ; then
	wan=$wan3
else
	wan=""
fi

#开机自启
stop_wan () {
[ -f ${path}/START_WAN.SH -a ! -z "$(cat ${path}/START_WAN.SH | grep ${bashname})" ] && echo -e \\n"\e[1;36m▷删除开机自启任务...\e[0m" && sed -i "/${bashname}/d" ${path}/START_WAN.SH
}
start_wan () {
[ -z "$(cat $file_wan | grep START_WAN.SH)" ] && echo "sh ${path}/START_WAN.SH &" >> $file_wan
[ ! -f ${path}/START_WAN.SH ] && > ${path}/START_WAN.SH
if [ "$(cat ${path}/START_WAN.SH | grep ${bashname} | wc -l)" != "1" ] ; then
stop_wan
echo -e \\n"\e[1;36m▶创建开机自启任务...\e[0m" && echo "sh ${path}/${bashname} restart > $tmp/${bashname}_start_wan.txt 2>&1 &" >> ${path}/START_WAN.SH
fi
}


start () {
echo -e "\e[1;37m 设置桥接ipv6 IP \e[0m" && logger -t "【${bashname}】" " 设置桥接ipv6 IP"
[ -z "`lsmod | grep ip6table_mangle`" ] && echo "▶挂载ipv6模块：ip6table_mangle" && modprobe ip6table_mangle
[ -z "`ebtables -t broute -L | grep "! IPv6"`" ] && echo "▶ebtables：在broute添加规则BROUTING，桥接ipv6包" && ebtables -t broute -A BROUTING -p ! ipv6 -j DROP -i $wan
[ -z "`brctl show | grep "$wan"`" ] && echo "▶brctl：添加网卡$wan加入网桥br0" && brctl addif br0 $wan
start_wan
}

stop () {
echo -e "\e[1;37m 检查是否需要清除旧ipv6规则\e[0m" && logger -t "【${bashname}】" " 清除旧ipv6规则"
#[ ! -z "`lsmod | grep ip6table_mangle`" ] && echo "▷移除已挂载ipv6模块：ip6table_mangle" && modprobe -r ip6table_mangle
[ ! -z "`ebtables -t broute -L | grep "! IPv6"`" ] && echo "▷ebtables：在broute删除规则BROUTING，桥接ipv6包" && ebtables -t broute -D BROUTING -p ! ipv6 -j DROP -i $wan
[ ! -z "`brctl show | grep "$wan"`" ] && echo "▷brctl：删除网卡$wan加入网桥br0" && brctl delif br0 $wan
stop_wan
}

chaxun () {
echo -e \\n"\e[1;37m ★当前wan网卡类型：【$wan】\e[0m"
echo -e \\n"\e[1;37m ★查看系统内核是否有ip6table模块\e[0m"
modprobe -l | grep ip6table_mangle
echo -e \\n"\e[1;37m ★查看系统内核是否已挂载ip6table模块\e[0m"
if [ -z "`lsmod | grep ip6table_mangle`" ]; then
	echo "✘ip6table内核模块未挂载"
else
	echo -e "\e[36m✔ip6table内核模块已挂载\e[0m"
fi
echo -e \\n"\e[1;37m ◆查看ebtables规则broute\e[0m"
if [ -z "`ebtables -t broute -L | grep "! IPv6"`" ]; then
	echo "✘ebtables不存在ipv6规则"
else
	echo -e "\e[36m✔ebtables存在ipv6规则\e[0m"
	ebtables -t broute -L
fi
echo -e \\n"\e[1;37m ◆查看brctl网桥信息\e[0m"
if [ -z "`brctl show | grep "$wan"`" ]; then
	echo "✘wan口brctl网桥信息不存在"
else
	echo -e "\e[36m✔wan口brctl网桥信息存在\e[0m"
	brctl show
fi
}


firewall0 () {
logger -t "【${bashname}】" "▷清空ipv4 INPUT、ipv6 INPUT/FORWARD防火墙规则. " && echo -e \\n"\e[36m▷清空ipv4 INPUT、ipv6 INPUT/FORWARD防火墙规则.\e[0m"
[ ! -z "$(iptables -vnL INPUT --line-numbers | grep -Ei "55555")" ] && IFS=$'\n' && for m in $(iptables -vnL INPUT --line-numbers | grep -Ei "55555" | awk '{print $1}' | sed '1!G;h;$!d' ) ; do iptables -D INPUT $m ;done
[ ! -z "$(ip6tables -vnL INPUT --line-numbers | grep -Ei "55555")" ] && IFS=$'\n' && for m in $(ip6tables -vnL INPUT --line-numbers | grep -Ei "55555" | awk '{print $1}' | sed '1!G;h;$!d' ) ; do ip6tables -D INPUT $m ;done
[ ! -z "$(ip6tables -vnL FORWARD --line-numbers | grep -Ei "ACCEPT *all *\* *\* *::/0 *::/0 *$")" ] && IFS=$'\n' && for m in $(ip6tables -vnL FORWARD --line-numbers | grep -Ei "ACCEPT *all *\* *\* *::/0 *::/0 *$" | awk '{print $1}' | sed '1!G;h;$!d' ) ; do ip6tables -D FORWARD $m ;done
}
firewall1 () {
logger -t "【${bashname}】" "▶添加ipv4 INPUT、ipv6 INPUT/FORWARD防火墙规则，端口：$all_port" && echo -e \\n"\e[36m▶添加ipv4 INPUT、ipv6 INPUT/FORWARD防火墙规则，端口：$all_port\e[0m"
iptables -I INPUT -p tcp -m multiport --dport $all_port -j ACCEPT
iptables -I INPUT -p udp -m multiport --dport $all_port -j ACCEPT
ip6tables -I INPUT -p tcp -m multiport --dport $all_port -j ACCEPT
ip6tables -I INPUT -p udp -m multiport --dport $all_port -j ACCEPT
ip6tables -I FORWARD -d ::/0 -j ACCEPT
}
firewall_wan_0 () {
[ ! -z "$(cat $file_wan2 | grep ${bashname})" ] && echo -e \\n"\e[1;36m▷删除firewall防火墙自启任务...\e[0m" && sed -i "/${bashname}/d" $file_wan2
}
firewall_wan_1 () {
[ -z "$(cat $file_wan2 | grep ${bashname})" ] && echo -e \\n"\e[1;36m▶创建firewall防火墙自启任务...\e[0m" && echo "sh ${path}/${bashname} start_firewall > $tmp/${bashname}_start_firewall.txt 2>&1 &" >> $file_wan2
}
start_firewall () {
[ "$firewall" != "1" ] && firewall=1 && sed -i '/firewall=/d' $dirconf/settings.txt && echo "firewall=$firewall" >> $dirconf/settings.txt
iptables_input=$(iptables -vnL INPUT --line-numbers | grep -Ei "55555" | wc -l)
ip6tables_input=$(ip6tables -vnL INPUT --line-numbers | grep -Ei "55555" | wc -l)
ip6tables_forward=$(ip6tables -vnL FORWARD --line-numbers | grep -Ei "ACCEPT *all *\* *\* *::/0 *::/0 *$" | wc -l)
if [ "$iptables_input" = "2" -a "$ip6tables_input" = "2" -a "$ip6tables_forward" = "1" ] ; then
	echo -e \\n"  ✔ start_firewall：${name} iptables INPUT/FORWARD规则已存在，无需设置。"\\n
else
	[ "$iptables_input" != "0" -o "$ip6tables_input" != "0" -o "$ip6tables_forward" != "0" ] && firewall0
	firewall1
fi
firewall_wan_1
}
stop_firewall () {
[ "$firewall" != "0" ] && firewall=0 && sed -i '/firewall=/d' $dirconf/settings.txt && echo "firewall=$firewall" >> $dirconf/settings.txt
firewall0
firewall_wan_0
}


#7
resettings () {
echo -e \\n"\e[1;37m--------------------\\n    【重置参数】\\n当前settings设置参数列表\\n$dirconf/settings.txt\\n--------------------\e[0m"
if [ -s $dirconf/settings.txt ] ; then
cat $dirconf/settings.txt | awk '{print "\e[1;33m第"NR"行\e[0m " "\e[1;36m" $0 "\e[0m"}'
else
echo "     （空）"
fi
echo -e "\e[1;37m--------------------\e[0m"
echo -e \\n"\e[1;32m【0】\e[1;33m⚠️重置全部参数\e[0m"
echo -e "\e[1;32m【1】\e[1;33m使用vi编辑参数文件\e[0m"
echo -e "* 进入编辑界面后移动光标到待修改地方，按a进入编辑模式。"
echo -e "* 编辑修改完成后按ESC键退出编辑模式进入一般模式，输入 :wq 即可保存并退出。"\\n
read -n 1 -p "请输入数字：" num
if [ ! -z "$(echo $num|grep -E '^[0-9]+$')" ] ; then
	if [ "$num" = "0" ] ; then
		settings
	elif [ "$num" = "1" ] ; then
		vi $dirconf/settings.txt
	else
		echo -e \\n"\e[1;37m✖输入非0、1，退出脚本 \e[0m"\\n
	fi
else
	echo -e \\n"\e[1;37m✖输入非数字，退出脚本 \e[0m"\\n
fi
}

view_all_logs () {
log_file=${bashname}_start_wan.txt && [ -s $tmp/$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && cat $tmp/$log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
log_file=${bashname}_start_firewall.txt && [ -s $tmp/$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && cat $tmp/$log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
}

toilet_font () {
echo "
┌─────────────────┐
│░▀█▀░█▀█░█░█░▄▀▀░│
│░░█░░█▀▀░▀▄▀░█▀▄░│
│░▀▀▀░▀░░░░▀░░░▀░░│
└─────────────────┘
"
}

#状态
zhuangtai () {
toilet_font
echo -e "\e[1;33m当前状态：\e[0m"\\n
if [ ! -z "${wan}" ] ; then
	echo -e "★ \e[1;36m 当前wan网卡类型 ：\e[1;32m【$wan】\e[0m"
else
	echo -e "☆ \e[1;36m 当前wan网卡类型 ：\e[1;31m【不存在】\e[0m"
fi
if [ ! -z "`lsmod | grep ip6table_mangle`" ] ; then
	echo -e "★ \e[1;36m ip6table内核模块：\e[1;32m【已挂载】\e[0m"
else
	echo -e "☆ \e[1;36m ip6table内核模块：\e[1;31m【未挂载】\e[0m"
	echo "▶挂载ipv6模块：ip6table_mangle" && modprobe ip6table_mangle
fi
lanfe=$(ifconfig -a | awk -F' ' '/inet6/{print $(NF-1)}' | grep -v -E '128|fe80'|awk -F: '{print $(NF-1)}'|grep fe | head -n1)
ipv6lan=$(ifconfig -a | awk -F' ' '/inet6/{print $(NF-1)}' | grep -v -E '128|fe80' | awk -F '/' '/'$lanfe'/{print $1}')
ipv6wan=$(ifconfig -a | awk -F' ' '/inet6/{print $(NF-1)}' | grep -v -E '128|fe80|'$lanfe'' | awk -F '/' '{print $1}')
if [ ! -z "${ipv6lan}" ] ; then
	echo -e "★ \e[1;36m ipv6 lan：\e[1;32m$ipv6lan\e[0m"
else
	echo -e "☆ \e[1;36m ipv6 lan：\e[1;37mnone\e[0m"
fi
if [ ! -z "${ipv6wan}" ] ; then
	echo -e "★ \e[1;36m ipv6 wan：\e[1;32m$ipv6wan\e[0m"
else
	echo -e "☆ \e[1;36m ipv6 wan：\e[1;37mnone\e[0m"
fi
if [ ! -z "$(cat ${path}/START_WAN.SH | grep ${bashname})" ] ; then
	echo -e \\n"● \e[1;36m ${name} 桥接自启：\e[1;32m【已启用】\e[0m"
else
	echo -e \\n"○ \e[1;36m ${name} 桥接自启：\e[1;31m【未启用】\e[0m"
fi
if [ ! -z "`ebtables -t broute -L | grep "! IPv6"`" ] ; then
	echo -e "● \e[1;36m ebtables规则 ：\e[1;32m【已加载】\e[0m"
else
	echo -e "○ \e[1;36m ebtables规则 ：\e[1;31m【未加载】\e[0m"
fi
if [ ! -z "`brctl show | grep "$wan"`" ] ; then
	echo -e "● \e[1;36m brctl网桥规则：\e[1;32m【已加载】\e[0m"
else
	echo -e "○ \e[1;36m brctl网桥规则：\e[1;31m【未加载】\e[0m"
fi
#firewall
if [ ! -z "$(cat $file_wan2 | grep ${bashname})" ] ; then
	echo -e \\n"● \e[1;36m ipv4/ipv6 firewall自启：\e[1;32m【已启用】\e[0m"
else
	echo -e \\n"○ \e[1;36m ipv4/ipv6 firewall自启：\e[1;31m【未启用】\e[0m"
fi
iptables_input=$(iptables -vnL INPUT --line-numbers | grep -Ei "55555" | wc -l)
ip6tables_input=$(ip6tables -vnL INPUT --line-numbers | grep -Ei "55555" | wc -l)
ip6tables_forward=$(ip6tables -vnL FORWARD --line-numbers | grep -Ei "ACCEPT *all *\* *\* *::/0 *::/0 *$" | wc -l)
if [ "$iptables_input" = "2" -a "$ip6tables_input" = "2" -a "$ip6tables_forward" = "1" ] ; then
	echo -e "● \e[1;36m ipv4/ipv6 firewall端口：\e[1;32m【已开通】\e[0m"
	echo -e "    port：\e[1;37m$all_port \e[0m"
else
	echo -e "○ \e[1;36m ipv4/ipv6 firewall端口：\e[1;31m【未开通】\e[0m"
	echo -e "    ipv4 INPUT: $iptables_input  ipv6 INPUT: $ip6tables_input  ipv6 FORWARD: $ip6tables_forward"
fi
}

case $1 in
0|stop)
	stop
	;;
1|start|restart)
	start
	;;
2)
	chaxun
	;;
3|start_firewall)
	start_firewall
	;;
4|stop_firewall)
	stop_firewall
	;;
7)
	resettings
	;;
f0)
	firewall0
	;;
f1)
	firewall1
	;;
log)
	view_all_logs
	;;
stop_wan_cron)
	stop_wan
	;;
start_wan_cron)
	start_wan
	;;
*)
	#状态
	zhuangtai
	#
	echo -e \\n"\e[1;33m脚本管理：\e[0m\e[37m『 \e[0m\e[1;37m$sh_ver\e[0m\e[37m 』\e[0m"\\n
	echo -e "\e[1;32m【0】\e[0m\e[1;36m 关闭ipv6桥接 \e[0m"
	echo -e "\e[1;32m【1】\e[0m\e[1;36m 启用ipv6桥接 \e[0m"
	echo -e "\e[1;32m【2】\e[0m\e[1;36m 查看ebtables规则、brctl网桥信息\e[0m "
	echo -e "\e[1;32m【3】\e[0m\e[1;36m 启用防火墙 ipv4 INPUT、ipv6 INPUT/FORWARD\e[0m "
	echo -e "\e[1;32m【4】\e[0m\e[1;36m 关闭防火墙 ipv4 INPUT、ipv6 INPUT/FORWARD\e[0m "
	echo -e "\e[1;32m【7】\e[0m\e[1;36m resettings：重置初始化配置\e[0m"\\n
	read -n 1 -p "请输入数字：" num
	if [ "$num" = "0" ] ; then
		stop
	elif [ "$num" = "1" ] ; then
		start
	elif [ "$num" = "2" ] ; then
		chaxun
	elif [ "$num" = "3" ] ; then
		start_firewall
	elif [ "$num" = "4" ] ; then
		stop_firewall
	elif [ "$num" = "7" ] ; then
		resettings
	else
		echo -e \\n"\e[1;31m输入错误。\e[0m "\\n
	fi
	;;
esac
