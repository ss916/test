#!/bin/sh
[ ! -z "$(ps -w | grep -v grep | grep "clash.*-d")" -a ! -z "$(netstat -anp | grep clash)" ] && echo "走clash本地http代理" && export http_proxy=http://127.0.0.1:8005 && export https_proxy=http://127.0.0.1:8005


update () {
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
start () {
[ -z "`ps -w|grep -v grep|grep iperf3`" ] && echo -e "\e[1;36m✦运行iperf3 \e[0m" && iperf3 -s -D
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
*)
	echo -e \\n"\e[1;33m脚本管理：\e[0m"
	echo -e \\n"\e[1;32m【0】\e[0m\e[1;36m update： opkg update upgrade \e[0m"
	echo -e "\e[1;32m【1】\e[0m\e[1;36m all： update.批量安装opkg.. \e[0m"
	echo -e "\e[1;32m【2】\e[0m\e[1;36m all：update upgrade.批量安装opkg\e[0m "\\n
	read -n 1 -p "请输入数字:" num
	[ "$num" = "0" ] && update &
	[ "$num" = "1" ] && update && install && start &
	[ "$num" = "2" ] && update && upgrade && install && start &
	;;
esac