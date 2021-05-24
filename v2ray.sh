#!/bin/bash
sh_ver=44

path=${0%/*}
bashname=${0##*/}

#程序名字
name=v2ray
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

#闪存资源文件夹
if [ -s $dirconf/settings.txt ] ; then
	diretc=$(cat $dirconf/settings.txt |awk -F 'diretc=' '/diretc=/{print $2}' | head -n 1)
	if [ ! -z "$diretc" ] ; then
		if [ "$diretc" != "/tmp/${name}/etc" ] ; then
			size=$(df $etc |awk '!/Available/{print $4}')
			if [ "$size" -lt "5120" ] ; then
				diretc=/tmp/${name}/etc
				sed -i '/diretc=/d' $dirconf/settings.txt
				echo "diretc=/tmp/${name}/etc" >> $dirconf/settings.txt
				#echo "检测到闪存$etc剩余空间$size KB小于5MB，资源文件將下载保存到內存中$dirtmp"
				[ ! -f $dirtmp/*${name}# ] && > $dirtmp/'#检测到闪存剩余空间'$size'KB小于5MB，资源文件將下载保存到內存中／tmp／${name}#'
			fi
		fi
	else
		diretc=/tmp/${name}/etc
		echo "diretc=/tmp/${name}/etc" >> $dirconf/settings.txt
	fi
else
	diretc=/tmp/${name}/etc
fi

#系统定时任务文件
file_cron=$etc/cron/crontabs/admin
#开机自启文件
file_wan=$etc/post_wan_script.sh

user_name=${name}
#用户uid/gid
uid=0
gid=20001

#资源文件地址前缀
url1="https://raw.githubusercontent.com/ss916/test/master"
url2="https://cdn.jsdelivr.net/gh/ss916/test"
url3="https://raw.fastgit.org/ss916/test/master"
url4="https://rrr.san99.workers.dev/ss916/test/master"


#alias
run="$dirtmp/${name} -config=$dirtmp/config.json"
alias pss='ps -w |grep -v grep| grep "$run"'
alias pid='pidof ${name}'
alias port='netstat -anp | grep "${name}"'
alias psskeep='ps -w | grep -v grep |grep "${name}_keep.sh"'
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'

#xtls日志
#export XRAY_VLESS_XTLS_SHOW=true
#export V2RAY_TROJAN_XTLS_SHOW=true

curl_proxy () {
if [ ! -z "$(ps -w |grep -v grep| grep "clash -d")" -a ! -z "$(netstat -anp | grep clash)" ] ; then
	curl="curl -x 127.0.0.1:8005"
	url=$url1
else
	curl="curl"
	url=$url4
fi
}
curl_proxy_v2 () {
if [ ! -z "$(ps -w |grep -v grep| grep "${name}.*-config")" -a ! -z "$(netstat -anp | grep ${name})" ] ; then
	curl="curl -x 127.0.0.1:8005"
	url=$url1
else
	curl="curl"
	url=$url2
fi
}
curl_proxy
[ ! -d $dirtmp ] && mkdir -p $dirtmp
[ ! -d $diretc ] && mkdir -p $diretc
[ ! -d $dirconf ] && mkdir -p $dirconf
cd $dirtmp

#初始化settings.txt
settings () {
echo -e \\n"\e[1;36m↓↓ 初始化设置，請輸入配置文件链接1，输入0即表示使用本地自定义配置文件↓↓\e[0m"\\n
read -p "配置文件链接：" link1
if [ "$link1" != "0" ] ; then
	echo -e \\n"\e[1;36m↓↓ 配置文件是否解密，输入1需要 ↓↓\e[0m"\\n
	read -p "是否解密：" secret
	if [ "$secret" = "1" ] ; then
		read -p "输入密码：" password
	else
		password=none
	fi
else
	secret=0
	password=none
fi
echo -e \\n"\e[1;36m↓↓ 开放防火墙iptables/ip6tables端口，输入1开启 ↓↓\e[0m"\\n
read -p "是否开放防火墙端口：" firewall
[ "$firewall" != "1" ] && firewall=0
echo -e \\n"\e[1;36m↓↓ 請选择透明代理模式mode ↓↓\e[0m"\\n
echo -e "\e[36m 1.tproxy透明代理\\n2.tproxy透明代理+自身代理\\n3.不启用透明代理（默认）\\n\e[0m"
read -n 1 -p "请输入：" mode
echo -e \\n"\e[1;37m你输入了：	\\n${name}配置文件链接1: $link1 \\n${name}是否解密: $secret\\n密码: $password \\n${name}开放防火墙端口: $firewall \\n${name}tproxy透明代理: $mode\e[0m"
echo "link1=$link1
secret=$secret
password=$password
firewall=$firewall
mode=$mode
" > $dirconf/settings.txt
}
#读取参数
read_settings () {
if [ -s $tmp/config.json -o -s $dirconf/config.json ] ; then
	link1=0
else
	#是否需要解密
	secret=$(cat $dirconf/settings.txt |awk -F 'secret=' '/secret=/{print $2}' | head -n 1)
	#密码
	password=$(cat $dirconf/settings.txt |awk -F 'password=' '/password=/{print $2}' | head -n 1)
	#地址1
	link1=$(cat $dirconf/settings.txt |awk -F 'link1=' '/link1=/{print $2}' | head -n 1)
fi
#模式
mode=$(cat $dirconf/settings.txt |awk -F 'mode=' '/mode=/{print $2}' | head -n 1)
[ -z "$mode" ] && mode=3 && echo "mode=3" >> $dirconf/settings.txt
#防火墙开关iptables
firewall=$(cat $dirconf/settings.txt |awk -F 'firewall=' '/firewall=/{print $2}' | head -n 1)
[ -z "$firewall" ] && firewall=0 && echo "firewall=0" >> $dirconf/settings.txt
#防火墙开关iptables
tproxy=$(cat $dirconf/settings.txt |awk -F 'tproxy=' '/tproxy=/{print $2}' | head -n 1)
[ -z "$tproxy" ] && tproxy=0 && echo "tproxy=0" >> $dirconf/settings.txt
#自定义闪存目录
diretc=$(cat $dirconf/settings.txt |awk -F 'diretc=' '/diretc=/{print $2}' | head -n 1)
[ -z "$diretc" ] && diretc=/tmp/$name/etc && echo "diretc=/tmp/$name/etc" >> $dirconf/settings.txt
}
if [ ! -z "$2" -a ! -z "$3" ] ; then
	#一键快速设置参数：./v2ray.sh 1 mode=1 link1=https://123.com/link1.txt
	echo "$@"|sed 's/ /\n/g' > $dirconf/settings.txt
	read_settings
else
	if [ -s $dirconf/settings.txt ] ; then
		#echo "已存在用戶配置settings.txt，直接讀取"
		#sort -u $dirconf/settings.txt -o $dirconf/settings.txt
		read_settings
	else
		settings
	fi
fi



function downloadfile () {
#本地文件名字
filename=$(echo "$@"|sed 's/ /\n/g'| awk -F 'filename=' '/filename=/{print $2}')
[ -z "$filename" ] && echo "download file错误，文件名filename参数为空" && exit
#压缩包文件名字
filetgz=$(echo "$@"|sed 's/ /\n/g'| awk -F 'filetgz=' '/filetgz=/{print $2}')
[ -z "$filetgz" ] && echo "download file错误，文件filetgz参数为空" && exit
#解压到目录，留空则默认路径使用./
fileout=$(echo "$@"|sed 's/ /\n/g'| awk -F 'fileout=' '/fileout=/{print $2}')
[ -z $fileout ] && fileout=./
#文件下载地址或名字
address=$(echo "$@"|sed 's/ /\n/g'| awk -F 'address=' '/address=/{print $2}')
if [ -z "$address" ] ; then
	echo "download file错误，文件地址address参数为空" && exit
else
	if [ -z "$(echo $address | grep ^http)" ] ; then
		#补全地址
		link="$url/$address"
	fi
fi
#是否需要解密
secret=$(echo "$@"|sed 's/ /\n/g'| awk -F 'secret=' '/secret=/{print $2}')
#密码
password=$(echo "$@"|sed 's/ /\n/g'| awk -F 'password=' '/password=/{print $2}')

#下载次数
m=10
n=1
while [ $n -le $m ]
do
if [ "$n" = "1" ] ; then
	echo -e \\n"\e[36m▶下载校验文件SHA1.TXT：$url/SHA1.TXT......\e[0m"
	$curl -# -L $url/SHA1.TXT -o $tmp/SHA1.TXT
	if [ -s $tmp/SHA1.TXT ] ; then
		cp -f $tmp/SHA1.TXT $etc/SHA1.TXT
		ver=$(cat $etc/SHA1.TXT | awk -F// '/【/{print $2}')
		echo -e "\e[1;37m ◆SHA1.TXT版本：$ver\e[0m"
	else
		ver=$(cat $etc/SHA1.TXT | awk -F// '/【/{print $2}')
		logger -t "【$filename】" "✘ $tmp/SHA1.TXT為空，直接使用旧文件$etc/SHA1.TXT校验，版本$ver" && echo -e \\n"\e[1;31m【$filename】  ✘ $tmp/SHA1.TXT為空，直接使用旧文件$etc/SHA1.TXT校验，版本$ver\e[0m"
		[ ! -s $etc/SHA1.TXT ] && logger -t "【$filename】" "✘ 下载$tmp/SHA1.TXT為空，且$etc/SHA1.TXT不存在，无法校验，结束脚本。" && echo -e \\n"\e[1;31m【$filename】  ✘ 下载$tmp/SHA1.TXT為空，且$etc/SHA1.TXT不存在，无法校验，结束脚本。\e[0m" && exit
	fi
fi
logger -t "【$filename】" "▶開始第[$n]次下载$filetgz......" && echo -e \\n"\e[1;36m▶『$filename』開始第[$n]次下载$filetgz......\e[0m"
if [ -s $diretc/$filetgz ] ; then
	new=$(openssl SHA1 $diretc/$filetgz |awk '{print $2}')
else
	logger -t "【$filename】" "▷github下载文件$filetgz：$link..." && echo -e \\n"\e[1;7;37m▷『$filename』github下载文件$filetgz：$link...\e[0m"
	[ ! -z "$(ps -w | grep -v grep | grep "curl.*$filetgz")" ] && echo "！已存在curl下載$filetgz進程，先kill。" && ps -w | grep "curl.*$filetgz" | grep -v grep | awk '{print $1}' | xargs kill -9
	$curl -# -L $link -o ./$filetgz
	new=$(openssl SHA1 ./$filetgz |awk '{print $2}')
fi
old=$(cat $etc/SHA1.TXT | grep $address | awk -F ' ' '/\/'$filetgz'=/{print $2}')
echo -e \\n"文件：$filetgz \\nnew：$new \\nold：$old"
if [ ! -z "$new" -a ! -z "$old" ] ; then
	if [ "$new" = "$old" ] ; then
		if [ -s ./$filetgz ] ; then
			echo -e \\n"\e[36m▷新下载文件$filetgz校验成功，复制到[ $diretc/$filetgz ]...\e[0m"
			mv -f ./$filetgz $diretc/$filetgz
		else
			echo -e \\n"\e[36m▷旧文件$filetgz校验成功...\e[0m"
		fi
		download_ok=1
	else
		logger -t "【$filename】" "✘『$filetgz』文件SHA1對比不一致，校验失败，刪除旧文件$diretc/$filetgz，重新下载！" && echo -e \\n"\e[1;35m    ✘ 【$filetgz】文件SHA1對比不一致，校验失败，刪除旧文件$diretc/$filetgz，重新下载！\e[0m"
		rm -rf $diretc/$filetgz
		download_ok=0
	fi
else
	[ -z "$new" ] && logger -t "【$filename】" "✘ $filetgz文件openssl生成SHA1為空。" && echo -e \\n"\e[1;31m    ✘ $filetgz文件openssl生成SHA1為空。\e[0m"
	[ -z "$old" ] && logger -t "【$filename】" "✘ SHA1.TXT校驗文件內沒有$filetgz文件" && echo -e \\n"\e[1;31m    ✘ SHA1.TXT校驗文件內沒有$filetgz文件。\e[0m"
	download_ok=0
fi
#下载完成后检查文件类型是否需要解压与解密
if [ "$download_ok" = "1" ] ; then
	type=$(echo $filetgz | awk -F. '{print $NF}')
	if [ "$type" = "tgz" ] ; then
		echo -e \\n"\e[36m▷解压文件$filetgz到[ $fileout ]...\e[0m"
		tar xzvf $diretc/$filetgz -C $fileout
		echo -e \\n"\e[32m✔文件$filetgz解压完成！\e[0m"\\n
	elif [ "$type" = "zip" ] ; then
		echo -e \\n"\e[36m▷解压文件$filetgz到[ $fileout ]...\e[0m"
		[ ! -s /opt/bin/unzip ] && echo -e "  >> 检测到opt需要安装unzip..." && opkg update && opkg install unzip
		unzip -o $diretc/$filetgz -d $fileout
		echo -e \\n"\e[32m✔文件$filetgz解压完成！\e[0m"\\n
	elif [ "$secret" = "1" ] ; then
		echo -e \\n"\e[36m▷解密文件$filetgz到[ $fileout/$filename ]...\e[0m"
		cat $diretc/$filetgz | openssl enc -aes-256-ctr -d -a -md md5 -k $password > $fileout/$filename
		echo -e \\n"\e[32m✔ $filetgz文件解密$filename完成！\e[0m"\\n
	else
		cp -f $diretc/$filetgz ./$filetgz
		echo -e \\n"\e[32m✔ 直接复制$diretc/$filetgz文件到[ ./$filetgz ] ！\e[0m"\\n
	fi
	#跳出循环
	break
fi
n=$(expr $n + 1)
done
[ "$n" -gt "$m" ] && logger -t "【$filename】" "✖下载[$m]次都失败！！！" && echo -e \\n"\e[1;31m✖『$filename』下载[$m]次都失败！！！\e[0m"\\n
}

#下载主程序
down_program () {
file=${name}
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filename=$file filetgz=$file
	[ -s ./$file ] && chmod +x -R ./
fi
}
#下载geoip
down_geoip () {
file=geo
if [ ! -s ./geoip.dat -o ! -s ./geosite.dat -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file.tgz filename=$file filetgz=$file.tgz fileout=./
fi
}

#下载json
down_config () {
file=$link1
if [ "$secret" = "1" ] ; then
	downloadfile address=s/$file filetgz=$file filename=config.json secret=1 password=$password
else
	downloadfile address=s/$file filetgz=$file filename=config.json
fi
}

#download ipset.cnip.txt
down_ipset_cnip () {
file="ipset.cnip.txt"
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filename=$file filetgz=$file fileout=./
fi
}

firewall0 () {
logger -t "【$name】" "▷清空INPUT/FORWARD防火墙规则. " && echo -e \\n"\e[36m▷清空INPUT/FORWARD防火墙规则.\e[0m"
iptables -D INPUT -p tcp -m multiport --dport 2087,443,55500:60000 -j ACCEPT
iptables -D INPUT -p udp -m multiport --dport 55500:60000 -j ACCEPT
ip6tables -D INPUT -p tcp -m multiport --dport 2087,443,55500:60000 -j ACCEPT
ip6tables -D INPUT -p udp -m multiport --dport 55500:60000 -j ACCEPT
ip6tables -D FORWARD -d ::/0 -j ACCEPT
}
firewall1 () {
logger -t "【$name】" "▶添加INPUT/FORWARD防火墙规则.. " && echo -e \\n"\e[36m▶添加INPUT/FORWARD防火墙规则..\e[0m"
iptables -I INPUT -p tcp -m multiport --dport 2087,443,55500:60000 -j ACCEPT
iptables -I INPUT -p udp -m multiport --dport 55500:60000 -j ACCEPT
ip6tables -I INPUT -p tcp -m multiport --dport 2087,443,55500:60000 -j ACCEPT
ip6tables -I INPUT -p udp -m multiport --dport 55500:60000 -j ACCEPT
ip6tables -I FORWARD -d ::/0 -j ACCEPT
}
start_firewall () {
iptables_input=$(iptables -nL | grep 55500 | wc -l)
ip6tables_input=$(ip6tables -nL | grep 55500 | wc -l)
if [ "$iptables_input" = "2" -a "$ip6tables_input" = "2" ] ; then
	echo -e \\n"  ✔ start_firewall：${name} iptables INPUT/FORWARD规则已存在，无需设置。"\\n
else
	firewall1
fi
}


ipset_cnip () {
[ ! -s ./ipset.cnip.txt ] && down_ipset_cnip
if [ -s ./ipset.cnip.txt ] ; then
	ipset restore -f ipset.cnip.txt
	ipset_cnip_ok=1
else
	logger -t "【${name}】" "✖ ipset.cnip.txt文件为空，无法创建cn IP ipset表。跳过。" && echo -e \\n"\e[1;31m✖ ✖ ipset.cnip.txt文件为空，无法创建cn IP ipset表。跳过。\e[0m"
	ipset_cnip_ok=0
fi
}

# iptables tproxy setting：https://xtls.github.io/documents/level-2/iptables_gid/
tproxy4 () {
echo -e \\n"\e[1;36m▶创建局域网透明代理\e[0m"
ip rule add fwmark 1 table 100
ip route add local default dev lo table 100
iptables -t mangle -N $name >/dev/null 2>&1
iptables -t mangle -F $name
iptables -t mangle -A $name -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A $name -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A $name -d 100.64.0.0/10 -j RETURN
iptables -t mangle -A $name -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A $name -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A $name -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A $name -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A $name -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A $name -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A $name -d 255.255.255.255/32 -j RETURN
for a in $(ip addr | grep -w inet | awk '{print $2}') ; do iptables -t mangle -A $name -d $a -j RETURN ; done
#iptables -t mangle -I $name -p udp --dport 53 -j TPROXY --on-ip 127.0.0.1 --on-port "$dns_port" --tproxy-mark 1
iptables -t mangle -A $name -p tcp -j TPROXY --on-ip 127.0.0.1 --on-port "$tproxy_port" --tproxy-mark 1
iptables -t mangle -A $name -p udp -j TPROXY --on-ip 127.0.0.1 --on-port "$tproxy_port" --tproxy-mark 1
iptables -t mangle -A PREROUTING -j $name
}
tproxy4_out () {
echo -e "\e[1;36m▶创建本机透明代理\e[0m"
iptables -t mangle -N ${name}_mask >/dev/null 2>&1
iptables -t mangle -F ${name}_mask
iptables -t mangle -A ${name}_mask -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A ${name}_mask -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A ${name}_mask -d 100.64.0.0/10 -j RETURN
iptables -t mangle -A ${name}_mask -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A ${name}_mask -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A ${name}_mask -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A ${name}_mask -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A ${name}_mask -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A ${name}_mask -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A ${name}_mask -d 255.255.255.255/32 -j RETURN
for a in $(ip addr | grep -w inet | awk '{print $2}') ; do iptables -t mangle -A ${name}_mask -d $a -j RETURN ; done
#iptables -t mangle -I ${name}_mask -p udp --dport 53 -j MARK --set-mark 1
iptables -t mangle -A ${name}_mask -p tcp -j MARK --set-mark 1
iptables -t mangle -A ${name}_mask -p udp -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -m owner ! --gid-owner $gid -j ${name}_mask
}

tproxy6 () {
echo -e "\e[1;36m▶创建ipv6局域网透明代理\e[0m"
ip -6 rule add fwmark 1 table 106
ip -6 route add local ::/0 dev lo table 106
ip6tables -t mangle -N $name >/dev/null 2>&1
ip6tables -t mangle -F $name
ip6tables -t mangle -A $name -d ::/128 -j RETURN
ip6tables -t mangle -A $name -d ::1/128 -j RETURN
ip6tables -t mangle -A $name -d ::ffff:0:0/96 -j RETURN
ip6tables -t mangle -A $name -d 64:ff9b::/96 -j RETURN
ip6tables -t mangle -A $name -d 100::/64 -j RETURN
ip6tables -t mangle -A $name -d 2001::/32 -j RETURN
ip6tables -t mangle -A $name -d 2001:20::/28 -j RETURN
ip6tables -t mangle -A $name -d 2001:db8::/32 -j RETURN
ip6tables -t mangle -A $name -d 2002::/16 -j RETURN
ip6tables -t mangle -A $name -d fc00::/7 -j RETURN
ip6tables -t mangle -A $name -d fe80::/10 -j RETURN
ip6tables -t mangle -A $name -d ff00::/8 -j RETURN
for a in $(ip addr | grep -w inet6 | grep -v fe80 | awk '{print $2}' | sort -u) ; do ip6tables -t mangle -A $name -d $a -j RETURN ; done
#ip6tables -t mangle -I $name -p udp --dport 53 -j TPROXY --on-port "$dns_port" --tproxy-mark 1
ip6tables -t mangle -A $name -p udp -j TPROXY --on-port "$tproxy_port" --tproxy-mark 1
ip6tables -t mangle -A $name -p tcp -j TPROXY --on-port "$tproxy_port" --tproxy-mark 1
ip6tables -t mangle -A PREROUTING -j $name
}
tproxy6_out () {
echo -e "\e[1;36m▶创建ipv6本机透明代理\e[0m"
ip6tables -t mangle -N ${name}_mask >/dev/null 2>&1
ip6tables -t mangle -F ${name}_mask
ip6tables -t mangle -A ${name}_mask -d ::/128 -j RETURN
ip6tables -t mangle -A ${name}_mask -d ::1/128 -j RETURN
ip6tables -t mangle -A ${name}_mask -d ::ffff:0:0/96 -j RETURN
ip6tables -t mangle -A ${name}_mask -d 64:ff9b::/96 -j RETURN
ip6tables -t mangle -A ${name}_mask -d 100::/64 -j RETURN
ip6tables -t mangle -A ${name}_mask -d 2001::/32 -j RETURN
ip6tables -t mangle -A ${name}_mask -d 2001:20::/28 -j RETURN
ip6tables -t mangle -A ${name}_mask -d 2001:db8::/32 -j RETURN
ip6tables -t mangle -A ${name}_mask -d 2002::/16 -j RETURN
ip6tables -t mangle -A ${name}_mask -d fc00::/7 -j RETURN
ip6tables -t mangle -A ${name}_mask -d fe80::/10 -j RETURN
ip6tables -t mangle -A ${name}_mask -d ff00::/8 -j RETURN
for a in $(ip addr | grep -w inet6 | grep -v fe80 | awk '{print $2}' | sort -u) ; do ip6tables -t mangle -A ${name}_mask -d $a -j RETURN ; done
ip6tables -t mangle -I ${name}_mask -p udp --dport 53 -j MARK --set-mark 1
ip6tables -t mangle -A ${name}_mask -p tcp -j MARK --set-mark 1
ip6tables -t mangle -A ${name}_mask -p udp -j MARK --set-mark 1
ip6tables -t mangle -A OUTPUT -m owner ! --gid-owner $gid -j ${name}_mask
}

redirect_dns () {
echo -e "\e[1;36m▶劫持DNS 53请求本机\e[0m"\\n
iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports "$dns_port"
iptables -t nat -I OUTPUT -m owner ! --gid-owner $gid -p udp --dport 53 -j REDIRECT --to-ports "$dns_port"
}

#透明代理
ipt1 () {
#检查是否缺少tproxy模块modprobe 
[ -z "$(lsmod | grep xt_TPROXY)" ] && echo "▶加載內核模塊 xt_TPROXY" && modprobe xt_TPROXY
redir_port=1099
tproxy_port=1099
dns_port=5353
##########
logger -t "【${name}】" "▶创建透明代理"
##tproxy tcp+udp
tproxy4
tproxy6
##redir dns
redirect_dns
if [ "$mode" = "2" ] ; then
logger -t "【${name}】" "▶创建路由自身走透明代理" && echo -e \\n"\e[1;36m▶创建路由自身走透明代理\e[0m"\\n
tproxy4_out
tproxy6_out
fi
}

ipt0 () {
echo -e \\n"\e[1;36m▷清空透明代理iptables规则\e[0m"\\n && logger -t "【${name}】" "▷清空透明代理iptables规则"
ip rule del fwmark 1 table 100 >/dev/null 2>&1
ip route del local default dev lo table 100 >/dev/null 2>&1
ip -6 rule del fwmark 1 table 106 >/dev/null 2>&1
ip -6 route del local ::/0 dev lo table 106 >/dev/null 2>&1
iptables -t mangle -F OUTPUT
iptables -t mangle -F PREROUTING
ip6tables -t mangle -F OUTPUT
ip6tables -t mangle -F PREROUTING
iptables -t nat -F OUTPUT
#iptables -t nat -F PREROUTING
[ ! -z "$(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp.*dpt:53")" ] && IFS=$'\n' && for m in $(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp.*dpt:53" | awk '{print $1}' | sed '1!G;h;$!d' ) ; do iptables -t nat -D PREROUTING $m ;done
}

stop_iptables () {
ipt0
}

start_iptables () {
pre1=$(iptables -t mangle -vnL PREROUTING --line-numbers | grep -i $name | wc -l)
pre2=$(ip6tables -t mangle -vnL PREROUTING --line-numbers | grep -i $name | wc -l)
pre3=$(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp.*dpt:53" | wc -l)
out3=$(iptables -t nat -vnL OUTPUT --line-numbers | grep -Ei "udp.*dpt:53" | wc -l)
out1=$(iptables -t mangle -vnL OUTPUT --line-numbers | grep -i $name | wc -l)
out2=$(ip6tables -t mangle -vnL OUTPUT --line-numbers | grep -i $name | wc -l)
if [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out3" = "1" -a "$out1" = "0" -a "$out2" = "0" ] ; then
	iptables_mode=1
elif [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out3" = "1" -a "$out1" = "1" -a "$out2" = "1" ] ; then
	iptables_mode=2
else
	iptables_mode=0
fi
if [ "$mode" = "1" -a "$iptables_mode" = "1" ] ; then
	echo "    ✓ start_iptables：${name}当前模式mode 1，iptables mode 1，iptables规则正常，跳过设置。"
elif [ "$mode" = "2" -a "$iptables_mode" = "2" ] ; then
	echo "    ✓ start_iptables：${name}当前模式mode 2，iptables mode 2，iptables规则正常，跳过设置。"
else
	#清空iptables规则
	[ "$pre1" != "0" -o "$pre2" != "0" -o "$pre3" != "0" -o "$out3" != "0" -o "$out1" != "0" -o "$out2" != "0" ] && ipt0
	if [ ! -z "$(pss)" -a ! -z "$(port)" ] ; then
		ipt1
		work_ok=1
		[ -f ./start_iptables_ok_* ] && rm ./start_iptables_ok_*
		> ./start_iptables_ok_1
	else
		#echo "    ✖ start_iptables：${name}进程或端口没启动成功，跳过设置透明代理。"
		work_ok=0
		[ -f ./start_iptables_ok_* ] && rm ./start_iptables_ok_*
		> ./start_iptables_ok_0
	fi
fi
}

#开机自启
stop_wan () {
[ -f $pdcn/START_WAN.SH -a ! -z "$(cat $pdcn/START_WAN.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▷删除开机自启任务...\e[0m" && sed -i "/${name}.sh/d" $pdcn/START_WAN.SH
}
start_wan () {
[ -z "$(cat $file_wan | grep START_WAN.SH)" ] && echo "sh $pdcn/START_WAN.SH &" >> $file_wan
[ ! -f $pdcn/START_WAN.SH ] && > $pdcn/START_WAN.SH
[ -z "$(cat $pdcn/START_WAN.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▶创建开机自启任务...\e[0m" && echo "sh $pdcn/${name}.sh restart > $tmp/${name}_start_wan.txt 2>&1 &" >> $pdcn/START_WAN.SH
}

#定时任务
stop_cron () {
[ -f $pdcn/START_CRON.SH -a ! -z "$(cat $pdcn/START_CRON.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▷删除定时任务crontab...\e[0m" && sed -i "/${name}.sh/d" $pdcn/START_CRON.SH
}
start_cron () {
[ -z "$(cat $file_cron | grep START_CRON.SH)" ] && echo "1 5 * * * sh $pdcn/START_CRON.SH &" >> $file_cron
[ ! -f $pdcn/START_CRON.SH ] && > $pdcn/START_CRON.SH
[ -z "$(cat $pdcn/START_CRON.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▶创建定时任务crontab...\e[0m" && echo "sh $pdcn/${name}.sh $mode > $tmp/${name}_start_cron.txt 2>&1 &" >> $pdcn/START_CRON.SH
#[ -z "$(cat $pdcn/START_CRON.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▶创建定时任务crontab...\e[0m" && echo "sh $pdcn/${name}.sh restart > $tmp/${name}_start_cron.txt 2>&1 &" >> $pdcn/START_CRON.SH
}

restart () {
#检查进程端口
if [ "$(pss | wc -l)" != "1" -o "$(psskeep | wc -l)" != "1" ] ; then
	sh $pdcn/${name}.sh $mode &
else
	echo -e \\n"$(timenow) ✓ restart：${name}进程与${name}_keep.sh进程守护已运行，无需重启。"\\n
fi
#检查firewall
[ "$firewall" = "1" ] && start_firewall
[ "$mode" = "1" -o "$mode" = "2" ] && start_iptables
}

#进程守护
start_keep () {
if [ ! -s ./${name}_keep.sh ] ; then
echo "▶生成进程守护脚本."
cat > ./${name}_keep.sh << \EOF
#!/bin/sh
name=v2ray
tmp=/tmp
etc=/etc/storage
dirtmp=$tmp/${name}
pdcn=$etc/pdcn
dirconf=$pdcn/${name}
run="$dirtmp/${name} -config=$dirtmp/config.json"
alias pss='ps -w |grep -v grep| grep "$run"'
alias pid='pidof ${name}'
alias port='netstat -anp | grep "${name}"'
alias psskeep='ps -w | grep -v grep |grep "${name}_keep.sh"'
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'
mode=$(cat $dirconf/settings.txt |awk -F 'mode=' '/mode=/{print $2}' |head -n 1)
firewall=$(cat $dirconf/settings.txt |awk -F 'firewall=' '/firewall=/{print $2}' | head -n 1)
t=1
f=1
v=1
log1=1
cd $dirtmp
while true ; do
#t：检查tproxy
if [ "$mode" = "1" -o "$mode" = "2" ] ; then
	pre1=$(iptables -t mangle -vnL PREROUTING --line-numbers | grep -i $name | wc -l)
	pre2=$(ip6tables -t mangle -vnL PREROUTING --line-numbers | grep -i $name | wc -l)
	pre3=$(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp.*dpt:53" | wc -l)
	out3=$(iptables -t nat -vnL OUTPUT --line-numbers | grep -Ei "udp.*dpt:53" | wc -l)
	out1=$(iptables -t mangle -vnL OUTPUT --line-numbers | grep -i $name | wc -l)
	out2=$(ip6tables -t mangle -vnL OUTPUT --line-numbers | grep -i $name | wc -l)
	if [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out3" = "1" -a "$out1" = "0" -a "$out2" = "0" ] ; then
		iptables_mode=1
	elif [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out3" = "1" -a "$out1" = "1" -a "$out2" = "1" ] ; then
		iptables_mode=2
	else
		iptables_mode=0
	fi
	if [ "$mode" = "1" -a "$iptables_mode" != "1" ] ; then
		echo -e "$(timenow) [$t]检测${name}需要重置iptables规则①！" >> ./keep.txt
		echo "mode：$mode ， iptables_mode：$iptables_mode，$pre1 $pre2 $pre3 $out3 $out1 $out2" >> ./keep.txt
		sh $pdcn/${name}.sh start_iptables &
		tproxy_ok=0
		t=0
	elif [ "$mode" = "2" -a "$iptables_mode" != "2" ] ; then
		echo -e "$(timenow) [$t]检测${name}需要重置iptables规则②！" >> ./keep.txt
		echo "mode：$mode ， iptables_mode：$iptables_mode，$pre1 $pre2 $pre3 $out3 $out1 $out2" >> ./keep.txt
		sh $pdcn/${name}.sh start_iptables &
		tproxy_ok=0
		t=0
	else
		tproxy_ok=1
	fi
else
	tproxy_ok=close
fi
#f：检查firewall
if [ "$firewall" = "1" ] ; then
	ipt=$(iptables -nL | grep 55500 | wc -l)
	ipt6=$(ip6tables -nL | grep 55500 | wc -l)
	if [ "$ipt" != "2" -o "$ipt6" != "2" ] ; then
		echo -e "$(timenow) [$f]检测${name}防火墙规则不存在，重新加载！" >> ./keep.txt
		sh $pdcn/${name}.sh start_firewall >> ./keep.txt 2>&1 &
		firewall_ok=0
		f=0
	else
		firewall_ok=1
	fi
else
	firewall_ok=close
fi
#v：检查进程与端口
pss_status=$(pss|wc -l)
port_status=$(port|wc -l)
if [ "$pss_status" != "1" -o -z "$port_status" ] ; then
	if [ "$pss_status" = "0" ] ; then
		echo -e "$(timenow) [$v]检测${name}进程不存在，重启程序！" >> ./keep.txt
	elif [ "$pss_status" -gt "1" ] ; then
		echo -e "$(timenow) [$v]检测${name}进程重复 x $pss_status，重启程序！" >> ./keep.txt
	fi
	[ -z "$port_status" ] && echo -e "$(timenow) [$v]检测${name}端口没监听，重启程序！" >> ./keep.txt
	nohup sh $pdcn/${name}.sh restart >> ./keep.txt 2>&1 &
	server_port_ok=0
	v=0
else
	server_port_ok=1
fi
#总结
if [ "$server_port_ok" = "1" -a "$firewall_ok" = "1" -a "$tproxy_ok" = "1" ] ; then
	echo -e "$(timenow) ${name} [$v] 进程OK，端口OK，[$t] tproxy OK，[$f] firewall OK" >> ./keep.txt
elif [ "$server_port_ok" = "1" -a "$firewall_ok" = "1" -a "$tproxy_ok" = "close" ] ; then
	echo -e "$(timenow) ${name} [$v] 进程OK，端口OK，[$f] firewall OK" >> ./keep.txt
elif [ "$server_port_ok" = "1" -a "$firewall_ok" = "close" -a "$tproxy_ok" = "1" ] ; then
	echo -e "$(timenow) ${name} [$v] 进程OK，端口OK，[$t] tproxy OK" >> ./keep.txt
elif [ "$server_port_ok" = "1" -a "$firewall_ok" = "close" -a "$tproxy_ok" = "close" ] ; then
	echo -e "$(timenow) ${name} [$v] 进程OK，端口OK" >> ./keep.txt
fi
#+1
t=$(($t+1))
f=$(($f+1))
v=$(($v+1))
#日志文件大于1万条后删除1000条
[ -s ./keep.txt ] && [ "$(sed -n '$=' ./keep.txt)" -ge "10000" ] && echo -e "❴d:$log1❵ $(sed -n '$=' ./keep.txt)—1000_[$(timenow)]" >> ./keep.txt && sed -i '1,1000d' ./keep.txt && log1=$(($log1+1))
sleep 120
done
EOF
chmod +x ./${name}_keep.sh
fi
#检查进程守护脚本是否已启动
if [ -z "$(psskeep)" ] ; then
	echo -e \\n"\e[1;36m▶启动进程守护脚本...\e[0m" && nohup sh $dirtmp/${name}_keep.sh >> $dirtmp/keep.txt 2>&1 &
	keep_run_status=0
else
	keep_run_status=1
fi
}
stop_keep () {
[ ! -z "$(psskeep)" ] && echo -e \\n"\e[1;36m▷关闭进程守护脚本...\e[0m" && psskeep | awk '{print $1}' | xargs kill -9
}
restart_keep () {
stop_keep
[ -s ./${name}_keep.sh ] && rm ./${name}_keep.sh
[ -s ./keep.txt ] && rm ./keep.txt
start_keep
}

#状态
status_program () {
echo -e \\n"\e[36m■查看${name}进程：\e[0m"
pss
echo -e \\n"\e[36m■查看${name}网络监听端口：\e[0m"
port
#判断是否启动
if [ ! -z "$(pss)" ] ; then
	if [ ! -z "$(port)" ] ; then
		logger -t "【${name}】" "✔ ${name}已启动！！" && echo -e \\n"\e[1;36m✔ ${name}已启动！！\e[0m"\\n
		start_ok=1
	else
		logger -t "【${name}】" "✦ ${name}进程已启动，但没监听端口..." && echo -e \\n"\e[1;36m✦ ${name}进程已启动，但没监听端口...\e[0m"
		start_ok=0
	fi
else
	logger -t "【${name}】" "✖ ${name}进程启动失败，端口无监听，请检查网络问题！！" && echo -e \\n"\e[1;31m✖ ${name}进程启动失败，端口无监听，请检查网络问题！！\e[0m"
	start_ok=0
fi
}

check_work () {
if [ ! -z "$(pid)" -a ! -z "$(port)" ] ; then
	work_ok=1
else
	work_ok=0
fi
}

function waitwork () {
comm=$1
time_max=$2
t=1
[ -z "$comm" ] && echo "\$1为空，退出循环" && exit
[ -z "$time_max" ] && time_max=60
while [ $t -le $time_max ]
do
if [ "$work_ok" = "0" ] ; then
	#echo "$t/$time_max，$comm ok = $work_ok"
	$comm
	t=$(($t+1))
	sleep 1
else
	echo -e "☑️ \e[1;32m$t/$time_max，$comm ok = $work_ok \e[0m"
	break
fi
done
[ $t -gt $time_max ] && echo -e "❎ \e[1;31m$time_max/$time_max，$comm ok = $work_ok \e[0m"
}

#check_work && waitwork check_work 10

#关闭
stop_program () {
[ ! -z "$(pss)" ] && logger -t "【${name}】" "▷关闭${name}..." && echo -e \\n"\e[1;36m▷关闭${name}...\e[0m" && pss | awk '{print $1}' | xargs kill -9 && curl_proxy_v2
}
#启动
start_program () {
[ -f ./${name}_log.txt ] && mv -f ./${name}_log.txt ./old_${name}_log.txt
logger -t "【${name}】" "▶启动${name}主程序..." && echo -e \\n"\e[1;36m▶启动${name}主程序...\e[0m"
[ -z "$(grep "$user_name" /etc/passwd)" ] && echo "▶添加用戶$user_name，uid为$uid，gid为$gid" && echo "$user_name:x:$uid:$gid:::" >> /etc/passwd
su $user_name -c "nohup $run > $dirtmp/${name}_log.txt 2>&1 &"
}

test_json () {
if [ -s ./config.json ] ; then
	test_json_status=$(./${name} -test ./config.json)
	if [ ! -z "$(echo $test_json_status | grep "Configuration OK")" ] ; then
		logger -t "【$name】" "✔ $name配置文件config.json测试通过Configuration OK..." && echo -e \\n"\e[1;32m  ✔ $name配置文件config.json测试通过Configuration OK...\e[0m"
	else
		logger -t "【$name】" "✘配置文件config.json配置文件测试不通过。结束脚本。" && echo -e \\n"\e[1;31m✘配置文件config.json配置文件测试不通过。结束脚本。\e[0m"
		#exit
	fi
else
	logger -t "【$name】" "✘配置文件config.json不存在或为空，请检查配置文件是否有错误，结束脚本。" && echo -e \\n"\e[1;31m✘配置文件config.json不存在或为空，请检查配置文件是否有错误，结束脚本。\e[0m"
	#exit
fi
}

get_config_file () {
config=config.json
if [ -s $tmp/$config -o -s $dirconf/$config ] ; then
	if [ -s $tmp/$config ] ; then
		cp -f $tmp/$config ./$config
		ver=$(cat ./$config | awk -F// '/【/{print $2}')
		logger -t "【${name}】" "▶进入测试模式，使用本地配置文件$tmp/$config，版本$ver" && echo -e \\n"\e[1;36m▶进入测试模式，使用本地配置文件$tmp/$config，版本：\e[0m\e[1;32m$ver\e[0m"
	elif [ -s $dirconf/$config ] ; then
		cp -f $dirconf/$config ./$config
		ver=$(cat ./$config | awk -F// '/【/{print $2}')
		logger -t "【${name}】" "▶使用闪存配置文件$dirconf/$config，版本$ver" && echo -e \\n"\e[36m▶使用本地配置文件$dirconf/$config，版本：\e[0m\e[1;32m$ver\e[0m"
	fi
else
	[ -z "$link1" -o "$link1" = "0"  ] && logger -t "【${name}】" "✖ 配置文件下载链接为空或等于0，结束脚本。" && echo -e \\n"\e[36m✖ 配置文件下载链接为空或等于0，结束脚本。\e[0m" && exit
	logger -t "【${name}】" "▶直接github下载配置文件$config" && echo -e \\n"\e[36m▶直接github下载配置文件$config \e[0m"
	down_config
fi
}

#關閉
stop_0 () {
stop_program
[ "$mode" = "1" -o "$mode" = "2" ] && stop_iptables
}
#关闭所有
stop_1 () {
stop_0
stop_wan
stop_cron
stop_keep
}

start_0 () {
echo -e \\n"$(timenow)"\\n
stop_0
#下载文件
get_config_file &
down_program &
down_geoip &
wait
#防火墙
[ "$firewall" = "1" ] && start_firewall
#启动主程序
start_program
#等待30秒
check_work && waitwork check_work 30
#查看状态
status_program
#创建开机自启
start_wan
#创建定时任务
start_cron
#keep进程守护
if [ "$run_restart_keep" = "1" ] ; then
	restart_keep
else
	start_keep
fi
}

start_1 () {
[ "$mode" != "1" ] && mode=1 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=1" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && run_restart_keep=1
[ "$tproxy" != "1" ] && tproxy=1 && sed -i '/tproxy=/d' $dirconf/settings.txt && echo "tproxy=1" >> $dirconf/settings.txt
start_0
if [ "$keep_run_status" = "1" ] ; then
	#keep脚本进程已存在，则立即执行透明代理
	start_iptables && waitwork start_iptables 60 &
else
	echo -e \\n"\e[1;36m◆keep.sh脚本为初始化启动，透明代理只由keep.sh启动。（避免重复加载透明代理规则）\e[0m"
fi
}
start_2 () {
[ "$mode" != "2" ] && mode=2 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=2" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && run_restart_keep=1
[ "$tproxy" != "1" ] && tproxy=1 && sed -i '/tproxy=/d' $dirconf/settings.txt && echo "tproxy=1" >> $dirconf/settings.txt
start_0
if [ "$keep_run_status" = "1" ] ; then
	#keep脚本进程已存在，则立即执行透明代理
	start_iptables && waitwork start_iptables 60 &
else
	echo -e \\n"\e[1;36m◆keep.sh脚本为初始化启动，透明代理只由keep.sh启动。（避免重复加载透明代理规则）\e[0m"
fi
}
start_3 () {
[ "$mode" != "3" ] && mode=3 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=3" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && run_restart_keep=1
[ "$tproxy" != "0" ] && tproxy=0 && sed -i '/tproxy=/d' $dirconf/settings.txt && echo "tproxy=0" >> $dirconf/settings.txt
[ ! -z "$(iptables -t mangle -vnL PREROUTING --line-numbers | grep -i $name)" ] && ipt0
start_0
}


#8更新文件
renew () {
startrenew=1
echo -e \\n"\e[1;33m檢查更新文件：\e[0m"\\n
[ -s ./$name ] && echo "▷删除旧文件$name" && rm -f ./$name
down_program &
down_geoip &
[ "$link1" != "0" ] && down_config &
wait
echo -e \\n"\e[1;33m...更新完成...\e[0m"\\n
exit
}


remove () {
echo -e \\n"\e[1;33m⚠️\\n即将卸载全部，确认卸载请按1，按其他任意键则取消卸载。\e[0m"\\n
read -n 1 -p "请输入:" num
if [ "$num" = "1" ] ; then
stop_1
rm -rf $dirtmp
rm -rf $diretc
rm -rf $dirconf
echo -e \\n" \e[1;32m✔${name}卸载完成！\e[0m"
fi
}


#状态
zhuangtai () {
echo -e \\n"\e[1;33m当前状态：\e[0m"\\n
if [ -s ./${name} ] ; then
	echo -e "★ \e[1;36m ${name} 版本：\e[1;32m【$(./${name} -version | awk '/Xray/{print $2}')】\e[0m"
else
	echo -e "☆ \e[1;36m ${name} 版本：\e[1;31m【不存在】\e[0m"
fi
if [ -s $tmp/config.json ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat $tmp/config.json | awk -F// '/【/{print $2}')\e[0m临时"
elif [ -s $dirconf/config.json ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat $dirconf/config.json | awk -F// '/【/{print $2}')\e[0m闪存"
elif [ -s ./config.json ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat ./config.json | awk -F// '/【/{print $2}')\e[0m在线:$link1】\e[0m"
else
	echo -e "☆ \e[1;36m ${name} 配置：\e[1;31m【不存在】\e[0m"
fi
if [ ! -z "$(pss)" ] ; then
	echo -e \\n"● \e[1;36m ${name} 进程：\e[1;32m【已运行】\e[0m"
else
	echo -e \\n"○ \e[1;36m ${name} 进程：\e[1;31m【未运行】\e[0m"
fi
if [ ! -z "$(port)" ] ; then
	echo -e "● \e[1;36m ${name} 端口：\e[1;32m【已监听】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 端口：\e[1;31m【未监听】\e[0m"
fi
#
if [ ! -z "$(psskeep)" ] ; then
	echo -e "● \e[1;36m ${name} 进程守护：\e[1;32m【已运行】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 进程守护：\e[1;31m【未运行】\e[0m"
fi
if [ ! -z "$(cat $pdcn/START_CRON.SH | grep ${name}.sh)" ] ; then
	echo -e "● \e[1;36m ${name} 定时重启：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 定时重启：\e[1;31m【未启用】\e[0m"
fi
if [ ! -z "$(cat $pdcn/START_WAN.SH | grep ${name}.sh)" ] ; then
	echo -e "● \e[1;36m ${name} 开机自启：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 开机自启：\e[1;31m【未启用】\e[0m"
fi
if [ "$firewall" = "1" ] ; then
	ipt=$(iptables -nL | grep 55500 | wc -l)
	ipt6=$(ip6tables -nL | grep 55500 | wc -l)
	if [ "$ipt" = "2" -a "$ipt6" = "2" ] ; then
		echo -e "● \e[1;36m ${name} firewall防火墙端口：\e[1;32m【已开通】\e[0m"
	else
		echo -e "○ \e[1;36m ${name} firewall防火墙端口：\e[1;31m【未开通】$ipt $ipt6\e[0m"
	fi
fi
pre1=$(iptables -t mangle -nL PREROUTING | grep -i $name | wc -l)
pre2=$(ip6tables -t mangle -nL PREROUTING | grep -i $name | wc -l)
pre3=$(iptables -t nat -nL PREROUTING | grep -Ei "udp.*$dns_port" | wc -l)
out3=$(iptables -t nat -nL OUTPUT | grep -Ei "udp.*$dns_port" | wc -l)
out1=$(iptables -t mangle -nL OUTPUT | grep -i $name | wc -l)
out2=$(ip6tables -t mangle -nL OUTPUT | grep -i $name | wc -l)
if [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out3" = "1" -a "$out1" = "0" -a "$out2" = "0" ] ; then
	iptables_mode=1
elif [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out3" = "1" -a "$out1" = "1" -a "$out2" = "1" ] ; then
	iptables_mode=2
else
	iptables_mode=0
fi
if [ "$mode" = "1" -a "$iptables_mode" = "1" ] ; then
	echo -e "● \e[1;36m ${name} 透明代理①：\e[1;32m【已启用】\e[0m"
elif [ "$mode" = "2" -a "$iptables_mode" = "2" ] ; then
	echo -e "● \e[1;36m ${name} 透明代理②：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 透明代理：\e[1;31m【未启用】\e[0m"
	echo "    mode：$mode，iptables_mode：$iptables_mode，$pre1 $pre2 $pre3 $out3 $out1 $out2"
fi
}
#按钮
case $1 in
0)
	stop_1 &
	;;
1)
	start_1 &
	;;
2)
	start_2 &
	;;
3)
	start_3 &
	;;
7)
	settings
	;;
8)
	renew &
	;;
9)
	remove &
	;;
ipt0)
	ipt0
	;;
ipt1)
	ipt1
	;;
start_iptables)
	start_iptables
	;;
start_firewall)
	start_firewall
	;;
stop_keep)
	stop_keep
	;;
start_keep)
	start_keep
	;;
restart_keep)
	restart_keep
	;;
restart)
	restart
	;;
*)
	#状态
	zhuangtai
	#
	echo -e \\n"\e[1;33m脚本管理：\e[0m\e[37m『 \e[0m\e[1;37m$sh_ver\e[0m\e[37m 』\e[0m"\\n
	echo -e "\e[1;32m【0】\e[0m\e[1;36m stop：关闭所有 \e[0m "
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start_1：启动$name + tproxy透明代理\e[0m"
	echo -e "\e[1;32m【2】\e[0m\e[1;36m start_2：启动$name + tproxy透明代理 + 代理自身\e[0m"
	echo -e "\e[1;32m【3】\e[0m\e[1;36m start_3：只启动$name\e[0m"
	echo -e "\e[1;32m【7】\e[0m\e[1;36m settings：重置初始化配置\e[0m"
	echo -e "\e[1;32m【8】\e[0m\e[1;36m renew：更新所有文件 \e[0m"
	echo -e "\e[1;32m【9】\e[0m\e[1;36m remove：卸载 \e[0m"\\n
	read -n 1 -p "请输入数字:" num
	if [ "$num" = "0" ] ; then
		stop_1 &
	elif [ "$num" = "1" ] ; then
		start_1 &
	elif [ "$num" = "2" ] ; then
		start_2 &
	elif [ "$num" = "3" ] ; then
		start_3 &
	elif [ "$num" = "7" ] ; then
		settings
	elif [ "$num" = "8" ] ; then
		renew &
	elif [ "$num" = "9" ] ; then
		remove &
	else
		echo -e \\n"\e[1;31m输入错误。\e[0m "\\n
	fi
	;;
esac