#!/bin/bash
sh_ver=250
#
path=${0%/*}
bashname=${0##*/}
bashpid=$$

#程序名字
name=clash

#闪存配置文件夹
dirconf=${path}/${name}
[ ! -d $dirconf ] && mkdir -p $dirconf

tmp=/tmp
#系统定时任务文件
file_cron=/etc/storage/cron/crontabs/admin
#开机自启文件
file_wan=/etc/storage/post_wan_script.sh

#iptables设置绕过UID
#创建系统新用户
user_name=${name}
#用户uid/gid
uid=0
gid=20000

#端口
#redir_port=8002
tproxy_port=8001
dns_port=5300

#资源文件地址前缀
url1="https://raw.githubusercontent.com/ss916/test/main"
url2="https://raw.githubusercontents.com/ss916/test/main"
url3="https://rrr.ariadl.eu.org/ss916/test/main"
url4="https://fastly.jsdelivr.net/gh/ss916/test@main"
url5="https://gcore.jsdelivr.net/gh/ss916/test@main"
url6="https://testingcf.jsdelivr.net/gh/ss916/test@main"
url7="https://yyellow.ariadl.eu.org/916"
#url8="https://originfastly.jsdelivr.net/gh/ss916/test@main"

[ "${path}" = "sh" -a "${bashname}" = "sh" -o "${path}" = "bash" -a "${bashname}" = "bash" ] && echo -e \\n"❗ \e[1;37m获取不到脚本真实路径path与脚本名字bashname，其值为$path。依赖路径与名字的功能将会失效。请下载脚本到本地再运行。\e[0m❗"\\n

#初始化settings.txt
settings () {
echo -e \\n"\e[1;36m↓↓ 初始化设置，請輸入订阅链接link↓↓\e[0m"
echo -e "\e[1;36m* 多个http在线订阅请编辑settings.txt文件输入，格式：link2=订阅链接（link2=https://server.com）\e[0m"\\n
read -p "订阅链接1：" link1
echo -e \\n"\e[1;36m↓↓ 是否启用本地订阅文件clashfile1，1启用，0则不启用↓↓\e[0m"
echo -e "\e[1;36m* 多个本地订阅请编辑settings.txt文件输入，格式： clashfile2=文件名,密码，密码用,隔开（clashfile2=file2.txt,password2）\e[0m"\\n
read -p "本地订阅：" clashfile1
if [ "$clashfile1" = "1" ] ; then
	echo -e \\n"\e[1;36m↓↓ 请输入本地订阅文件名字clashfile_name↓↓\e[0m"\\n
	read -p "本地订阅文件名字：" clashfile_name
	echo -e \\n"\e[1;36m↓↓ 请输入本地订阅文件是否需要解密clashfile_secret，按1则需要解密，0则不需要解密↓↓\e[0m"\\n
	read -p "本地订阅文件是否解密：" clashfile_secret
	if [ "$clashfile_secret" = "1" ] ; then
		echo -e \\n"\e[1;36m↓↓ 请输入本地订阅文件解密密码clashfile_password↓↓\e[0m"\\n
		read -p "本地订阅文件解密密码：" clashfile_password
		clashfile1=${clashfile_name},${clashfile_password}
	else
		clashfile1=${clashfile_name}
	fi
else
	clashfile1=0
fi
#模式
echo -e \\n"\e[1;36m↓↓ 請选择透明代理模式mode ↓↓\e[0m"\\n
echo -e "\e[36m1.启用透明代理（默认）\\n2.透明代理+路由自身走代理\\n3.不启用透明代理\e[0m"
read -n 1 -p "请输入：" mode
#编辑模式，可选功能
echo -e \\n"\e[1;36m↓↓ 請选择edit编辑配置模式 ↓↓\e[0m"\\n
echo -e "\e[36m1.使用内置配置模板，编辑配置（默认）\\n0.自定义配置，不编辑配置\e[0m"
read -n 1 -p "请输入：" edit
echo -e \\n"\e[1;36m↓↓ [编辑] 請选择DNS模式 ↓↓\e[0m"\\n
echo -e "\e[36m1.redir-host模式（默认）\\n2.fake-dns模式\e[0m"
read -n 1 -p "请输入：" dns
echo -e \\n"\e[1;36m↓↓ [编辑] 請选择代理模式 ↓↓\e[0m"\\n
echo -e "\e[36m0.gfwlist模式（默认）\\n1.大陆白名单模式\e[0m"
read -n 1 -p "请输入：" chinalist
echo -e \\n"\e[1;36m↓↓ [编辑] 請选择是否启用去广告功能 ↓↓\e[0m"\\n
echo -e "\e[36m0.不启用adblock（默认）\\n1.启用adblock\e[0m"
read -n 1 -p "请输入：" adblock
#其他功能
echo -e \\n"\e[1;36m↓↓ 請选择是否绕过大陆IP， 大陆IP将不进入${name}↓↓\e[0m"\\n
echo -e "\e[36m0.不启用bypasscnip\\n1.启用bypasscnip\e[0m（默认）"
read -n 1 -p "请输入：" bypasscnip
#自启
echo -e \\n"\e[1;36m↓↓ 請选择开机自启模式wan↓↓\e[0m"\\n
echo -e "\e[36m0.不启用\\n1.开机自启，仅检查进程（默认）\\n2.开机自启，强制重启进程\e[0m"
read -n 1 -p "请输入：" wan
echo -e \\n"\e[1;36m↓↓ 請选择定时启动模式cron↓↓\e[0m"\\n
echo -e "\e[36m0.不启用\\n1.定时启动，仅检查进程\\n2.定时启动，强制重启进程（默认）\e[0m"
read -n 1 -p "请输入：" cron
###
echo -e \\n"\e[1;37m你输入了：\\n\\n订阅链接1: $link1 \\n本地订阅文件: $clashfile1 \\n透明代理模式: $mode \\nedit编辑配置模式: $edit \\nDNS模式: $dns \\n去广告: $adblock\\n代理模式: $chinalist \\n开机自启wan: $wan \\n定时启动cron: $cron \e[0m"\\n
echo "link1=$link1
clashfile1=$clashfile1
mode=$mode
edit=$edit
dns=$dns
chinalist=$chinalist
bypasscnip=$bypasscnip
adblock=$adblock
wan=$wan
cron=$cron
" > $dirconf/settings.txt
sed -i '/^.*=$/'d $dirconf/settings.txt
}
#读取参数
read_settings () {
##读取配置文件全部参数
for a in $(cat $dirconf/settings.txt | grep '=' | grep -Ev '^#' | sed '1!G;h;$!d') ; do n=$(echo $a | awk -F= '{print $1}') ; b=$(echo $a | sed "s/${n}=//g") ; eval $n=$b ; done
##缺省参数补全
#透明代理模式，mode=1 透明代理（默认），mode=2 透明代理+自身代理，mode=3 不透明代理
[ -z "$mode" ] && mode=1 && echo "mode=$mode" >> $dirconf/settings.txt
#编辑模式
[ -z "$edit" ] && edit=1 && echo "edit=$edit" >> $dirconf/settings.txt
if [ "$edit" = "1" ] ; then
#DNS模式，1.redir-host （默认），2.fake-dns
[ -z "$dns" ] && dns=1 && echo "dns=$dns" >> $dirconf/settings.txt
#代理模式，0.gfwlist模式（默认），1.chinalist
[ -z "$chinalist" ] && chinalist=1 && echo "chinalist=$chinalist" >> $dirconf/settings.txt
#是否启用去广告，adblock=1则启用，关闭0（默认）
[ -z "$adblock" ] && adblock=0 && echo "adblock=$adblock" >> $dirconf/settings.txt
fi
#其他功能
#绕过cn ip
[ -z "$bypasscnip" ] && bypasscnip=1 && echo "bypasscnip=$bypasscnip" >> $dirconf/settings.txt
#是否启用脚本节点记忆与恢复mark，0.关闭（默认，直接使用自带.cache），1.打开
[ -z "$mark" ] && mark=0 && echo "mark=$mark" >> $dirconf/settings.txt
#使用自定义配置模板，留空则使用 config=config.yaml （默认）
[ "$config" = "config.yaml" ] && config="" && sed -i '/^config=/d' $dirconf/settings.txt && echo "config=" >> $dirconf/settings.txt
[ -z "$config" ] && config=244-config.yaml
#模板是否需要解密文件，secret=1 则进入解密模式，password为空时则关闭解密模式
if [ "$secret" = "1" ] ; then
[ -z "$password" ] && sed -i '/secret=/d' $dirconf/settings.txt && secret=0 && echo "secret=$secret" >> $dirconf/settings.txt
fi
#开机自启
[ -z "$wan" ] && wan=1 && echo "wan=$wan" >> $dirconf/settings.txt
#定时启动
[ -z "$cron" ] && cron=2 && echo "cron=$cron" >> $dirconf/settings.txt
#自定义闪存资源文件夹
if [ ! -z "$diretc" ] ; then
	if [ "$diretc" != "/tmp/${name}/etc" ] ; then
		[ ! -d $diretc ] && mkdir -p $diretc
		size=$(df $diretc | awk '!/Available/{print $4}')
		dirsize=$(du -s $diretc | awk '{print $1}')
		diretc_new=/tmp/${name}/etc
		if [ "$size" -eq "0" ] ; then
			echo "！！检测到$diretc已满，剩余空间$size KB，强制将资源文件夹改为 $diretc_new，并清空$diretc文件夹。"
			[ "$dirsize" -ne "0" ] && echo "> 清空文件夹$diretc内文件..." && rm -f $diretc/*
			[ "$(du -s $diretc | awk '{print $1}')" -eq "0" ] && echo "> 删除文件夹$diretc..." && rm -r $diretc
			sed -i '/diretc=/d' $dirconf/settings.txt
			diretc=$diretc_new
			echo "diretc=$diretc" >> $dirconf/settings.txt
		else
			if [ "$dirsize" -eq "0" ] ; then
				if [ "$size" -lt "12288" ] ; then
					echo "！！检测到$diretc剩余空间$size KB小于 12 MB，强制将资源文件夹改为 $diretc_new"
					sed -i '/diretc=/d' $dirconf/settings.txt
					diretc=$diretc_new
					echo "diretc=$diretc" >> $dirconf/settings.txt
				fi
			fi
		fi
	fi
else
	diretc=/tmp/${name}/etc && echo "diretc=$diretc" >> $dirconf/settings.txt
fi
#运行目录
[ -z "$dirtmp" ] && dirtmp=/tmp/${name} && echo "dirtmp=$dirtmp" >> $dirconf/settings.txt
}
if [ ! -z "$2" -a ! -z "$3" ] ; then
	#一键快速设置参数：./clash.sh 1 link1=https://123.com/link1.txt link2=https://123.com/link2.txt adblock=0 chinalist=0 bypasscnip=1
	echo "$@" | sed 's/ /\n/g' | grep "=" > $dirconf/settings.txt
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

export SKIP_SAFE_PATH_CHECK=1
run="$dirtmp/${name} -d $dirtmp"

pss='ps -w |grep -v grep| grep "$run"'
pid='pidof ${name}'
port='netstat -anp 2>/dev/null | grep "${name}"'
psskeep='ps -w | grep -v grep |grep "${name}_keep.sh"'
timenow='date "+%Y-%m-%d_%H:%M:%S"'
version="$dirtmp/${name} -v | head -n 1 | cut -f 3 -d ' '|sed 's/v//'"
log_ok='grep -E "TProxy server listening at|TProxy.* proxy listening at" ./${name}_log.txt'
log_error='grep "TProxy server error" ./${name}_log.txt'

#alias
[ "$(shopt 2>/dev/null | awk '/expand_aliases/{print $2}')" = "off" ] && shopt -s expand_aliases
alias pss=$pss
alias pid=$pid
alias port=$port
alias psskeep=$psskeep
alias timenow=$timenow
alias version=$version
alias log_ok=$log_ok
alias log_error=$log_error

[ ! -d $diretc ] && mkdir -p $diretc
[ ! -d $dirtmp ] && mkdir -p $dirtmp
cd $dirtmp


edit_chinalist () {
#是否启用大陆白名单功能，1启用chinalist，0则默认gfwlist
if [ "$chinalist" = "1" ] ; then
sed -i '/#markgfwlistorchinalist1/s@- ➡️直连 #@- 🎯代理 #@g;/#markgfwlistorchinalist2/s@- 🎯代理 #@- ➡️直连 #@g' config.yaml
fi
}
edit_dns () {
#DNS模式，2启用fake-ip，非2则默认redir-host
[ "$dns" = "2" ] && sed -i 's/enhanced-mode: redir-host/enhanced-mode: fake-ip/g' config.yaml
}
edit_port () {
configfile=./config.yaml
if [ -s $configfile ] ; then
	#提取redir-port透明代理端口
	#redir_port=$(cat $configfile | awk '/^redir-port:/{print $2}' | sed 's/"//g' | grep -E '^[0-9]+$')
	#提取tproxy-port透明代理端口
	if [ ! -z "$(cat $configfile | awk '/^tproxy-port:/{print $0}')" ] ; then
		get_tproxy_port=$(cat $configfile | awk '/^tproxy-port:/{print $2}' | sed 's/"//g' | grep -E '^[0-9]+$')
		[ ! -z "$get_tproxy_port" -a ! -z "$tproxy_port" -a "$get_tproxy_port" != "$tproxy_port" ] && echo " * 修改配置文件的tproxy_port端口为 $tproxy_port" && sed -i "/^tproxy-port:/s/$get_tproxy_port/$tproxy_port/g" $configfile
	elif [ ! -z "$(cat $configfile | awk '/^-.*type: tproxy/{print $0}')" ] ; then
		get_tproxy_port=$(cat $configfile | awk '/^-.*type: tproxy/{print $0}' | grep -Eo 'port:.*,' | awk '{print $2}' | grep -Eo '[0-9]+')
		[ ! -z "$get_tproxy_port" -a ! -z "$tproxy_port" -a "$get_tproxy_port" != "$tproxy_port" ] && echo " * 修改配置文件的tproxy_port端口为 $tproxy_port" && sed -i "/^-.*type: tproxy/s/$get_tproxy_port/$tproxy_port/g" $configfile
	fi
	#提取DNS监听端口
	get_dns_port=$(cat $configfile | sed -n '/^dns:$/,$p' | awk -F: '/listen:/{print $NF}' | grep -E '^[0-9]+$')
	[ ! -z "$get_dns_port" -a ! -z "$dns_port" -a "$get_dns_port" != "$dns_port" ] && echo " * 修改配置文件的dns_port端口为 $dns_port" && sed -i "/listen: .*:$get_dns_port/s/$get_dns_port/$dns_port/g" $configfile
fi
}

edit_proxy_providers () {
f=$1
n=$2
p=$3
u=$4
update=$5
health_check_url=$6
health_check_interval=$7
#1，proxy-providers:下面插入订阅
if [ "$f" = "订阅" ] ; then
sed -i "/^proxy-providers:$/a\  ${f}${n}:\n    type: http\n    url: $u\n    interval: $update\n    path: $p\n    health-check:\n      enable: true\n      interval: $health_check_interval\n      url: $health_check_url" config.yaml
elif [ "$f" = "文件" ] ; then
sed -i "/^proxy-providers:$/a\  ${f}${n}:\n    type: file\n    interval: $update\n    path: $p\n    health-check:\n      enable: true\n      interval: $health_check_interval\n      url: $health_check_url" config.yaml
else
echo "错误，proxy-providers类型不为http与file，结束" && exit
fi
#2，#mark_proxy_groups下面插入
sed -i "/#mark_proxy_groups$/a\  - { name: \"故障-${f}${n}\", type: fallback, use: [\"${f}${n}\"] }\n  - { name: \"延迟-${f}${n}\", type: url-test, use: [\"${f}${n}\"] }\n  - { name: \"负载-${f}${n}\", type: load-balance, strategy: round-robin, use: [\"${f}${n}\"] }" config.yaml
#3，  use:上下插入
#sed -i "/^    use:$/i\      - 故障-${f}${n}\n      - 延迟-${f}${n}\n      - 负载-${f}${n}" config.yaml
sed -i "/^    use:/a\      - ${f}${n}" config.yaml
#4，  use: #usemark下面插入
#sed -i "/^    use: #usemark$/a\      - ${f}${n}" config.yaml
}

edit_link () {
[ ! -f $dirconf/test.txt ] && echo -e "proxies:\\n" > $dirconf/test.txt
#file
for providers_file in $(ls -r $dirconf/file[0-9]*.txt 2>/dev/null)
do
a=${providers_file##*/}
echo ">> [proxy providers] 添加本地订阅文件： $a"
f="文件"
n=$(echo $a | sed 's/^file//g;s/.txt//g')
p=$providers_file
u="none"
update=$(awk -F '#update=' '/^#update=/{print $2}' $providers_file)
[ -z "$update" ] && update=30000
health_check_url=$(awk -F '#url=' '/^#url=/{print $2}' $providers_file)
[ -z "$health_check_url" ] && health_check_url="http://clients2.google.com/generate_204"
health_check_interval=$(awk -F '#interval=' '/^#interval=/{print $2}' $providers_file)
if [ -z "$health_check_interval" ] ; then random_mum=$(cat /proc/sys/kernel/random/uuid | sed 's/[a-zA-Z]//g;s/-//g' | head -c 2) ; [ -z "$(echo $random_mum | grep -E '^[0-9]+$')" ] && random_mum=0 ; health_check_interval=$(expr 300 + $random_mum) ; fi
edit_proxy_providers $f $n $p $u $update $health_check_url $health_check_interval
done
#http
for providers_http in $(cat $dirconf/settings.txt | grep -E '^link[0-9]+=' | sort -ur)
do
a=$(echo $providers_http | grep -Eo '^link[0-9]+=' | sed 's/=$//g')
echo ">> [proxy providers] 添加在线订阅链接： $a"
f="订阅"
n=$(echo $a | sed 's/^link//g')
p=$dirconf/${f}${n}.txt
u=$(echo $providers_http | sed "s/^link${n}=//g")
update=30000
health_check_url="http://clients1.google.com/generate_204"
random_mum=$(cat /proc/sys/kernel/random/uuid | sed 's/[a-zA-Z]//g;s/-//g' | head -c 2) ; [ -z "$(echo $random_mum | grep -E '^[0-9]+$')" ] && random_mum=0
health_check_interval=$(expr 300 + $random_mum)
edit_proxy_providers $f $n $p $u $update $health_check_url $health_check_interval
done
#  use:上插入
for n in $(cat $dirconf/settings.txt | grep -Eo '^link[0-9]+=' | sed 's/^link//g;s/=$//g' | sort -u) ; do f="订阅" && sed -i "/^    use:$/i\      - 故障-${f}${n}\n      - 延迟-${f}${n}\n      - 负载-${f}${n}" config.yaml ; done
for n in $(ls $dirconf/file[0-9]*.txt 2>/dev/null | awk -F '/' '{print $NF}' | sed 's/^file//g;s/.txt//g') ; do f="文件" && sed -i "/^    use:$/i\      - 故障-${f}${n}\n      - 延迟-${f}${n}\n      - 负载-${f}${n}" config.yaml ; done
}

edit_adblock () {
#是否启用去广告功能，1启用，非1则默认关闭
[ "$adblock" != "1" ] && sed -i '/#markadblock/d' config.yaml
}


function downloadfile () {
#读取参数
for a in $(echo "$@" | sed 's/ /\n/g' | grep "=") ; do n=$(echo $a | awk -F= '{print $1}') ; b=$(echo $a | sed "s/${n}=//g") ; eval $n=$b ; done
#filename：本地文件名字
[ -z "$filename" ] && echo "download file错误，文件名filename参数为空" && exit
#filetgz：压缩包文件名字
[ -z "$filetgz" ] && echo "download file错误，文件filetgz参数为空" && exit
#fileout：解压到目录，留空则默认路径使用./
[ -z $fileout ] && fileout=./
#address：文件下载地址或名字
[ -z "$address" ] && echo "download file错误，文件地址address参数为空" && exit
#decrypt：文件是否需要解密，decrypt=1则需要解密
#password：文件密码，password=123456
#############
#临时下载文件夹
[ ! -d $dirtmp/downloadfile ] && mkdir -p $dirtmp/downloadfile
#是否走proxy socks5
[ ! -z "$(pidof clash)" -a ! -z "$(netstat -anp 2>/dev/null | grep clash)" ] && proxy_work=1 || proxy_work=0
#获取URL
if [ -z "${force_url}" ] ; then
all_url=$(set | grep -E "^url[0-9]+=" | sed '/"/d' | sed -E "s/'//g;s/^url[0-9]+=//g")
else
all_url=$(set | grep -E "^url${force_url}=" | sed '/"/d' | sed -E "s/'//g;s/^url${force_url}=//g")
fi
max_url=$(echo $all_url | sed 's/ /\n/g' | wc -l)
u=1
for url in $all_url
do
{
#判断url是否为raw.githubusercontent.com，是则需要走proxy，无proxy则跳过
if [ ! -z "$(echo $url | grep "^https://raw.githubusercontent.com/")" ] ; then
	if [ "$proxy_work" = "1" ] ; then
		curl="curl -x socks5h://127.0.0.1:8005"
		proxy_status=" and SOCKS5 PROXY"
	else
		raw_status=$(curl -s -m 3 https://raw.githubusercontent.com -o /dev/null -w "%{http_code}")
		if [ "$raw_status" = "200" -o "$raw_status" = "301" ] ; then
			curl="curl"
			proxy_status=""
		else
			u=$((u+1))
			continue
		fi
	fi
else
	curl="curl"
	proxy_status=""
fi
#补全地址
if [ -z "$(echo $address | grep ^http)" ] ; then
	link="$url/$address"
else
	link=$address
	url=${address%/*}
	address=${address##*/}
fi
echo -e \\n"\e[1;44m★[$u/$max_url]『$filename』use URL <$link>$proxy_status is downloading... \e[0m"
########
#检验文件，可选算法SHA1、SHAKE128
[ ! -z "$(openssl dgst -list 2>&1 | grep -i shake128)" ] && hash=SHAKE128 || hash=SHA1
hashfile=${hash}.TXT
#下载次数
m=5
n=1
while true
do
if [ $n -le $m ] ; then
	if [ "$n" = "1" ] ; then
		#下载校验文件
		t=1
		tt=5
		while true
		do
		if [ $t -le $tt ] ; then
			echo -e \\n"\e[36m▶『$filename』[$t/$tt]下载校验文件$hashfile：<$url/$hashfile> ......\e[0m"
			$curl -m 10 -sL $url/$hashfile -o $diretc/$hashfile -w "\n📑 $filename [$t/$tt] - $hashfile - 状态: %{http_code} - 耗时: %{time_total} s - 速度: %{speed_download} B/s\n"
			if [ "$?" = "0" ] ; then
				cp -f $diretc/$hashfile ${path}/$hashfile
				ver=$(cat ${path}/$hashfile | awk -F// '/【/{print $2}')
				echo -e \\n"\e[1;37m    ◆ 『$filename』[$t/$tt] $hashfile版本：$ver\e[0m"
				download_hashfile_status=1
				break
			else
				echo -e \\n"\e[1;31m    ✘ 『$filename』[$t/$tt] $hashfile校验文件下载错误。\e[0m"\\n
				t=$((t+1))
				continue
			fi
		else
			if [ "$u" = "$max_url" -a -s ${path}/$hashfile ] ; then
				logger -t "【${bashname}】" " 『$filename』直接使用本地${path}/$hashfile检验文件。t=$t/$tt，u=$u/$max_url"
				echo -e \\n"\e[1;37m『$filename』直接使用本地${path}/$hashfile检验文件。t=$t/$tt，u=$u/$max_url\e[0m"
				ver=$(cat ${path}/$hashfile | awk -F// '/【/{print $2}')
				echo -e \\n"\e[1;37m    ◆ 『$filename』[$t/$tt] $hashfile版本：$ver\e[0m"
				download_hashfile_status=1
				break
			else
				logger -t "【${bashname}】" " ✘ 『$filename』$hashfile检验文件使用URL <$url/$hashfile> 下载[$tt]次都失败，无法下一步下载文件$filename，跳过当前URL！"
				echo -e \\n"\e[1;31m✘『$filename』$hashfile检验文件使用URL <$url/$hashfile> 下载[$tt]次都失败，无法下一步下载文件$filename，跳过当前URL！\e[0m"
				download_hashfile_status=0
				break 2
			fi
		fi
		done
	fi
	logger -t "【${bashname}】" "▶『$filename』開始第[$n/$m]次下载$filetgz......"
	echo -e \\n"\e[1;36m▶『$filename』開始第[$n/$m]次下载$filetgz......\e[0m"
	if [ -s $diretc/$filetgz ] ; then
		localfile=$(openssl $hash $diretc/$filetgz |awk '{print $2}')
		newdownload=0
	else
		logger -t "【${bashname}】" "▶『$filename』[$n/$m]下载文件$filetgz：<$link> ..."
		echo -e \\n"\e[1;7;37m▶『$filename』[$n/$m]下载文件$filetgz：<$link> ...\e[0m"
		[ ! -z "$(ps -w | grep -v grep | grep "curl.*-o $dirtmp/downloadfile/$filetgz ")" ] && echo -e "\e[1;37m！已存在curl下載$filetgz進程，先kill。\\n$(ps -w | grep -v grep | grep "curl.*-o $dirtmp/downloadfile/$filetgz ")\e[0m" && ps -w | grep -v grep | grep "curl.*-o $dirtmp/downloadfile/$filetgz " | awk '{print $1}' | xargs kill -9
		$curl -o $dirtmp/downloadfile/$filetgz -sL $link -w "\n⬇️ $filename [$n/$m] - 状态: %{http_code} - 耗时: %{time_total} s - 速度: %{speed_download} B/s\n"
		if [ "$?" = "0" ] ; then
			localfile=$(openssl $hash $dirtmp/downloadfile/$filetgz |awk '{print $2}')
			newdownload=1
		else
			echo -e \\n"\e[1;31m   ✘ 『$filename』[$n/$m] curl下载文件$filetgz错误。\e[0m"\\n
			n=$((n+1))
			continue
		fi
	fi
	new=$(cat ${path}/$hashfile | grep $address | awk -F ' ' '/\/'$filetgz'=/{print $2}')
	echo -e \\n"文件：$filetgz \\n本地：$localfile \\n最新：$new"
	if [ ! -z "$localfile" -a ! -z "$new" ] ; then
		if [ "$localfile" = "$new" ] ; then
			if [ "$newdownload" = "1" ] ; then
				logger -t "【${bashname}】" "✓『$filename』 新下载文件$dirtmp/downloadfile/$filetgz校验成功，移动到[ $diretc/$filetgz ]"
				echo -e \\n"\e[36m✓『$filename』新下载文件$dirtmp/downloadfile/$filetgz校验成功，移动到[ $diretc/$filetgz ]\e[0m"
				mv -f $dirtmp/downloadfile/$filetgz $diretc/$filetgz
			else
				logger -t "【${bashname}】" "✓『$filename』旧文件$diretc/$filetgz校验成功"
				echo -e \\n"\e[36m✓『$filename』旧文件$diretc/$filetgz校验成功\e[0m"
			fi
			download_ok=1
		else
			logger -t "【${bashname}】" "✘『$filename』$filetgz文件$hash對比不一致，校验失败，刪除旧文件$diretc/$filetgz，重新下载！"
			echo -e \\n"\e[1;35m    ✘ 『$filename』$filetgz文件$hash對比不一致，校验失败，刪除旧文件$diretc/$filetgz，重新下载！\e[0m"
			rm -rf $diretc/$filetgz
			download_ok=0
		fi
	else
		[ -z "$localfile" ] && logger -t "【${bashname}】" "✘『$filename』$filetgz文件openssl生成$hash為空。" && echo -e \\n"\e[1;31m    ✘ 『$filename』$filetgz文件openssl生成$hash為空。\e[0m"
		[ -z "$new" ] && logger -t "【${bashname}】" "✘『$filename』$hashfile校驗文件內沒有$filetgz文件" && echo -e \\n"\e[1;31m    ✘ 『$filename』$hashfile校驗文件內沒有$filetgz文件。\e[0m"
		download_ok=0
	fi
	#下载完成后检查文件类型是否需要解压与解密
	if [ "$download_ok" = "1" ] ; then
		type=${filetgz##*.}
		if [ "$type" = "tgz" ] ; then
			echo -e \\n"\e[36m▷解压文件$diretc/$filetgz到目录[ $fileout ]...\e[0m"
			tar xzvf $diretc/$filetgz -C $fileout
			[ "$?" = "0" ] && echo -e \\n"\e[32m✔ 文件$filetgz解压完成！\e[0m"\\n || echo -e \\n"\e[31m✖ 文件$filetgz解压失败！\e[0m"\\n
		elif [ "$type" = "zip" ] ; then
			echo -e \\n"\e[36m▷解压文件$diretc/$filetgz到目录[ $fileout ]...\e[0m"
			[ -z "$(which unzip)" ] && echo -e "  >> 检测到opt需要安装unzip..." && opkg update && opkg install unzip
			unzip -o $diretc/$filetgz -d $fileout
			[ "$?" = "0" ] && echo -e \\n"\e[32m✔ 文件$filetgz解压完成！\e[0m"\\n || echo -e \\n"\e[31m✖ 文件$filetgz解压失败！\e[0m"\\n
		elif [ "$decrypt" = "1" ] ; then
			echo -e \\n"\e[36m▷解密文件$diretc/$filetgz到[ $fileout/$filename ]...\e[0m"
			cat $diretc/$filetgz | openssl enc -aes-256-ctr -d -a -md md5 -k $password > $fileout/$filename
			[ "$?" = "0" ] && echo -e \\n"\e[32m✔ 文件$filetgz解密到[ $fileout/$filename ]完成！\e[0m"\\n || echo -e \\n"\e[31m✖ 文件$filetgz解密到[ $fileout/$filename ]失败！\e[0m"\\n
		else
			cp -f $diretc/$filetgz $fileout/$filename
			echo -e \\n"\e[32m✔ 直接复制$diretc/$filetgz文件到[ $fileout/$filename ] ！\e[0m"\\n
		fi
		all_download_results=1
		#跳出循环
		break 2
	fi
	n=$((n+1))
else
	logger -t "【${bashname}】" "✖『$filename』[$m]次下载都失败！！！"
	echo -e \\n"\e[1;31m✖『$filename』[$m]次下载都失败！！！\e[0m"\\n
	all_download_results=0
	break
fi
done
}
u=$((u+1))
done
}


#下载文件并解密
#downloadfile address=t/c filetgz=c decrypt=1 password=1+1=1 fileout=./ filename=config.yaml
#下载文件并解压
#downloadfile address=t/Country.mmdb.tgz filetgz=Country.mmdb.tgz fileout=/tmp filename=Country.mmdb
#下载文件
#downloadfile address=t/clash filetgz=clash fileout=./ filename=clash


#下载主程序
down_program () {
file=${name}
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=$file
fi
[ -s ./$file ] && [ ! -x ./$file ] && echo ">> 赋予主程序文件$file执行权限" && chmod +x ./$file
}
#下载Country.mmdb
down_mmdb () {
file=Country.mmdb
[ -s ./${name}_log.txt ] && [ ! -z "$(grep -io "Can't load mmdb" ./${name}_log.txt)" -o ! -z "$(grep -io "Can't find MMDB" ./${name}_log.txt)" ] && logger -t "【${bashname}】" "删除无效Country.mmdb文件" && echo "  >> 删除无效Country.mmdb文件 " && rm -rf ./Country.mmdb
if [ ! -s ./Country.mmdb -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file.tgz filetgz=$file.tgz fileout=./ filename=Country.mmdb
fi
}
#下载geoip
down_geoip () {
file=geoip.dat
[ -s ./${name}_log.txt ] && [ ! -z "$(grep -io "can't initial geoip" ./${name}_log.txt)" ] && logger -t "【${bashname}】" "删除无效geoip.dat文件" && echo "  >> 删除无效geoip.dat文件 " && rm -rf ./geoip.dat
if [ ! -s ./geoip.dat -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=geoip.dat
fi
}
down_geoip_full () {
file=geoip-full.dat
[ -s ./${name}_log.txt ] && [ ! -z "$(grep -io "can't initial geoip" ./${name}_log.txt)" ] && logger -t "【${bashname}】" "删除无效geoip.dat文件" && echo "  >> 删除无效geoip.dat文件 " && rm -rf ./geoip.dat
if [ ! -s ./geoip.dat -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=geoip.dat
fi
}
#下载geosite
down_geosite () {
file=geosite.dat
[ -s ./${name}_log.txt ] && [ ! -z "$(grep -io "can't initial GeoSite" ./${name}_log.txt)" ] && logger -t "【${bashname}】" "删除无效geosite.dat文件" && echo "  >> 删除无效geosite.dat文件 " && rm -rf ./geosite.dat
if [ ! -s ./geosite.dat -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=geosite.dat
fi
}
down_geosite_full () {
file=geosite-full.dat
[ -s ./${name}_log.txt ] && [ ! -z "$(grep -io "can't initial GeoSite" ./${name}_log.txt)" ] && logger -t "【${bashname}】" "删除无效geosite.dat文件" && echo "  >> 删除无效geosite.dat文件 " && rm -rf ./geosite.dat
if [ ! -s ./geosite.dat -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=geosite.dat
fi
}
#下载主題Web文件
down_web () {
file="clash-dashboard-gh-pages"
if [ ! -s ./$file/index.html -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file.tgz filetgz=$file.tgz fileout=./ filename=$file
fi
}
#下载config.yaml
down_config () {
file=$config
if [ "$secret" = "1" ] ; then
	downloadfile address=s/$file filetgz=$file decrypt=1 password=$password fileout=./ filename=config.yaml 
else
	downloadfile address=config/$file filetgz=$file fileout=./ filename=config.yaml
fi
}
#download ipset.cnip.txt
down_ipset_cnip () {
file="ipset.cnip.txt"
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=$file 
fi
}
down_ipset_cnipv6 () {
file="ipset.cnipv6.txt"
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=$file 
fi
}
#下载rule
down_rule () {
file="rule"
#[ -z "$(ls ./rule 2>/dev/null)" ] && need_down_rule=1
need_down_rule=1
if [ "$need_down_rule" = "1" -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file.tgz filetgz=$file.tgz fileout=./ filename=$file
fi
}
#下载clashfile
down_clashfile () {
for clashfile_all in $(cat $dirconf/settings.txt | grep -E '^clashfile[0-9]+=' | sort -ur)
do
a=$(echo $clashfile_all | grep -Eo '^clashfile[0-9]+=' | sed 's/=$//g')
u=$(echo $clashfile_all | sed -E "s/^clashfile[0-9]+=//g")
if [ ! -z "$u" -a "$u" != "0" ] ; then
	n=$(echo $u | awk -F ',' '{print $1}')
	p=$(echo $u | awk -F ',' '{print $2}')
	if [ ! -z "$(echo $n | grep -E '^file[0-9]+.txt')" ] ; then
		if [ ! -z "$p" ] ; then
			downloadfile address=s/$n filetgz=$n decrypt=1 password=$p fileout=$dirconf filename=$n &
		else
			downloadfile address=$n filetgz=$n fileout=$dirconf filename=$n &
		fi
	else
		echo -e \\n"\e[1;31m  ✖ [clashfile providers] 本地订阅 $a 文件名 $n 不符合格式 [file*.txt]，跳过下载。\e[0m"\\n
	fi
fi
done
}


setmark () {
configfile=./config.yaml
secret=$(cat $configfile | awk '/^secret:/{print $2}' | sed 's/"//g')
port=$(cat $configfile | awk -F: '/^external-controller/{print $3}')
curl -s -X GET "http://127.0.0.1:$port/proxies" -H "Authorization: Bearer $secret" | sed 's/\},/\},\n/g' | grep "Selector" | grep "now" |grep -Eo "name.*" > ./mark/setmark_new.txt
if [ ! -s ./mark/setmark_old.txt ] ; then
	if [ ! -s $dirconf/setmark.txt ] ; then
		echo -e \\n"\e[1;36m▶直接保存[节点位置记录]到$dirconf/setmark.txt ...\e[0m"
		cp -f ./mark/setmark_new.txt ./mark/setmark_old.txt
		cp -f ./mark/setmark_new.txt $dirconf/setmark.txt
		[ -f ./mark/setmark_ok_* ] && rm ./mark/setmark_ok_*
		> ./mark/setmark_ok_0
		exit
	else
		cp -f $dirconf/setmark.txt ./mark/setmark_old.txt
	fi
fi
new=$(openssl SHA1 ./mark/setmark_new.txt |awk '{print $2}')
old=$(openssl SHA1 ./mark/setmark_old.txt |awk '{print $2}')
if [ ! -z "$new" ] ; then
	if [ "$new" != "$old" ] ; then
		echo -e \\n"\e[1;36m▶保存新[节点位置记录]到$dirconf/setmark.txt ...\e[0m"
		cp -f ./mark/setmark_new.txt ./mark/setmark_old.txt
		cp -f ./mark/setmark_new.txt $dirconf/setmark.txt
		[ -f ./mark/setmark_ok_* ] && rm ./mark/setmark_ok_*
		> ./mark/setmark_ok_0
	else
		#echo "节点位置记录文件无需更新"
		[ -f ./mark/setmark_ok_* ] && rm ./mark/setmark_ok_*
		> ./mark/setmark_ok_1
	fi
else
	echo "✗導出新[节点位置记录]為空，跳過是setmark。"
	[ -f ./mark/setmark_ok_* ] && rm ./mark/setmark_ok_*
	> ./mark/setmark_ok_none
fi
}
start_setmark () {
[ ! -d ./mark ] && mkdir -p ./mark
if [ -f ./mark/start_remark_ok_0 ] ; then
	start_remark
else
	setmark
fi
}

remark_while () {
while read a
do
	group=$(echo $a|grep -Eo "name.*"|awk -F\" '{print $3}')
	now=$(echo $a|grep -Eo "now.*"|awk -F\" '{print $3}')
	if [ -z "$(echo "$group" | grep -E '^[A-Za-z0-9]+$')" ] ; then
		encode=$(curl -sv -G --data-urlencode "$group" -X GET "http://127.0.0.1:$port" 2>&1 |awk '/GET/{print $3}'|sed 's@/?@@')
	else
		encode=$group
	fi
	echo -e \\n"★$a"
	echo -e "●策略组：$group → 上次选中：$now"
	echo -e "■encode编码：$encode"
	curl -sv -X PUT "http://127.0.0.1:$port/proxies/$encode" -H "Authorization: Bearer $secret" -d "{\"name\": \"$now\"}" 2>&1
done < $dirconf/setmark.txt
}
remark_for () {
IFS=$'\n'
for a in $(cat $dirconf/setmark.txt)
do
	group=$(echo $a|grep -Eo "name.*"|awk -F\" '{print $3}')
	now=$(echo $a|grep -Eo "now.*"|awk -F\" '{print $3}')
	if [ -z "$(echo "$group" | grep -E '^[A-Za-z0-9]+$')" ] ; then
		encode=$(curl -sv -G --data-urlencode "$group" -X GET "http://127.0.0.1:$port" 2>&1 |awk '/GET/{print $3}'|sed 's@/?@@')
	else
		encode=$group
	fi
	echo -e \\n"★$a"
	echo -e "●策略组：$group → 上次选中：$now"
	echo -e "■encode编码：$encode"
	curl -sv -X PUT "http://127.0.0.1:$port/proxies/$encode" -H "Authorization: Bearer $secret" -d "{\"name\": \"$now\"}" 2>&1
done
}
remark () {
[ ! -d ./mark ] && mkdir -p ./mark
configfile=./config.yaml
secret=$(cat $configfile | awk '/^secret:/{print $2}' | sed 's/"//g')
port=$(cat $configfile | awk -F: '/^external-controller/{print $3}')
if [ -s $dirconf/setmark.txt ] ; then
echo -e \\n"\e[1;36m▶还原节点位置记录...\e[0m"
#remark_for > ./mark/remark_status.txt
remark_while > ./mark/remark_status.txt
sed -i "1i\######$(timenow) #######" ./mark/remark_status.txt
else
echo -e \\n"\e[1;37m▷节点位置记录文件不存在$dirconf/setmark.txt，跳过还原。\e[0m"
fi
}
start_remark () {
if [ ! -z "$(pss)" -a ! -z "$(port)" ] ; then
	remark
	work_ok=1
	[ -f ./mark/start_remark_ok_* ] && rm ./mark/start_remark_ok_*
	> ./mark/start_remark_ok_1
else
	#echo "    ✖ start_remark：${name}进程或端口没启动成功，跳过还原节点记录。"
	work_ok=0
	[ -f ./mark/start_remark_ok_* ] && rm ./mark/start_remark_ok_*
	> ./mark/start_remark_ok_0
fi
}

check_cache_file () {
filename1=.cache
filename2=cache.db
[ -f $dirconf/$filename1 ] && rm -f $dirconf/$filename1
filename=$filename2
#
#内存文件存在、闪存文件存在
if [ -f $dirtmp/$filename -a -f $dirconf/$filename ] ; then
	#若非软链接
	if [ ! -h $dirtmp/$filename ] ; then
		echo "▷$dirconf/$filename、$dirtmp/$filename都文件存在但$dirtmp/$filename非软连接。移动文件$dirtmp/$filename到$dirconf/$filename，重新生成软链接文件$dirtmp/$filename"
		mv -f $dirconf/$filename $dirconf/${filename}_backup
		mv -f $dirtmp/$filename $dirconf/$filename
		ln -s $dirconf/$filename $dirtmp/$filename
	fi
#内存文件存在、闪存文件不存在
elif [ -f $dirtmp/$filename -a ! -f $dirconf/$filename ] ; then
	#若非软链接
	if [ ! -h $dirtmp/$filename ] ; then
		echo "▷$dirconf/$filename文件不存在但$dirtmp/$filename文件存在。移动文件$dirtmp/$filename到$dirconf/$filename，重新生成软链接文件$dirtmp/$filename"
		mv -f $dirtmp/$filename $dirconf/$filename
		ln -s $dirconf/$filename $dirtmp/$filename
	else
		echo "▷$dirconf/$filename文件不存在且$dirtmp/$filename为软链接。删除无效软链接，创建空白文件$dirconf/$filename并生成软链接文件$dirtmp/$filename"
		rm $dirtmp/$filename
		> $dirconf/$filename
		ln -s $dirconf/$filename $dirtmp/$filename
	fi
#内存文件不存在、闪存文件存在，直接创建软链接
elif [ ! -f $dirtmp/$filename -a -f $dirconf/$filename ] ; then
	echo "▷$dirconf/$filename文件存在但$dirtmp/$filename不存在。生成软链接文件$dirtmp/$filename"
	ln -s $dirconf/$filename $dirtmp/$filename
#内存文件不存在、闪存文件不存在，直接创建软链接
elif [ ! -f $dirtmp/$filename -a ! -f $dirconf/$filename ] ; then
	echo "▷$dirconf/$filename、$dirtmp/$filename文件都不存在。创建空白文件$dirconf/$filename并生成软链接文件$dirtmp/$filename"
	> $dirconf/$filename
	ln -s $dirconf/$filename $dirtmp/$filename
fi
}

ipset_local_ipv4 () {
ipset -N localipv4 hash:net family inet
ipset add localipv4 0.0.0.0/8
ipset add localipv4 0.0.0.0/8
ipset add localipv4 10.0.0.0/8
ipset add localipv4 100.64.0.0/10
ipset add localipv4 127.0.0.0/8
ipset add localipv4 169.254.0.0/16
ipset add localipv4 172.16.0.0/12
ipset add localipv4 192.0.0.0/24
ipset add localipv4 192.0.2.0/24
ipset add localipv4 192.88.99.0/24
ipset add localipv4 192.168.0.0/16
ipset add localipv4 198.18.0.0/15
ipset add localipv4 198.51.100.0/24
ipset add localipv4 203.0.113.0/24
ipset add localipv4 224.0.0.0/4
ipset add localipv4 240.0.0.0/4
ipset add localipv4 255.255.255.255/32
}
ipset_local_ipv6 () {
ipset -N localipv6 hash:net family inet6
ipset add localipv6 ::/128
ipset add localipv6 ::1/128
ipset add localipv6 ::ffff:0:0/96
ipset add localipv6 ::ffff:0:0:0/96
ipset add localipv6 64:ff9b::/96
ipset add localipv6 100::/64
ipset add localipv6 2001::/32
ipset add localipv6 2001:20::/28
ipset add localipv6 2001:db8::/32
ipset add localipv6 2002::/16
ipset add localipv6 fe80::/10
ipset add localipv6 fc00::/7
ipset add localipv6 fd00::/8
ipset add localipv6 ff00::/8
}

bypass_lan_ip () {
[ ! -f $dirconf/bypasslan.txt ] && > $dirconf/bypasslan.txt
echo -e \\n"\e[1;37m--------------------\\n    【黑名单】\\n绕过代理的来源局域网IP/MAC列表\\n$dirconf/bypasslan.txt\\n--------------------\e[0m"
if [ -s $dirconf/bypasslan.txt ] ; then
cat $dirconf/bypasslan.txt | awk '{print "\e[1;33m第"NR"行\e[0m " "\e[1;36m" $0 "\e[0m"}'
else
echo "     （空）"
fi
echo -e "\e[1;37m--------------------\e[0m"
echo -e \\n"\e[1;37m↓输入IP地址或MAC地址↓\e[0m"
echo -e "* 输入0将重置列表，输入d将删除列表某一行，输入1将使用vi编辑文件"\\n
read -p "请输入：" lanip
if [ "$lanip" = "0" ] ; then
	> $dirconf/bypasslan.txt
	echo -e \\n"\e[1;37m已重置IP/MAC列表bypasslan.txt。\e[0m"\\n
elif [ "$lanip" = "1" ] ; then
	vi $dirconf/bypasslan.txt
elif [ "$lanip" = "d" -o "$lanip" = "D" ] ; then
	echo -e \\n"\e[1;37m--------------------\e[0m"
	cat $dirconf/bypasslan.txt | awk '{print "\e[1;33m第"NR"行\e[0m " "\e[1;36m" $0 "\e[0m"}'
	echo -e "\e[1;37m--------------------\e[0m"\\n
	read -p "请输入要删除的行号：" num
	if [ ! -z "$(echo $num|grep -E '^[0-9]+$')" ] ; then
		sed -i "${num}d" $dirconf/bypasslan.txt
		echo -e \\n"\e[1;37m已删除bypasslan.txt第${num}行。\e[0m"\\n
	else
		echo -e \\n"\e[1;37m✖输入非数字，取消删除行。\e[0m"\\n
	fi
else
	echo "$lanip" | grep -v '^ *$' >> $dirconf/bypasslan.txt
	[ ! -z "$(sed -n '/^ *$/=' $dirconf/bypasslan.txt)" ] && echo "删除空行" && sed -i '/^ *$/d' $dirconf/bypasslan.txt
fi
}
bypasslan () {
#黑名单，局域网绕过
if [ -s $dirconf/bypasslan.txt ] ; then
	logger -t "【${bashname}】" "▶[黑名单]添加iptables/ip6tables绕过来源局域网IP/MAC与劫持DNS.." && echo -e \\n"\e[1;36m▶[黑名单]添加iptables/ip6tables绕过来源局域网IP/MAC与劫持DNS...\e[0m"
	#IP地址
	iplist=$(cat $dirconf/bypasslan.txt | grep -Ev '^#|^ *$' | grep -Eo '([0-9]+\.){3}[0-9]+.*')
	if [ ! -z "$iplist" ] ; then
		[ ! -z "$(ipset list | grep bypass_lan_ip)" ] && ipset -X bypass_lan_ip
		ipset -N bypass_lan_ip hash:net
		IFS=$'\n'
		for ip in $iplist
		do
			echo "  ✚ [bypasslan] 绕过来源局域网IP：$ip"
			ipset add bypass_lan_ip $ip
		done
		iptables -t mangle -I $name -m set --match-set bypass_lan_ip src -j RETURN
		iptables -t nat -I dns_redir -m set --match-set bypass_lan_ip src -j RETURN
	fi
	#MAC地址
	maclist=$(cat $dirconf/bypasslan.txt | grep -Ev '^#|^ *$' | grep -Eo '([0-9a-fA-F]{2})(([\s:/-][0-9a-fA-F]{2}){5})')
	if [ ! -z "$maclist" ] ; then
		[ ! -z "$(ipset list | grep bypass_lan_mac)" ] && ipset -X bypass_lan_mac
		ipset -N bypass_lan_mac hash:mac
		IFS=$'\n'
		for mac in $maclist
		do
			echo "  ✚ [bypasslan] 绕过来源局域网MAC：$mac"
			ipset add bypass_lan_mac $mac
		done
		iptables -t mangle -I $name -m set --match-set bypass_lan_mac src -j RETURN
		iptables -t nat -I dns_redir -m set --match-set bypass_lan_mac src -j RETURN
		ip6tables -t mangle -I $name -m set --match-set bypass_lan_mac src -j RETURN
		[ -z "$(ip6tables -t nat -nL 2>&1 |grep "can't.*nat")" ] && ip6tables -t nat -I dns_redir -m set --match-set bypass_lan_mac src -j RETURN
		#iptables -t mangle -I $name -m mac --mac-source $mac -j RETURN
		#iptables -t nat -I dns_redir -m mac --mac-source $mac -j RETURN
		#ip6tables -t mangle -I $name -m mac --mac-source $mac -j RETURN
		#[ -z "$(ip6tables -t nat -nL 2>&1 |grep "can't.*nat")" ] && ip6tables -t nat -I dns_redir -m mac --mac-source $mac -j RETURN
	fi
fi
}

onlyallow_lan_ip () {
[ ! -f $dirconf/onlyallowlan.txt ] && > $dirconf/onlyallowlan.txt
echo -e \\n"\e[1;37m--------------------\\n    【白名单】\\n只允许通过代理的来源局域网IP/MAC列表\\n$dirconf/onlyallowlan.txt\\n--------------------\e[0m"
if [ -s $dirconf/onlyallowlan.txt ] ; then
cat $dirconf/onlyallowlan.txt | awk '{print "\e[1;33m第"NR"行\e[0m " "\e[1;36m" $0 "\e[0m"}'
else
echo "     （空）"
fi
echo -e "\e[1;37m--------------------\e[0m"
echo -e \\n"\e[1;37m↓输入IP地址或MAC地址↓\e[0m"
echo -e "* 输入0将重置列表，输入d将删除列表某一行，输入1将使用vi编辑文件"\\n
read -p "请输入：" lanip
if [ "$lanip" = "0" ] ; then
	> $dirconf/onlyallowlan.txt
	echo -e \\n"\e[1;37m已重置IP/MAC列表onlyallowlan.txt。\e[0m"\\n
elif [ "$lanip" = "1" ] ; then
	vi $dirconf/onlyallowlan.txt
elif [ "$lanip" = "d" -o "$lanip" = "D" ] ; then
	echo -e \\n"\e[1;37m--------------------\e[0m"
	cat $dirconf/onlyallowlan.txt | awk '{print "\e[1;33m第"NR"行\e[0m " "\e[1;36m" $0 "\e[0m"}'
	echo -e "\e[1;37m--------------------\e[0m"\\n
	read -p "请输入要删除的行号：" num
	if [ ! -z "$(echo $num|grep -E '^[0-9]+$')" ] ; then
		sed -i "${num}d" $dirconf/onlyallowlan.txt
		echo -e \\n"\e[1;37m已删除onlyallowlan.txt第${num}行。\e[0m"\\n
	else
		echo -e \\n"\e[1;37m✖输入非数字，取消删除行。\e[0m"\\n
	fi
else
	echo "$lanip" | grep -v '^ *$' >> $dirconf/onlyallowlan.txt
	[ ! -z "$(sed -n '/^ *$/=' $dirconf/onlyallowlan.txt)" ] && echo "删除空行" && sed -i '/^ *$/d' $dirconf/onlyallowlan.txt
fi
}
onlyallowlan () {
#白名单，仅局域网IP通过
if [ -s $dirconf/onlyallowlan.txt ] ; then
	logger -t "【${bashname}】" "▶[白名单]添加iptables/ip6tables只允许来源局域网IP/MAC通过代理与劫持DNS.." && echo -e \\n"\e[1;36m▶[白名单]添加iptables/ip6tables只允许来源局域网IP/MAC通过代理与劫持DNS..\e[0m"
	#IP地址
	iplist=$(cat $dirconf/onlyallowlan.txt | grep -Ev '^#|^ *$' | grep -Eo '([0-9]+\.){3}[0-9]+.*')
	if [ ! -z "$iplist" ] ; then
		[ ! -z "$(ipset list | grep onlyallow_lan_ip)" ] && ipset -X onlyallow_lan_ip
		ipset -N onlyallow_lan_ip hash:net
		IFS=$'\n'
		for ip in $iplist
		do
			echo "  ✚ [onlyallowlan] 仅代理来源局域网IP：$ip"
			ipset add onlyallow_lan_ip $ip
		done
		iptables -t mangle -I $name -m set ! --match-set onlyallow_lan_ip src -j RETURN
		iptables -t nat -I dns_redir -m set ! --match-set onlyallow_lan_ip src -j RETURN
	fi
	#MAC地址
	maclist=$(cat $dirconf/onlyallowlan.txt | grep -Ev '^#|^ *$' | grep -Eo '([0-9a-fA-F]{2})(([\s:/-][0-9a-fA-F]{2}){5})')
	if [ ! -z "$maclist" ] ; then
		[ ! -z "$(ipset list | grep onlyallow_lan_mac)" ] && ipset -X onlyallow_lan_mac
		ipset -N onlyallow_lan_mac hash:mac
		IFS=$'\n'
		for mac in $maclist
		do
			echo "  ✚ [onlyallowlan] 仅代理来源局域网MAC：$mac"
			ipset add onlyallow_lan_mac $mac
		done
		iptables -t mangle -I $name -m set ! --match-set onlyallow_lan_mac src -j RETURN
		iptables -t nat -I dns_redir -m set ! --match-set onlyallow_lan_mac src -j RETURN
		ip6tables -t mangle -I $name -m set ! --match-set onlyallow_lan_mac src -j RETURN
		[ -z "$(ip6tables -t nat -nL 2>&1 |grep "can't.*nat")" ] && ip6tables -t nat -I dns_redir -m set ! --match-set onlyallow_lan_mac src -j RETURN
		#iptables -t mangle -A $name -p tcp -m mac --mac-source $mac -j TPROXY --on-ip 127.0.0.1 --on-port "$tproxy_port" --tproxy-mark 1
		#iptables -t mangle -A $name -p udp -m mac --mac-source $mac -j TPROXY --on-ip 127.0.0.1 --on-port "$tproxy_port" --tproxy-mark 1
		#ip6tables -t mangle -A $name -p udp -m mac --mac-source $mac -j TPROXY --on-port "$tproxy_port" --tproxy-mark 1
		#ip6tables -t mangle -A $name -p tcp -m mac --mac-source $mac -j TPROXY --on-port "$tproxy_port" --tproxy-mark 1
		#iptables -t nat -A dns_redir -p udp --dport 53 -m mac --mac-source $mac -j REDIRECT --to-ports "$dns_port"
		#[ -z "$(ip6tables -t nat -nL 2>&1 |grep "can't.*nat")" ] && ip6tables -t nat -A dns_redir -p udp --dport 53 -m mac --mac-source $mac -j REDIRECT --to-ports "$dns_port"
	fi
fi
}

force_ip () {
[ ! -f $dirconf/forceip.txt ] && > $dirconf/forceip.txt
echo -e \\n"\e[1;37m--------------------\\n    【forceip】\\n强制走代理的目标ipv4 IP列表\\n$dirconf/forceip.txt\\n--------------------\e[0m"
if [ -s $dirconf/forceip.txt ] ; then
cat $dirconf/forceip.txt | awk '{print "\e[1;33m第"NR"行\e[0m " "\e[1;36m" $0 "\e[0m"}'
else
echo "     （空）"
fi
echo -e "\e[1;37m--------------------\e[0m"
echo -e \\n"\e[1;37m↓输入ipv4 IP地址↓\e[0m"
echo -e "* 不可输入本机使用的IP网段，否则将导致回环！"
echo -e "* 输入0将重置列表，输入d将删除列表某一行，输入1将使用vi编辑文件"\\n
read -p "请输入：" forceip
if [ "$forceip" = "0" ] ; then
	> $dirconf/forceip.txt
	echo -e \\n"\e[1;37m已重置ipv4 IP列表forceip.txt。\e[0m"\\n
elif [ "$forceip" = "1" ] ; then
	vi $dirconf/forceip.txt
elif [ "$forceip" = "d" -o "$forceip" = "D" ] ; then
	echo -e \\n"\e[1;37m--------------------\e[0m"
	cat $dirconf/forceip.txt | awk '{print "\e[1;33m第"NR"行\e[0m " "\e[1;36m" $0 "\e[0m"}'
	echo -e "\e[1;37m--------------------\e[0m"\\n
	read -p "请输入要删除的行号：" num
	if [ ! -z "$(echo $num|grep -E '^[0-9]+$')" ] ; then
		sed -i "${num}d" $dirconf/forceip.txt
		echo -e \\n"\e[1;37m已删除forceip.txt第${num}行。\e[0m"\\n
	else
		echo -e \\n"\e[1;37m✖输入非数字，取消删除行。\e[0m"\\n
	fi
else
	echo "$forceip" | grep -v '^ *$' >> $dirconf/forceip.txt
	[ ! -z "$(sed -n '/^ *$/=' $dirconf/forceip.txt)" ] && echo "删除空行" && sed -i '/^ *$/d' $dirconf/forceip.txt
fi
}
forceip () {
#强制走代理ipv4 IP列表
if [ -s $dirconf/forceip.txt ] ; then
	logger -t "【${bashname}】" "▶[forceip]强制目标IP列表走代理.." && echo -e \\n"\e[1;36m▶[forceip]强制目标IP列表走代理..\e[0m"
	#IP地址
	iplist=$(cat $dirconf/forceip.txt | grep -Ev '^#|^ *$' | grep -Eo '([0-9]+\.){3}[0-9]+.*')
	if [ ! -z "$iplist" ] ; then
		[ ! -z "$(iptables -t mangle -L | grep ${name}_mask)" ] && [ ! -z "$(iptables -t mangle -L ${name}_mask | grep "match-set forceip")" ] && iptables -t mangle -F ${name}_mask
		[ ! -z "$(ipset list | grep forceip)" ] && ipset -X forceip
		ipset -N forceip hash:net
		IFS=$'\n'
		for ip in $iplist
		do
			echo "  ✚ [forceip] 强制走代理目标IP：$ip"
			ipset add forceip $ip
		done
		iptables -t mangle -I $name -p tcp -m set --match-set forceip dst -j TPROXY --on-ip 127.0.0.1 --on-port "$tproxy_port" --tproxy-mark 1
		iptables -t mangle -I $name -p udp -m set --match-set forceip dst -j TPROXY --on-ip 127.0.0.1 --on-port "$tproxy_port" --tproxy-mark 1
		if [ "$mode" = "2" ] ; then
			iptables -t mangle -I ${name}_mask -p tcp -m set --match-set forceip dst -j MARK --set-mark 1
			iptables -t mangle -I ${name}_mask -p udp -m set --match-set forceip dst -j MARK --set-mark 1
		fi
	fi
fi
}

ipset_cnip_1 () {
[ ! -s ./ipset.cnip.txt ] && down_ipset_cnip
if [ -s ./ipset.cnip.txt ] ; then
	echo "▶添加ipset IP集合cnip"
	ipset restore -f ipset.cnip.txt
	ipset_cnip_ok=1
else
	logger -t "【${bashname}】" "✖ ipset.cnip.txt文件为空，无法创建ipv4 cn IP ipset表。跳过。" && echo -e \\n"\e[1;31m✖ ipset.cnip.txt文件为空，无法创建ipv4 cn IP ipset表。跳过。\e[0m"
	ipset_cnip_ok=0
fi
}
ipset_cnip_0 () {
[ ! -z "$(ipset list | grep cnip$)" ] && echo "▷删除ipset IP集合cnip" && ipset destroy cnip
}
ipset_cnipv6_1 () {
[ ! -s ./ipset.cnipv6.txt ] && down_ipset_cnipv6
if [ -s ./ipset.cnipv6.txt ] ; then
	echo "▶添加ipset IP集合cnipv6"
	ipset restore -f ipset.cnipv6.txt
	ipset_cnipv6_ok=1
else
	logger -t "【${bashname}】" "✖ ipset.cnipv6.txt文件为空，无法创建ipv6 cn IP ipset表。跳过。" && echo -e \\n"\e[1;31m✖ ipset.cnipv6.txt文件为空，无法创建ipv6 cn IP ipset表。跳过。\e[0m"
	ipset_cnipv6_ok=0
fi
}
ipset_cnipv6_0 () {
[ ! -z "$(ipset list | grep cnipv6$)" ] && echo "▷删除ipset IP集合cnipv6" && ipset destroy cnipv6
}

ip_4_rule_route_1 () {
echo "▶添加ip rule路由策略table 100，将标记为1的流量走表100"
ip rule add fwmark 1 table 100
echo "▶添加ip route路由表table 100，将本机流量0.0.0.0/0走表100"
ip route add local 0.0.0.0/0 dev lo table 100
}
ip_4_rule_route_0 () {
while true ; do if [ ! -z "$(ip rule list | grep 'lookup 100')" ] ; then echo "▷删除ip rule路由策略table 100" && ip rule del fwmark 1 table 100 ; else break ; fi ; done
while true ; do if [ ! -z "$(ip route list table 100)" ] ; then echo "▷删除ip route路由表table 100" && ip route del local default dev lo table 100 ; else break ; fi ; done
}
ip_6_rule_route_1 () {
echo "▶添加ip -6 rule路由策略table 100，将标记为1的流量走表100"
ip -6 rule add fwmark 1 table 100
[ "$?" = "0" ] && ipv6_support=1 || ipv6_support=0
echo "▶添加ip -6 route路由表table 100，将本机流量::/0走表100"
ip -6 route add local ::/0 dev lo table 100
}
ip_6_rule_route_0 () {
while true ; do if [ ! -z "$(ip -6 rule list | grep 'lookup 100')" ] ; then echo "▷删除ip -6 rule路由策略table 100" && ip -6 rule del fwmark 1 table 100 ; else break ; fi ; done
while true ; do if [ ! -z "$(ip -6 route list table 100)" ] ; then echo "▷删除ip -6 route路由表table 100" && ip -6 route del local default dev lo table 100 ; else break ; fi ; done
}

# iptables tproxy setting： https://xtls.github.io/document/level-2/iptables_gid.html
tproxy4 () {
ip_4_rule_route_0
echo -e \\n"\e[1;36m▶[pre41]创建局域网ipv4透明代理\e[0m"
ip_4_rule_route_1
[ -z "$(iptables -t mangle -nL | grep -i "chain ${name} ")" ] && iptables -t mangle -N $name
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
iptables -t mangle -A $name -m mark --mark $gid -j RETURN
local_ip=$(ip addr | grep -w inet | awk '{print $2}' | sed 's@\.[0-9]*/@\.0/@g' | sort -u) && [ ! -z "$local_ip" ] && for a in $local_ip ; do [ -z "$(iptables -t mangle -nL $name | grep -Ei "RETURN.*$a")" ] && echo ">> ipv4 $name：RETURN local ip $a" && iptables -t mangle -A $name -d $a -j RETURN ; done
iptables -t mangle -A $name -p tcp -j TPROXY --on-ip 127.0.0.1 --on-port "$tproxy_port" --tproxy-mark 1
iptables -t mangle -A $name -p udp -j TPROXY --on-ip 127.0.0.1 --on-port "$tproxy_port" --tproxy-mark 1
iptables -t mangle -A PREROUTING -j $name
}
tproxy4_out () {
echo -e "\e[1;36m▶[out41]创建本机ipv4透明代理\e[0m"
[ -z "$(iptables -t mangle -nL | grep -i "chain ${name}_mask ")" ] && iptables -t mangle -N ${name}_mask
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
#iptables -t mangle -A ${name}_mask -m mark --mark $gid -j RETURN
[ -s ${path}/RETURN_UID_GID.TXT ] && for uidgid in $(cat ${path}/RETURN_UID_GID.TXT | sort -u) ; do n=$(echo $uidgid | awk -F ',' '{print $1}') && g=$(echo $uidgid | awk -F ',' '{print $3}') && echo ">> ipv4 ${name}_mask：RETURN $n gid [$g]" && iptables -t mangle -I ${name}_mask -m owner --gid-owner $g -j RETURN ; done
local_ip=$(ip addr | grep -w inet | awk '{print $2}' | sed 's@\.[0-9]*/@\.0/@g' | sort -u) && [ ! -z "$local_ip" ] && for a in $local_ip ; do [ -z "$(iptables -t mangle -nL ${name}_mask | grep -Ei "RETURN.*$a")" ] && echo ">> ipv4 ${name}_mask：RETURN local ip $a" && iptables -t mangle -A ${name}_mask -d $a -j RETURN ; done
iptables -t mangle -A ${name}_mask -p tcp -j MARK --set-mark 1
iptables -t mangle -A ${name}_mask -p udp -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -m owner ! --gid-owner $gid -j ${name}_mask
}

tproxy6 () {
ip_6_rule_route_0
echo -e "\e[1;36m▶[pre61]创建局域网ipv6透明代理\e[0m"
ip_6_rule_route_1
[ -z "$(ip6tables -t mangle -nL | grep -i "chain ${name} ")" ] && ip6tables -t mangle -N $name
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
ip6tables -t mangle -A $name -d fe80::/10 -j RETURN
ip6tables -t mangle -A $name -d fc00::/7 -j RETURN
ip6tables -t mangle -A $name -d fd00::/8 -j RETURN
ip6tables -t mangle -A $name -d ff00::/8 -j RETURN
ip6tables -t mangle -A $name -m mark --mark $gid -j RETURN
[ "$ipv6_support" = "0" ] && echo ">> $name：由于ipv6的ip -6 rule规则添加错误，添加绕过来源地址为本机::1/128的访问。" && ip6tables -t mangle -A $name -s ::1/128 -j RETURN
local_ip=$(ip addr | grep -w inet6 | grep -Ev ' fe80| fc| fd| ff| ::1/128|qdisc' | awk '{print $2}' | sed 's/:/::/4;s/::.*\//::\//' | sort -u) && [ ! -z "$local_ip" ] && for a in $local_ip ; do [ -z "$(ip6tables -t mangle -nL $name | grep -Ei "RETURN.*$a")" ] && echo ">> ipv6 $name：RETURN local ip $a" && ip6tables -t mangle -A $name -d $a -j RETURN ; done
ip6tables -t mangle -A $name -p udp -j TPROXY --on-port "$tproxy_port" --tproxy-mark 1
ip6tables -t mangle -A $name -p tcp -j TPROXY --on-port "$tproxy_port" --tproxy-mark 1
ip6tables -t mangle -A PREROUTING -j $name
}
tproxy6_out () {
echo -e "\e[1;36m▶[out61]创建本机ipv6透明代理\e[0m"
[ -z "$(ip6tables -t mangle -nL | grep -i "chain ${name}_mask ")" ] && ip6tables -t mangle -N ${name}_mask
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
ip6tables -t mangle -A ${name}_mask -d fe80::/10 -j RETURN
ip6tables -t mangle -A ${name}_mask -d fc00::/7 -j RETURN
ip6tables -t mangle -A ${name}_mask -d fd00::/8 -j RETURN
ip6tables -t mangle -A ${name}_mask -d ff00::/8 -j RETURN
#ip6tables -t mangle -A ${name}_mask -m mark --mark $gid -j RETURN
[ "$ipv6_support" = "0" ] && echo ">> ${name}_mask：添加绕过来源地址为本机::1/128的访问。" && ip6tables -t mangle -A ${name}_mask -s ::1/128 -j RETURN
[ -s ${path}/RETURN_UID_GID.TXT ] && for uidgid in $(cat ${path}/RETURN_UID_GID.TXT | sort -u) ; do n=$(echo $uidgid | awk -F ',' '{print $1}') && g=$(echo $uidgid | awk -F ',' '{print $3}') && echo ">> ipv6 ${name}_mask：RETURN $n gid [$g]" && ip6tables -t mangle -I ${name}_mask -m owner --gid-owner $g -j RETURN ; done
local_ip=$(ip addr | grep -w inet6 | grep -Ev ' fe80| fc| fd| ff| ::1/128|qdisc' | awk '{print $2}' | sed 's/:/::/4;s/::.*\//::\//' | sort -u) && [ ! -z "$local_ip" ] && for a in $local_ip ; do [ -z "$(ip6tables -t mangle -nL ${name}_mask | grep -Ei "RETURN.*$a")" ] && echo ">> ipv6 ${name}_mask：RETURN local ip $a" && ip6tables -t mangle -A ${name}_mask -d $a -j RETURN ; done
ip6tables -t mangle -A ${name}_mask -p tcp -j MARK --set-mark 1
ip6tables -t mangle -A ${name}_mask -p udp -j MARK --set-mark 1
ip6tables -t mangle -A OUTPUT -m owner ! --gid-owner $gid -j ${name}_mask
}

redirect_dns () {
echo -e "\e[1;36m▶[pre42]劫持局域网ipv4 DNS 53请求到本机端口$dns_port\e[0m"
[ -z "$(iptables -t nat -nL | grep -i "chain dns_redir ")" ] && iptables -t nat -N dns_redir
iptables -t nat -F dns_redir
iptables -t nat -A dns_redir -p udp --dport 53 -j REDIRECT --to-ports "$dns_port"
iptables -t nat -A dns_redir -p tcp --dport 53 -j REDIRECT --to-ports "$dns_port"
iptables -t nat -I PREROUTING -p udp --dport 53 -j dns_redir
if [ "$mode" = "2" ] ; then
echo -e "\e[1;36m▶[out42]劫持本机ipv4 DNS 53请求到本机端口$dns_port\e[0m"
[ -z "$(iptables -t nat -nL | grep -i "chain dns_redir_mask ")" ] && iptables -t nat -N dns_redir_mask
iptables -t nat -F dns_redir_mask
[ -s ${path}/RETURN_UID_GID.TXT ] && for uidgid in $(cat ${path}/RETURN_UID_GID.TXT | sort -u) ; do n=$(echo $uidgid | awk -F ',' '{print $1}') && g=$(echo $uidgid | awk -F ',' '{print $3}') && echo ">> ipv4 dns_redir_mask：RETURN $n gid [$g]" && iptables -t nat -I dns_redir_mask -m owner --gid-owner $g -j RETURN ; done
iptables -t nat -A dns_redir_mask -p udp --dport 53 -j REDIRECT --to-ports "$dns_port"
iptables -t nat -A dns_redir_mask -p tcp --dport 53 -j REDIRECT --to-ports "$dns_port"
iptables -t nat -I OUTPUT -p udp --dport 53 -j dns_redir_mask
iptables -t nat -I OUTPUT -p tcp --dport 53 -j dns_redir_mask
#iptables -t nat -I OUTPUT -m owner ! --gid-owner $gid -p udp --dport 53 -j dns_redir
fi
if [ -z "$(ip6tables -t nat -nL 2>&1 | grep "can't.*nat")" ] ; then
echo -e "\e[1;36m▶[pre62]劫持局域网ipv6 DNS 53请求到本机端口$dns_port\e[0m"
[ -z "$(ip6tables -t nat -nL | grep -i "chain dns_redir ")" ] && ip6tables -t nat -N dns_redir
ip6tables -t nat -F dns_redir
ip6tables -t nat -A dns_redir -p udp --dport 53 -j REDIRECT --to-ports "$dns_port"
ip6tables -t nat -A dns_redir -p tcp --dport 53 -j REDIRECT --to-ports "$dns_port"
ip6tables -t nat -I PREROUTING -p udp --dport 53 -j dns_redir
if [ "$mode" = "2" ] ; then
echo -e "\e[1;36m▶[out62]劫持本机ipv6 DNS 53请求到本机端口$dns_port\e[0m"
[ -z "$(ip6tables -t nat -nL | grep -i "chain dns_redir_mask ")" ] && ip6tables -t nat -N dns_redir_mask
ip6tables -t nat -F dns_redir_mask
[ -s ${path}/RETURN_UID_GID.TXT ] && for uidgid in $(cat ${path}/RETURN_UID_GID.TXT | sort -u) ; do n=$(echo $uidgid | awk -F ',' '{print $1}') && g=$(echo $uidgid | awk -F ',' '{print $3}') && echo ">> ipv6 dns_redir_mask：RETURN $n gid [$g]" && ip6tables -t nat -I dns_redir_mask -m owner --gid-owner $g -j RETURN ; done
ip6tables -t nat -A dns_redir_mask -p udp --dport 53 -j REDIRECT --to-ports "$dns_port"
ip6tables -t nat -A dns_redir_mask -p tcp --dport 53 -j REDIRECT --to-ports "$dns_port"
ip6tables -t nat -I OUTPUT -p udp --dport 53 -j dns_redir_mask
ip6tables -t nat -I OUTPUT -p tcp --dport 53 -j dns_redir_mask
#ip6tables -t nat -I OUTPUT -m owner ! --gid-owner $gid -p udp --dport 53 -j dns_redir
fi
else
echo -e "\e[1;36m▶ipv6 DNS：ip6tables不支持nat，直接丢弃/屏蔽所有ipv6 DNS 53请求\e[0m"
#ip6tables -t mangle -I $name -p udp --dport 53 -j DROP
[ -z "$(ip6tables -vnL INPUT --line-numbers | grep -Ei " *dpt:53 *reject")" ] && ip6tables -I INPUT -p udp --dport 53 -j REJECT
fi
#####
#iptables -t nat -I PREROUTING -p udp --dport 53 -j DNAT --to-destination "127.0.0.1:$dns_port"
#iptables -t nat -I OUTPUT -m owner ! --gid-owner $gid -p udp --dport 53 -j DNAT --to-destination "127.0.0.1:$dns_port"
#iptables -t mangle -I OUTPUT -m owner ! --gid-owner $gid -p udp --dport 53 -j MARK --set-mark 1
#iptables -t mangle -I OUTPUT -p udp --dport 53 -j MARK --set-mark 1
#iptables -t mangle -I PREROUTING -p udp --dport 53 -j TPROXY --on-port "$dns_tproxy" --tproxy-mark 1
#ip6tables -t mangle -I OUTPUT -m owner ! --gid-owner $gid -p udp --dport 53 -j MARK --set-mark 1
#ip6tables -t mangle -I PREROUTING -p udp --dport 53 -j TPROXY --on-port "$dns_tproxy" --tproxy-mark 1
}


#透明代理
ipt1 () {
#检查是否缺少tproxy模块modprobe
if [ -z "$(lsmod | grep xt_TPROXY)" ] ; then
	if [ ! -z "$(find /lib/modules/$(uname -r) | grep xt_TPROXY.ko)" ] ; then
		echo "▶加載內核模塊 xt_TPROXY"
		modprobe xt_TPROXY
	else
		echo -e \\n"\e[1;31m✖ ${name} 当前Linux系统缺少内核模塊xt_TPROXY.ko，无法使用tproxy透明代理，结束脚本。\e[0m"
		exit
	fi
fi
##########
logger -t "【${bashname}】" "▶创建局域网透明代理"
#[ -z "$(ipset list | grep localipv4)" ] && ipset_local_ipv4
#[ -z "$(ipset list | grep localipv6)" ] && ipset_local_ipv6
##tproxy tcp+udp
tproxy4
tproxy6
##redir dns
redirect_dns
##OUTPUT
if [ "$mode" = "2" ] ; then
logger -t "【${bashname}】" "▶创建路由自身走透明代理"
tproxy4_out
tproxy6_out
fi
#判断是否绕过cn IP
if [ "$bypasscnip" = "1" ] ; then
	#ipv4
	ipset_cnip_0
	ipset_cnip_1
	if [ "$ipset_cnip_ok" = "1" ] ; then
		logger -t "【${bashname}】" "▶[bypasscnip] 绕过cn IP ipset模式：cn ipv4 IP不走$name" && echo -e "\e[1;36m▶[bypasscnip] 绕过cn IP ipset模式：cn ipv4 IP不走$name\e[0m"
		iptables -t mangle -I $name -m set --match-set cnip dst -j RETURN
	fi
	#ipv6
	ipset_cnipv6_0
	ipset_cnipv6_1
	if [ "$ipset_cnipv6_ok" = "1" ] ; then
		if [ ! -z "$(ip6tables -t mangle -vnL $name 1 --line-numbers | grep -Ei "DROP.*udp *dpt:53 *")" ] ; then
			logger -t "【${bashname}】" "▶[bypasscnip] 绕过cn IP ipset模式：cn ipv6 IP不走$name >2" && echo -e "\e[1;36m▶[bypasscnip] 绕过cn IP ipset模式：cn ipv6 IP不走$name >2\e[0m"\\n
			ip6tables -t mangle -I $name 2 -m set --match-set cnipv6 dst -j RETURN
		else
			logger -t "【${bashname}】" "▶[bypasscnip] 绕过cn IP ipset模式：cn ipv6 IP不走$name" && echo -e "\e[1;36m▶[bypasscnip] 绕过cn IP ipset模式：cn ipv6 IP不走$name\e[0m"\\n
			ip6tables -t mangle -I $name -m set --match-set cnipv6 dst -j RETURN
		fi
	fi
fi
#强制走代理目标IP列表
forceip
#判断是否仅代理来源局域网IP
onlyallowlan
#判断是否绕过来源局域网ip
bypasslan
##fake-dns
if [ "$dns" = "2" ] ; then
logger -t "【${bashname}】" "▶透明代理DNS模式：fake-dns" && echo -e \\n"\e[1;36m▶透明代理DNS模式：fake-dns\e[0m"\\n
fi
}

ipt0 () {
echo -e \\n"\e[1;36m▷清空透明代理iptables规则\e[0m"\\n && logger -t "【${bashname}】" "▷清空透明代理iptables规则"
ip_4_rule_route_0
ip_6_rule_route_0
iptables -t mangle -F OUTPUT
iptables -t mangle -F PREROUTING
ip6tables -t mangle -F OUTPUT
ip6tables -t mangle -F PREROUTING
iptables -t nat -F OUTPUT
#iptables -t nat -F PREROUTING
[ ! -z "$(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei " *dpt:53 *")" ] && IFS=$'\n' && for m in $(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei " *dpt:53 *" | awk '{print $1}' | sed '1!G;h;$!d' ) ; do iptables -t nat -D PREROUTING $m ;done
[ ! -z "$(ip6tables -vnL INPUT --line-numbers | grep -Ei " *dpt:53 *reject")" ] && IFS=$'\n' && for m in $(ip6tables -vnL INPUT --line-numbers | grep -Ei " *dpt:53 *reject" | awk '{print $1}' | sed '1!G;h;$!d' ) ; do ip6tables -D INPUT $m ;done
if [ -z "$(ip6tables -t nat -nL 2>&1 |grep "can't.*nat")" ] ; then
ip6tables -t nat -F OUTPUT
ip6tables -t nat -F PREROUTING
fi
}

stop_iptables () {
ipt0
}

start_iptables () {
#ipv4 局域网
pre41=$(iptables -t mangle -vnL PREROUTING --line-numbers | grep -i $name | wc -l)
#ipv4 局域网DNS
pre42=$(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp *dpt:53 *" | wc -l)
#ipv6 局域网
pre61=$(ip6tables -t mangle -vnL PREROUTING --line-numbers | grep -i $name | wc -l)
#ipv6 局域网DNS
pre62=$(ip6tables -t nat -vnL PREROUTING --line-numbers 2>&1 | grep -Ei "udp *dpt:53 *" | wc -l)
#ipv4 本机
out41=$(iptables -t mangle -vnL OUTPUT --line-numbers | grep -i $name | wc -l)
#ipv4 本机DNS
out42=$(iptables -t nat -vnL OUTPUT --line-numbers | grep -Ei "udp *dpt:53 *" | wc -l)
#ipv6 本机
out61=$(ip6tables -t mangle -vnL OUTPUT --line-numbers | grep -i $name | wc -l)
#ipv6 本机DNS
out62=$(ip6tables -t nat -vnL OUTPUT --line-numbers 2>&1 | grep -Ei "udp *dpt:53 *" | wc -l)
#ipv4 规则表
iprule4=$(ip rule list | grep 'lookup 100' | wc -l)
#ipv6 规则表
iprule6=$(ip -6 rule list | grep 'lookup 100' | wc -l)
#ipv4 路由表
iproute4=$(ip route list table 100 | wc -l)
#ipv6 路由表
iproute6=$(ip -6 route list table 100 | wc -l)
tproxy_status="${pre41}${pre42}${pre61}${pre62}${out41}${out42}${out61}${out62}${iprule4}${iprule6}${iproute4}${iproute6}"
if [ "$tproxy_status" = "111000001111" -o "$tproxy_status" = "111100001111" ] ; then
	iptables_mode=1
elif [ "$tproxy_status" = "111011101111" -o "$tproxy_status" = "111011111111" -o "$tproxy_status" = "111111101111" -o "$tproxy_status" = "111111111111" ] ; then
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
	[ "$tproxy_status" != "000000000000" ] && ipt0
	if [ ! -z "$(pss)" ] ; then
		if [ "$(port | grep $tproxy_port | wc -l)" = "2" ] ; then
			ipt1
			work_ok=1
			[ -f ./start_iptables_ok_* ] && rm ./start_iptables_ok_*
			> ./start_iptables_ok_1
		else
			echo "    ✖ start_iptables：${name}进程已启动，但无tproxy端口监听。跳过设置透明代理。"
			work_ok=0
			[ -f ./start_iptables_ok_* ] && rm ./start_iptables_ok_*
			> ./start_iptables_ok_0_tproxy_port_listen_error
		fi
	else
		echo "    ✖ start_iptables：${name}进程未启动，跳过设置透明代理。"
		work_ok=0
		[ -f ./start_iptables_ok_* ] && rm ./start_iptables_ok_*
		> ./start_iptables_ok_0
	fi
fi
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
	if [ "$wan" = "1" ] ; then
		echo -e \\n"\e[1;36m▶创建开机自启任务1...\e[0m" && echo "sh ${path}/${bashname} restart > $tmp/${bashname}_start_wan1.txt 2>&1 &" >> ${path}/START_WAN.SH
	elif [ "$wan" = "2" ] ; then
		echo -e \\n"\e[1;36m▶创建开机自启任务2...\e[0m" && echo "sh ${path}/${bashname} $mode > $tmp/${bashname}_start_wan2.txt 2>&1 &" >> ${path}/START_WAN.SH
	fi
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
	if [ "$cron" = "1" ] ; then
		echo -e \\n"\e[1;36m▶创建定时任务crontab1...\e[0m" && echo "sleep 60 && sh ${path}/${bashname} restart > $tmp/${bashname}_start_cron1.txt 2>&1 &" >> ${path}/START_CRON.SH
	elif [ "$cron" = "2" ] ; then
		echo -e \\n"\e[1;36m▶创建定时任务crontab2...\e[0m" && echo "sleep 60 && sh ${path}/${bashname} $mode > $tmp/${bashname}_start_cron2.txt 2>&1 &" >> ${path}/START_CRON.SH
	fi
fi
}

restart () {
#检查进程端口
if [ "$(pss | wc -l)" != "1" -o "$(psskeep | wc -l)" != "1" ] ; then
	sh ${path}/${bashname} $mode &
else
	echo -e \\n"$(timenow) ✓ restart：${name}进程与${name}_keep.sh进程守护已运行，无需重启。"\\n
fi
#检查iptables
[ "$mode" = "1" -o "$mode" = "2" ] && start_iptables
}

#进程守护
start_keep () {
if [ ! -s ./${name}_keep.sh ] ; then
echo "▶生成进程守护脚本."
cat > ./${name}_keep.sh << EOF
#!/bin/sh
path=$path
bashname=$bashname
name=$name
dirtmp=$dirtmp
dirconf=$dirconf
run="$run"
alias pss='$pss'
alias pid='$pid'
alias port='$port'
alias psskeep='$psskeep'
alias timenow='$timenow'
##
mode=\$(cat \$dirconf/settings.txt |awk -F 'mode=' '/^mode=/{print \$2}' |head -n 1)
mark=\$(cat \$dirconf/settings.txt |awk -F 'mark=' '/^mark=/{print \$2}' |head -n 1)
log1=1
net=1
skip=1
t=1
m=1
v=1
cd \$dirtmp
while true ; do
#log1：日志文件大于1万条后删除1000条
[ -s ./keep.txt ] && keep_line=\$(sed -n '\$=' ./keep.txt) && [ "\$keep_line" -ge "10000" ] && echo -e \\\n"❴d:\$log1❵ \$keep_line—1000_[\$(timenow)]"\\\n >> ./keep.txt && sed -i '1,1000d' ./keep.txt && sed -i "1i\\【status】❴d:\${log1}❵ \${keep_line}—1000_[\$(timenow)]\\\n" ./keep.txt && log1=\$((log1+1))
#net：检查网络
if [ -f need_check_network_1 ] ; then
	ping -nq -c1 -W1 223.5.5.5 >/dev/null 2>&1
	if [ "\$?" != "0" ] ; then
		ping -nq -c1 -W1 119.29.29.29 >/dev/null 2>&1
		if [ "\$?" != "0" ] ; then
			ping -nq -c1 -W1 8.8.4.4 >/dev/null 2>&1
			if [ "\$?" != "0" ] ; then
				echo -e "\$(timenow) \${name} [\$net] ✖ 检测到当前网络不通，休息120秒后重试。" >> ./keep.txt
				net=\$((net+1))
				sleep 120
				continue
			fi
		fi
	fi
	echo -e "\$(timenow) \${name} [\$net] ✔ 检测到当前网络已畅通！" >> ./keep.txt
	net=1
	rm need_check_network_1
fi
#skip：跳过任务
if [ ! -z "\$(ls skip_keep_check_* 2>/dev/null)" ] ; then
	echo -e "\$(timenow) \${name} [\$skip] 🔒keep_lock 检测到存在进程锁文件[ \$(ls skip_keep_check_* 2>/dev/null) ]，跳过本轮进程守护任务。休息120秒后继续。" >> ./keep.txt
	skip=\$((skip+1))
	rm skip_keep_check_*
	sleep 120
	continue
fi
#t：检查tproxy
if [ "\$mode" = "1" -o "\$mode" = "2" ] ; then
	pre41=\$(iptables -t mangle -vnL PREROUTING --line-numbers | grep -i \$name | wc -l)
	pre42=\$(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp *dpt:53 *" | wc -l)
	pre61=\$(ip6tables -t mangle -vnL PREROUTING --line-numbers | grep -i \$name | wc -l)
	pre62=\$(ip6tables -t nat -vnL PREROUTING --line-numbers 2>&1 | grep -Ei "udp *dpt:53 *" | wc -l)
	out41=\$(iptables -t mangle -vnL OUTPUT --line-numbers | grep -i \$name | wc -l)
	out42=\$(iptables -t nat -vnL OUTPUT --line-numbers | grep -Ei "udp *dpt:53 *" | wc -l)
	out61=\$(ip6tables -t mangle -vnL OUTPUT --line-numbers | grep -i \$name | wc -l)
	out62=\$(ip6tables -t nat -vnL OUTPUT --line-numbers 2>&1 | grep -Ei "udp *dpt:53 *" | wc -l)
	iprule4=\$(ip rule list | grep 'lookup 100' | wc -l)
	iprule6=\$(ip -6 rule list | grep 'lookup 100' | wc -l)
	iproute4=\$(ip route list table 100 | wc -l)
	iproute6=\$(ip -6 route list table 100 | wc -l)
	tproxy_status="\${pre41}\${pre42}\${pre61}\${pre62}\${out41}\${out42}\${out61}\${out62}\${iprule4}\${iprule6}\${iproute4}\${iproute6}"
	if [ "\$tproxy_status" = "111000001111" -o "\$tproxy_status" = "111100001111" ] ; then
		iptables_mode=1
	elif [ "\$tproxy_status" = "111011101111" -o "\$tproxy_status" = "111011111111" -o "\$tproxy_status" = "111111101111" -o "\$tproxy_status" = "111111111111" ] ; then
		iptables_mode=2
	else
		iptables_mode=0
	fi
	if [ "\$mode" = "1" -a "\$iptables_mode" != "1" ] ; then
		echo -e "\$(timenow) [\$t]检测\${name}需要重置iptables规则①！" >> ./keep.txt
		echo -e "mode：\$mode ，iptables_mode：\$iptables_mode \\nPRE：\$pre41 \$pre42 \$pre61 \$pre62 ，OUT：\$out41 \$out42 \$out61 \$out62 ，RULE：\$iprule4 \$iprule6 ，ROUTE：\$iproute4 \$iproute6" >> ./keep.txt
		sh \${path}/\${bashname} start_iptables >> ./keep.txt 2>&1 &
		tproxy_ok=0
		t=0
	elif [ "\$mode" = "2" -a "\$iptables_mode" != "2" ] ; then
		echo -e "\$(timenow) [\$t]检测\${name}需要重置iptables规则②！" >> ./keep.txt
		echo -e "mode：\$mode ，iptables_mode：\$iptables_mode \\nPRE：\$pre41 \$pre42 \$pre61 \$pre62 ，OUT：\$out41 \$out42 \$out61 \$out62 ，RULE：\$iprule4 \$iprule6 ，ROUTE：\$iproute4 \$iproute6" >> ./keep.txt
		sh \${path}/\${bashname} start_iptables >> ./keep.txt 2>&1 &
		tproxy_ok=0
		t=0
	else
		#绕过本机公网ipv4
		local_ip4=\$(ip addr | grep -w inet | awk '{print \$2}' | sed 's@\.[0-9]*/@\.0/@g' | sort -u)
		if [ ! -z "\$local_ip4" ] ; then
			for a in \$local_ip4 ; do [ -z "\$(iptables -t mangle -nL \$name | grep -Ei "RETURN.*\$a")" ] && echo -e \\\\n">> ipv4 \$name：RETURN local ip \$a" >> ./keep.txt && insert_num=\$(iptables -t mangle -vnL \$name --line-number | awk '!/match-set.*TPROXY/&&/TPROXY redirect/{print \$1}' | head -n 1) && iptables -t mangle -I \$name \$insert_num -d \$a -j RETURN && tproxy_ok=0 ; done
			[ "\$mode" = "2" ] && for a in \$local_ip4 ; do [ -z "\$(iptables -t mangle -nL \${name}_mask | grep -Ei "RETURN.*\$a")" ] && echo -e \\\\n">> ipv4 \${name}_mask：RETURN local ip \$a" >> ./keep.txt && insert_num=\$(iptables -t mangle -vnL \${name}_mask --line-number | awk '!/match-set.*MARK set/&&/MARK set/{print \$1}' | head -n 1) && iptables -t mangle -I \${name}_mask \$insert_num -d \$a -j RETURN && tproxy_ok=0 ; done
		fi
		#绕过本机公网ipv6
		local_ip6=\$(ip addr | grep -w inet6 | grep -Ev ' fe80| fc| fd| ff| ::1/128|qdisc' | awk '{print \$2}' | sed 's/:/::/4;s/::.*\//::\//' | sort -u)
		if [ ! -z "\$local_ip6" ] ; then
			for a in \$local_ip6 ; do [ -z "\$(ip6tables -t mangle -nL \$name | grep -Ei "RETURN.*\$a")" ] && echo -e \\\\n">> ipv6 \$name：RETURN local ip \$a" >> ./keep.txt && insert_num=\$(ip6tables -t mangle -vnL \$name --line-number | awk '!/match-set.*TPROXY/&&/TPROXY redirect/{print \$1}' | head -n 1) && ip6tables -t mangle -I \$name \$insert_num -d \$a -j RETURN && tproxy_ok=0 ; done
			[ "\$mode" = "2" ] && for a in \$local_ip6 ; do [ -z "\$(ip6tables -t mangle -nL \${name}_mask | grep -Ei "RETURN.*\$a")" ] && echo -e \\\\n">> ipv6 \${name}_mask：RETURN local ip \$a" >> ./keep.txt && insert_num=\$(ip6tables -t mangle -vnL \${name}_mask --line-number | awk '!/match-set.*MARK set/&&/MARK set/{print \$1}' | head -n 1) && ip6tables -t mangle -I \${name}_mask \$insert_num -d \$a -j RETURN && tproxy_ok=0 ; done
		fi
		[ "\$tproxy_ok" = "0" ] && t=0
		tproxy_ok=1
	fi
else
	tproxy_ok=close
fi
#m：检查mark
if [ "\$mark" = "1" ] ; then
	sh \${path}/\${bashname} start_setmark >> ./keep.txt 2>&1 &
	if [ -f ./mark/setmark_ok_0 ] ; then
		mark_ok=0
		m=0
	else
		mark_ok=1
	fi
else
	mark_ok=close
fi
#v：检查进程与端口
pss_status=\$(pss|wc -l)
port_status=\$(port|wc -l)
if [ "\$pss_status" != "1" -o -z "\$port_status" ] ; then
	if [ "\$pss_status" = "0" ] ; then
		echo -e "\$(timenow) [\$v]检测\${name}进程不存在，重启程序！" >> ./keep.txt
	elif [ "\$pss_status" -gt "1" ] ; then
		echo -e "\$(timenow) [\$v]检测\${name}进程重复 x \$pss_status，重启程序！" >> ./keep.txt
	fi
	[ -z "\$port_status" ] && echo -e "\$(timenow) [\$v]检测\${name}端口没监听，重启程序！" >> ./keep.txt
	sh \${path}/\${bashname} restart >> ./keep.txt 2>&1 &
	server_port_ok=0
	v=0
else
	server_port_ok=1
fi
##总结
if [ "\$server_port_ok" = "1" -a "\$tproxy_ok" = "1" -a "\$mark_ok" = "close" ] ; then
	echo -e "\$(timenow) \${name} [\$v] 进程OK，端口OK，[\$t] tproxy OK" >> ./keep.txt
elif [ "\$server_port_ok" = "1" -a "\$tproxy_ok" = "close" -a "\$mark_ok" = "close" ] ; then
	echo -e "\$(timenow) \${name} [\$v] 进程OK，端口OK" >> ./keep.txt
elif [ "\$server_port_ok" = "1" -a "\$tproxy_ok" = "1" -a "\$mark_ok" = "1" ] ; then
	echo -e "\$(timenow) \${name} [\$v] 进程OK，端口OK，[\$t] tproxy OK，[\$m] mark OK" >> ./keep.txt
elif [ "\$server_port_ok" = "1" -a "\$tproxy_ok" = "close" -a "\$mark_ok" = "1" ] ; then
	echo -e "\$(timenow) \${name} [\$v] 进程OK，端口OK，[\$m] mark OK" >> ./keep.txt 
fi
##+1
t=\$((t+1))
m=\$((m+1))
v=\$((v+1))
##休息
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
		logger -t "【${bashname}】" "✔ ${name}已启动！！" && echo -e \\n"\e[1;36m✔ ${name}已启动！！\e[0m"\\n
		#标记程序pid与启动时间
		echo "$(pid),$(date +%s)" > start_work_time.txt
	else
		logger -t "【${bashname}】" "✦ ${name}进程已启动，但没监听端口..." && echo -e \\n"\e[1;36m✦ ${name}进程已启动，但没监听端口...\e[0m"
		[ -s start_work_time.txt ] && > start_work_time.txt
	fi
else
	logger -t "【${bashname}】" "✖ ${name}进程启动失败，端口无监听，请检查网络问题！！" && echo -e \\n"\e[1;31m✖ ${name}进程启动失败，端口无监听，请检查网络问题！！\e[0m"
	> need_check_network_1
	[ -s start_work_time.txt ] && > start_work_time.txt
fi
}

check_work () {
if [ ! -z "$(pid)" -a ! -z "$(port)" ] ; then
	work_ok=1
else
	work_ok=0
fi
}
check_work_all () {
if [ ! -z "$(pid)" -a "$(port | grep $tproxy_port | wc -l)" = "2" ] ; then
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
while true
do
if [ $t -le $time_max ] ; then
	if [ "$work_ok" = "0" ] ; then
		$comm
		t=$((t+1))
		sleep 1
	elif [ "$work_ok" = "1" ] ; then
		echo -e "☑️ \e[1;32m已工作，耗时 \e[1;33m$t\e[1;32m 秒。\e[0m\\n\e[37m[ $comm ] $t/$time_max work_ok = $work_ok \e[0m"
		break
	else
		echo -e "❔ \e[1;31m未知工作状态，耗时 $t 秒。\e[0m\\n\e[37m[ $comm ] $t/$time_max work_ok参数非0或1。\e[0m"
		break
	fi
else
	echo -e "❎ \e[1;31m等待工作已超时 ，耗时 $t 秒。\e[0m\\n\e[37m[ $comm ] $t/$time_max work_ok = $work_ok \e[0m"
	break
fi
done
}

#check_work && waitwork check_work 10


#关闭
stop_program () {
[ ! -z "$(pid)" ] && logger -t "【${bashname}】" "▷关闭${name}..." && echo -e \\n"\e[1;36m▷关闭${name}...\e[0m" && killall ${name}
[ ! -z "$(pss)" ] && logger -t "【${bashname}】" "▷再次关闭${name}..." && echo -e \\n"\e[1;36m▷再次关闭${name}...\e[0m" && pss | awk '{print $1}' | xargs kill -9
}
#启动
start_program () {
logger -t "【${bashname}】" "▶启动${name}主程序..." && echo -e \\n"\e[1;36m▶启动${name}主程序...\e[0m"
[ -f ./${name}_log.txt ] && mv -f ./${name}_log.txt ./old_${name}_log.txt
[ ! -s ./${name}_ver.txt ] && echo "▶查询主程序$name 版本号..." && echo "$(version)" | sed '/^ *$/d' > ./${name}_ver.txt
[ -z "$(grep "$gid$" ${path}/RETURN_UID_GID.TXT 2>/dev/null)" ] && echo "▶add $user_name,$uid,$gid to ${path}/RETURN_UID_GID.TXT" && echo "$user_name,$uid,$gid" >> ${path}/RETURN_UID_GID.TXT
[ -z "$(grep "$user_name" /etc/passwd)" ] && echo "▶添加用戶$user_name，uid为$uid，gid为$gid" && echo "$user_name:x:$uid:$gid:::" >> /etc/passwd
#adduser -u $uid $user_name -D -S -H -s /bin/sh
su $user_name -c "nohup $run > $dirtmp/${name}_log.txt 2>&1 &"
}

get_config_file () {
configfile=config.yaml
if [ -s /tmp/$configfile -o -s $dirconf/$configfile ] ; then
	if [ -s /tmp/$configfile ] ; then
		cp -f /tmp/$configfile ./$configfile
		ver=$(cat ./$configfile | awk -F// '/【/{print $2}')
		logger -t "【${bashname}】" "▶进入测试模式，使用本地配置文件/tmp/$configfile，版本$ver" && echo -e \\n"\e[1;36m▶进入测试模式，使用本地配置文件/tmp/$configfile，版本：\e[0m\e[1;32m$ver\e[0m"
	elif [ -s $dirconf/$configfile ] ; then
		cp -f $dirconf/$configfile ./$configfile
		ver=$(cat ./$configfile | awk -F// '/【/{print $2}')
		logger -t "【${bashname}】" "▶使用闪存配置文件$dirconf/$configfile，版本$ver" && echo -e \\n"\e[36m▶使用本地配置文件$dirconf/$configfile，版本：\e[0m\e[1;32m$ver\e[0m"
	fi
else
	logger -t "【${bashname}】" "▶直接github下载配置文件$configfile" && echo -e \\n"\e[36m▶直接github下载配置文件$configfile \e[0m"
	down_config
fi
}

#關閉
stop_0 () {
[ "$mode" = "1" -o "$mode" = "2" ] && stop_iptables
stop_program
}
#关闭所有
stop_1 () {
stop_0
stop_wan
stop_cron
stop_keep
all_sh=$(ps -w | grep -v grep| grep ${bashname} | wc -l)
[ "$all_sh" -gt "2" ] && echo -e "▷关闭脚本${bashname}重复进程 x $((all_sh-1))" && ps -w | grep -v grep| grep ${bashname} && ps -w | grep -v grep | grep ${bashname} | awk '{print $1}' | xargs kill -9
}

#启动模式0，只启动主程序
start_0 () {
echo -e \\n"$(timenow)"\\n
#关闭所有
stop_0
#下载文件
echo -e \\n"\e[1;36m▶检查与下载${name}资源文件...\e[0m"
get_config_file &
down_program &
#down_mmdb &
down_geoip &
#down_geoip_full &
down_geosite &
#down_geosite_full &
down_web &
down_rule &
if [ "$bypasscnip" = "1" ] ; then
down_ipset_cnip &
down_ipset_cnipv6 &
fi
down_clashfile
wait
#编辑配置文件
if [ "$edit" = "1" ] ; then
echo -e \\n"\e[1;36m▶编辑${name}配置文件config.yaml ...\e[0m"
edit_port
edit_link
edit_chinalist
edit_dns
edit_adblock
fi
#检查是否存在cache文件
check_cache_file
#启动主程序
start_program
#等待50秒
if [ "$mode" = "1" -o "$mode" = "2" ] ; then
	check_work_all && waitwork check_work_all 50
else
	check_work && waitwork check_work 50
fi
#查看状态
status_program
#创建开机自启
start_wan
#创建定时任务
start_cron
#检验tproxy端口是否监听
[ ! -z "$(log_error)" ] && logger -t "【${bashname}】" "✖ 检测到错误日志<TProxy server error>，tproxy端口监听失败，强制结束进程。" && echo -e \\n"\e[1;31m✖ 检测到错误日志<TProxy server error>，tproxy端口监听失败，强制结束进程。\e[0m" && stop_program
#keep进程守护
if [ "$run_restart_keep" = "1" ] ; then
	restart_keep
else
	psskeep_status=$(psskeep | wc -l) && [ "$psskeep_status" -gt "1" ] && echo -e "▷检测到进程守护脚本keep.sh进程重复 x $psskeep_status，重启脚本keep.sh" && echo -e "\\n$(timenow) ▷检测到进程守护脚本keep.sh进程重复 x $psskeep_status，重启脚本keep.sh \\n" >> $dirtmp/keep.txt && stop_keep
	start_keep
fi
}
#启动模式1：iptables透明代理
start_1 () {
[ "$mode" != "1" ] && mode=1 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=$mode" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && stop_wan && stop_cron && run_restart_keep=1
echo "🔒keep_lock" && > skip_keep_check_start_1
start_0
start_iptables && waitwork start_iptables 6 &
[ "$mark" = "1" ] && start_remark && waitwork start_remark 6
wait && [ ! -z "$(ls skip_keep_check_* 2>/dev/null)" ] && echo "🔓keep_unlock" && rm skip_keep_check_*
}
#启动模式2：iptables透明代理+路由自身走代理
start_2 () {
[ "$mode" != "2" ] && mode=2 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=$mode" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && stop_wan && stop_cron && run_restart_keep=1
echo "🔒keep_lock" && > skip_keep_check_start_2
start_0
start_iptables && waitwork start_iptables 6 &
[ "$mark" = "1" ] && start_remark && waitwork start_remark 6
wait && [ ! -z "$(ls skip_keep_check_* 2>/dev/null)" ] && echo "🔓keep_unlock" && rm skip_keep_check_*
}
#启动模式3：不启用iptables透明代理
start_3 () {
[ "$mode" != "3" ] && mode=3 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=$mode" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && stop_wan && stop_cron && run_restart_keep=1
[ ! -z "$(iptables -t mangle -vnL PREROUTING --line-numbers | grep -i $name)" ] && ipt0
echo "🔒keep_lock" && > skip_keep_check_start_3
start_0
wait && [ ! -z "$(ls skip_keep_check_* 2>/dev/null)" ] && echo "🔓keep_unlock" && rm skip_keep_check_*
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

#8更新文件
renew () {
startrenew=1
echo -e \\n"\e[1;33m檢查更新文件：\e[0m"\\n
down_program &
#down_mmdb &
down_geoip &
#down_geoip_full &
down_geosite &
#down_geosite_full &
down_web &
down_rule &
down_config &
if [ "$bypasscnip" = "1" ] ; then
down_ipset_cnip &
down_ipset_cnipv6 &
fi
down_clashfile
wait
echo -e \\n"\e[1;33m...更新完成...\e[0m"\\n
[ -s ./$name ] && echo "$(version)" | sed '/^ *$/d' > ./${name}_ver.txt
exit
}

#9
remove () {
echo -e \\n"▷删除临时文件夹$dirtmp..."
rm -rf $dirtmp
echo -e "▷删除本地文件夹$diretc..."
rm -rf $diretc
echo -e "▷删除配置文件夹$dirconf..."
rm -rf $dirconf
echo -e \\n" \e[1;32m✔$name卸载完成。\e[0m"\\n
stop_1
}
remove_ask () {
echo -e \\n\\n"\e[1;33m⚠️即将卸载全部，确认卸载请按数字\e[1;32m【1】\e[1;33m，按其他任意键则取消卸载。\e[0m"\\n
read -n 1 -p "请输入数字：" num
if [ ! -z "$(echo $num|grep -E '^[0-9]+$')" ] ; then
	if [ "$num" = "1" ] ; then
		remove
	else
		echo -e \\n"\e[1;37m✖输入非1，取消卸载 \e[0m"\\n
	fi
else
	echo -e \\n"\e[1;37m✖输入非数字，取消卸载 \e[0m"\\n
fi
}
remove_force () {
echo -e \\n"\e[1;33m◉ 强制卸载【$name】全部。\e[0m"
remove
}

view_all_logs () {
log_file=${bashname}_start_wan${wan}.txt && [ -s $tmp/$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && cat $tmp/$log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
log_file=${bashname}_start_cron${cron}.txt && [ -s $tmp/$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && cat $tmp/$log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
log_file=keep.txt && [ -s ./$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看最后50行日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && tail -n 50 $log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
log_file=old_${name}_log.txt && [ -s ./$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看最后100行日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && ( [ -z "$(grep -C 5 panic $log_file)" ] && tail -n 100 $log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' || echo -e "\e[1;7;31mpanic\e[0m" && grep -C 5 panic $log_file | awk '{print "\e[1;31m第"NR"行\e[0m " $0}' ) && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
log_file=${name}_log.txt && [ -s ./$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看最后100行日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && ( [ -z "$(grep -C 5 panic $log_file)" ] && tail -n 100 $log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' || echo -e "\e[1;7;31mpanic\e[0m" && grep -C 5 panic $log_file | awk '{print "\e[1;31m第"NR"行\e[0m " $0}' ) && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
}

toilet_font () {
echo "
┌─────────────────────┐
│░█▀▀░█░░░█▀█░█▀▀░█░█░│
│░█░░░█░░░█▀█░▀▀█░█▀█░│
│░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░▀░│
└─────────────────────┘
"
}

#状态
zhuangtai () {
toilet_font
pidd=$(pid)
if [ ! -z "$pidd" ] ; then
	#runtime=$(( $(date +%s) - $(stat -c%X /proc/$pidd) ))
	if [ -s start_work_time.txt ] ; then
		start_work_pid=$(awk -F, '{print $1}' start_work_time.txt)
		if [ "$start_work_pid" = "$pidd" ] ; then
			start_work_time=$(awk -F, '{print $2}' start_work_time.txt)
			runtime=$(( $(date +%s) - $start_work_time ))
			showtime=$(echo "$((runtime/3600/24))日$((runtime/3600%24))时$((runtime%3600/60))分$((runtime%3600%60))秒")
			echo -e "\e[1;33m当前状态：\e[1;4;37m已运行 $showtime\e[0m"\\n
		else
			echo -e "\e[1;33m当前状态：\e[0m\e[37m程序pid值[$pidd]与已标记时间记录pid值[$start_work_pid]不一致，需重启主程序\e[0m"\\n
		fi
	else
		echo -e "\e[1;33m当前状态：\e[0m\e[37m未标记运行时间\e[0m"\\n
	fi
	ram=$(cat /proc/$pidd/status |awk '/VmRSS/{print $2}'|sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
else
	echo -e "\e[1;33m当前状态：\e[0m"\\n
fi
if [ -s ./${name} ] ; then
	if [ -s ./${name}_ver.txt ] ; then
		file_version=$(cat ./${name}_ver.txt)
		echo -e "★ \e[1;36m ${name} 版本：\e[1;32m【$file_version】\e[0m"
	else
		echo -e "☆ \e[1;36m ${name} 版本：\e[1;31m【未查询】\e[0m"
	fi
else
	echo -e "☆ \e[1;36m ${name} 版本：\e[1;31m【不存在】\e[0m"
fi
if [ -s /tmp/config.yaml ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat /tmp/config.yaml | awk -F// '/【/{print $2}')\e[0m临时"
elif [ -s $dirconf/config.yaml ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat $dirconf/config.yaml | awk -F// '/【/{print $2}')\e[0m闪存"
elif [ -s ./config.yaml ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat ./config.yaml | awk -F// '/【/{print $2}')\e[0m在线：$config"
else
	echo -e "☆ \e[1;36m ${name} 配置：\e[1;31m【不存在】\e[0m"
fi
pss_status=$(pss | wc -l)
if [ "$pss_status" = "1" ] ; then
	echo -e \\n"● \e[1;36m ${name} 进程：\e[1;32m【已运行】\e[0m RAM：\e[1;37m$ram KB\e[0m"
elif [ "$pss_status" -gt "1" ] ; then
	echo -e \\n"○ \e[1;36m ${name} 进程：\e[1;31m【重复进程 x $pss_status】\e[0m"
else
	echo -e \\n"○ \e[1;36m ${name} 进程：\e[1;31m【未运行】\e[0m"
fi
if [ ! -z "$(port)" ] ; then
	echo -e "● \e[1;36m ${name} 端口：\e[1;32m【已监听】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 端口：\e[1;31m【未监听】\e[0m"
fi
psskeep_status=$(psskeep | wc -l)
if [ "$psskeep_status" = "1" ] ; then
	echo -e "● \e[1;36m ${name} 进程守护：\e[1;32m【已运行】\e[0m"
elif [ "$psskeep_status" -gt "1" ] ; then
	echo -e "○ \e[1;36m ${name} 进程守护：\e[1;31m【重复进程 x $psskeep_status】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 进程守护：\e[1;31m【未运行】\e[0m"
fi
if [ ! -z "$(cat ${path}/START_CRON.SH | grep -E "${bashname} *restart ")" ] ; then
	echo -e "● \e[1;36m ${name} 定时重启1：\e[1;32m【检查进程】\e[0m"
elif [ ! -z "$(cat ${path}/START_CRON.SH | grep -E "${bashname} *[0-9]+ ")" ] ; then
	echo -e "● \e[1;36m ${name} 定时重启2：\e[1;32m【强制重启】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 定时重启：\e[1;31m【未启用】\e[0m"
fi
if [ ! -z "$(cat ${path}/START_WAN.SH | grep -E "${bashname} *restart ")" ] ; then
	echo -e "● \e[1;36m ${name} 开机自启1：\e[1;32m【检查进程】\e[0m"
elif [ ! -z "$(cat ${path}/START_WAN.SH | grep -E "${bashname} *[0-9]+ ")" ] ; then
	echo -e "● \e[1;36m ${name} 开机自启2：\e[1;32m【强制重启】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 开机自启：\e[1;31m【未启用】\e[0m"
fi
pre41=$(iptables -t mangle -vnL PREROUTING --line-numbers | grep -i $name | wc -l)
pre42=$(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp *dpt:53 *" | wc -l)
pre61=$(ip6tables -t mangle -vnL PREROUTING --line-numbers | grep -i $name | wc -l)
pre62=$(ip6tables -t nat -vnL PREROUTING --line-numbers 2>&1 | grep -Ei "udp *dpt:53 *" | wc -l)
out41=$(iptables -t mangle -vnL OUTPUT --line-numbers | grep -i $name | wc -l)
out42=$(iptables -t nat -vnL OUTPUT --line-numbers | grep -Ei "udp *dpt:53 *" | wc -l)
out61=$(ip6tables -t mangle -vnL OUTPUT --line-numbers | grep -i $name | wc -l)
out62=$(ip6tables -t nat -vnL OUTPUT --line-numbers 2>&1 | grep -Ei "udp *dpt:53 *" | wc -l)
iprule4=$(ip rule list | grep 'lookup 100' | wc -l)
iprule6=$(ip -6 rule list | grep 'lookup 100' | wc -l)
iproute4=$(ip route list table 100 | wc -l)
iproute6=$(ip -6 route list table 100 | wc -l)
tproxy_status="${pre41}${pre42}${pre61}${pre62}${out41}${out42}${out61}${out62}${iprule4}${iprule6}${iproute4}${iproute6}"
if [ "$tproxy_status" = "111000001111" -o "$tproxy_status" = "111100001111" ] ; then
	iptables_mode=1
elif [ "$tproxy_status" = "111011101111" -o "$tproxy_status" = "111011111111" -o "$tproxy_status" = "111111101111" -o "$tproxy_status" = "111111111111" ] ; then
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
	echo -e "    mode：$mode ，iptables_mode：$iptables_mode\\n    PRE：$pre41 $pre42 $pre61 $pre62 ，OUT：$out41 $out42 $out61 $out62 ，RULE：$iprule4 $iprule6 ，ROUTE：$iproute4 $iproute6"
	[ "$pre42" != "0" ] && iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp *dpt:53 *"
fi
}
#按钮
case $1 in
0)
	stop_1 &
	;;
1)
	force_url=$2
	[ -z "$(echo $force_url | grep -E '^[0-9]+$')" ] && force_url=""
	start_1 &
	;;
2)
	force_url=$2
	[ -z "$(echo $force_url | grep -E '^[0-9]+$')" ] && force_url=""
	start_2 &
	;;
3)
	force_url=$2
	[ -z "$(echo $force_url | grep -E '^[0-9]+$')" ] && force_url=""
	start_3 &
	;;
4)
	force_ip
	;;
5)
	onlyallow_lan_ip
	;;
6)
	bypass_lan_ip
	;;
7)
	resettings
	;;
8)
	force_url=$2
	[ -z "$(echo $force_url | grep -E '^[0-9]+$')" ] && force_url=""
	renew &
	;;
9)
	remove_ask
	;;
999)
	remove_force
	;;
ipt0)
	ipt0
	;;
ipt1)
	ipt1
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
start_iptables)
	start_iptables
	;;
stop_iptables)
	stop_iptables
	;;
start_remark)
	start_remark
	;;
remark)
	remark
	;;
start_setmark)
	start_setmark
	;;
setmark)
	setmark
	;;
restart)
	restart
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
	echo -e "\e[1;32m【0】\e[0m\e[1;36m stop：关闭所有 \e[0m "
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start_1：启动${name}✚tproxy透明代理\e[0m"
	echo -e "\e[1;32m【2】\e[0m\e[1;36m start_2：启动${name}✚tproxy透明代理✚自身走代理\e[0m"
	echo -e "\e[1;32m【3】\e[0m\e[1;36m start_3：仅启动${name}\e[0m"
	echo -e "\e[1;32m【4】\e[0m\e[1;36m force_ip：强制走代理的目标ipv4 IP列表\e[0m"
	echo -e "\e[1;32m【5】\e[0m\e[1;36m onlyallow_lan_ip：仅允许通过代理的来源局域网IP/MAC列表\e[0m"
	echo -e "\e[1;32m【6】\e[0m\e[1;36m bypass_lan_ip：绕过代理的来源局域网IP/MAC列表\e[0m"
	echo -e "\e[1;32m【7】\e[0m\e[1;36m resettings：重置初始化配置\e[0m"
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
	elif [ "$num" = "4" ] ; then
		force_ip
	elif [ "$num" = "5" ] ; then
		onlyallow_lan_ip
	elif [ "$num" = "6" ] ; then
		bypass_lan_ip
	elif [ "$num" = "7" ] ; then
		resettings
	elif [ "$num" = "8" ] ; then
		renew &
	elif [ "$num" = "9" ] ; then
		remove_ask
	else
		echo -e \\n"\e[1;31m输入错误。\e[0m "\\n
	fi
	;;
esac