#!/bin/bash
sh_ver=185
#
path=${0%/*}
bashname=${0##*/}
bashpid=$$

#程序名字
name=v2ray

#闪存配置文件夹
dirconf=${path}/${name}
[ ! -d $dirconf/confdir ] && mkdir -p $dirconf/confdir

tmp=/tmp
#系统定时任务文件
file_cron=/etc/storage/cron/crontabs/admin
#开机自启文件
file_wan=/etc/storage/post_wan_script.sh

user_name=${name}
#用户uid/gid
uid=0
gid=20001

#端口
#redir_port=1098
tproxy_port=1099
dns_port=5353

#资源文件地址前缀
url1="https://raw.githubusercontent.com/ss916/test/main"
url2="https://raw.githubusercontents.com/ss916/test/main"
url3="https://rrr.ariadl.eu.org/ss916/test/main"
url4="https://fastly.jsdelivr.net/gh/ss916/test@main"
url5="https://gcore.jsdelivr.net/gh/ss916/test@main"
url6="https://testingcf.jsdelivr.net/gh/ss916/test@main"
url7="https://yyellow.ariadl.eu.org/916"

[ "${path}" = "sh" -a "${bashname}" = "sh" -o "${path}" = "bash" -a "${bashname}" = "bash" ] && echo -e \\n"❗ \e[1;37m获取不到脚本真实路径path与脚本名字bashname，其值为$path。依赖路径与名字的功能将会失效。请下载脚本到本地再运行。\e[0m❗"\\n

#初始化settings.txt
settings () {
echo -e \\n"\e[1;36m↓↓ 初始化设置，請輸入配置文件链接1，输入0即表示使用本地自定义配置文件↓↓\e[0m"\\n
read -p "配置文件链接：" config
if [ "$config" != "0" ] ; then
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
echo -e \\n"\e[1;36m↓↓ 請选择透明代理模式mode ↓↓\e[0m"\\n
echo -e "\e[36m 1.tproxy透明代理\\n2.tproxy透明代理+自身代理\\n3.不启用透明代理（默认）\\n\e[0m"
read -n 1 -p "请输入：" mode
#自启
echo -e \\n"\e[1;36m↓↓ 請选择开机自启模式wan↓↓\e[0m"\\n
echo -e "\e[36m0.不启用\\n1.开机自启，仅检查进程（默认）\\n2.开机自启，强制重启进程\e[0m"
read -n 1 -p "请输入：" wan
echo -e \\n"\e[1;36m↓↓ 請选择定时启动模式cron↓↓\e[0m"\\n
echo -e "\e[36m0.不启用\\n1.定时启动，仅检查进程\\n2.定时启动，强制重启进程（默认）\e[0m"
read -n 1 -p "请输入：" cron
###
echo -e \\n"\e[1;37m你输入了：\\n\\n配置文件链接: $config \\n${name}是否解密: $secret\\n密码: $password \\n${name}tproxy透明代理: $mode\\n开机自启wan: $wan \\n定时启动cron: $cron \e[0m"\\n
echo "config=$config
secret=$secret
password=$password
mode=$mode
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
if [ -s /tmp/config.json -o -s $dirconf/config.json ] ; then
	config=0
else
	if [ -z "$config" ] ; then
		config=config.json
		secret=0
	fi
fi
[ -z "$mode" ] && mode=3 && echo "mode=$mode" >> $dirconf/settings.txt
[ -z "$wan" ] && wan=1 && echo "wan=$wan" >> $dirconf/settings.txt
[ -z "$cron" ] && cron=2 && echo "cron=$cron" >> $dirconf/settings.txt
#自定义闪存资源文件夹
if [ ! -z "$diretc" ] ; then
	if [ "$diretc" != "/tmp/${name}/etc" ] ; then
		[ ! -d $diretc ] && mkdir -p $diretc
		size=$(df $diretc | awk '!/Available/{print $4}')
		if [ "$size" -lt "5120" ] ; then
			diretc_new=/tmp/${name}/etc
			echo "！！检测到$diretc剩余空间$size KB小于5MB，强制将资源文件夹改为 $diretc_new"
			sed -i '/diretc=/d' $dirconf/settings.txt
			diretc=$diretc_new
			echo "diretc=$diretc" >> $dirconf/settings.txt
		fi
	fi
else
	diretc=/tmp/${name}/etc && echo "diretc=$diretc" >> $dirconf/settings.txt
fi
#运行目录
[ -z "$dirtmp" ] && dirtmp=/tmp/${name} && echo "dirtmp=$dirtmp" >> $dirconf/settings.txt
}
if [ ! -z "$2" -a ! -z "$3" ] ; then
	#一键快速设置参数：./v2ray.sh 1 mode=1 config=https://123.com/config.json
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


run="$dirtmp/${name} -config $dirtmp/config.json -confdir $dirtmp/confdir"

pss='ps -w |grep -v grep| grep "$run"'
pid='pidof ${name}'
port='netstat -anp 2>/dev/null | grep "${name}"'
psskeep='ps -w | grep -v grep |grep "${name}_keep.sh"'
timenow='date "+%Y-%m-%d_%H:%M:%S"'
version="$dirtmp/${name} -version | grep -i xray | cut -f 2 -d ' '"

#alias
alias pss=$pss
alias pid=$pid
alias port=$port
alias psskeep=$psskeep
alias timenow=$timenow
alias version=$version

[ ! -d $diretc ] && mkdir -p $diretc
[ ! -d $dirtmp ] && mkdir -p $dirtmp
cd $dirtmp


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


#下载主程序
down_program () {
file=${name}
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=$file
fi
[ -s ./$file ] && [ ! -x ./$file ] && echo ">> 赋予主程序文件$file执行权限" && chmod +x ./$file
}
#下载geoip
down_geoip () {
file=geoip.dat
[ -s ./${name}_log.txt ] && [ ! -z "$(grep -io "not found in geoip" ./${name}_log.txt)" ] && logger -t "【${bashname}】" "删除无效geoip.dat文件" && echo "  >> 删除无效geoip.dat文件 " && rm -rf ./geoip.dat
if [ ! -s ./geoip.dat -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=geoip.dat
fi
}
#下载geosite
down_geosite () {
file=geosite.dat
[ -s ./${name}_log.txt ] && [ ! -z "$(grep -io "not found in geosite" ./${name}_log.txt)" ] && logger -t "【${bashname}】" "删除无效geosite.dat文件" && echo "  >> 删除无效geosite.dat文件 " && rm -rf ./geosite.dat
if [ ! -s ./geosite.dat -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=geosite.dat
fi
}

#下载json
down_config () {
file=$config
if [ "$secret" = "1" -o ! -z "$(echo $file | grep -E "^c[0-9]+.json$")" ] ; then
	downloadfile address=s/$file filetgz=$file decrypt=1 password=$password fileout=./ filename=config.json 
else
	if [ "$file" = "config.json" ] ; then
		downloadfile address=$file filetgz=$file fileout=./ filename=config.json
	else
		downloadfile address=$file filetgz=$file fileout=./ filename=config.json
	fi
fi
}

#download ipset.cnip.txt
down_ipset_cnip () {
file="ipset.cnip.txt"
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=$file
fi
}


ipset_cnip () {
[ ! -s ./ipset.cnip.txt ] && down_ipset_cnip
if [ -s ./ipset.cnip.txt ] ; then
	ipset restore -f ipset.cnip.txt
	ipset_cnip_ok=1
else
	logger -t "【${bashname}】" "✖ ipset.cnip.txt文件为空，无法创建cn IP ipset表。跳过。" && echo -e \\n"\e[1;31m✖ ipset.cnip.txt文件为空，无法创建cn IP ipset表。跳过。\e[0m"
	ipset_cnip_ok=0
fi
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
#[ -s ${path}/RETURN_UID_GID.TXT ] && for uidgid in $(cat ${path}/RETURN_UID_GID.TXT | sort -u) ; do n=$(echo $uidgid | awk -F ',' '{print $1}') && g=$(echo $uidgid | awk -F ',' '{print $3}') && echo ">> ipv4 dns_redir：RETURN $n gid [$g]" && iptables -t nat -I dns_redir -m owner --gid-owner $g -j RETURN ; done
iptables -t nat -A dns_redir -p udp --dport 53 -j REDIRECT --to-ports "$dns_port"
iptables -t nat -I PREROUTING -p udp --dport 53 -j dns_redir
[ "$mode" = "2" ] && echo -e "\e[1;36m▶[out42]劫持本机ipv4 DNS 53请求到本机端口$dns_port\e[0m" && iptables -t nat -I OUTPUT -m owner ! --gid-owner $gid -p udp --dport 53 -j dns_redir
if [ -z "$(ip6tables -t nat -nL 2>&1 |grep "can't.*nat")" ] ; then
echo -e "\e[1;36m▶[pre62]劫持局域网ipv6 DNS 53请求到本机端口$dns_port\e[0m"
[ -z "$(ip6tables -t nat -nL | grep -i "chain dns_redir ")" ] && ip6tables -t nat -N dns_redir
ip6tables -t nat -F dns_redir
#[ -s ${path}/RETURN_UID_GID.TXT ] && for uidgid in $(cat ${path}/RETURN_UID_GID.TXT | sort -u) ; do n=$(echo $uidgid | awk -F ',' '{print $1}') && g=$(echo $uidgid | awk -F ',' '{print $3}') && echo ">> ipv6 dns_redir：RETURN $n gid [$g]" && ip6tables -t nat -I dns_redir -m owner --gid-owner $g -j RETURN ; done
ip6tables -t nat -A dns_redir -p udp --dport 53 -j REDIRECT --to-ports "$dns_port"
ip6tables -t nat -I PREROUTING -p udp --dport 53 -j dns_redir
[ "$mode" = "2" ] && echo -e "\e[1;36m▶[out62]劫持本机ipv6 DNS 53请求到本机端口$dns_port\e[0m" && ip6tables -t nat -I OUTPUT -m owner ! --gid-owner $gid -p udp --dport 53 -j dns_redir
else
echo -e "\e[1;36m▶ipv6 DNS：ip6tables不支持nat，直接丢弃/屏蔽所有ipv6 DNS 53请求\e[0m"
#ip6tables -t mangle -I $name -p udp --dport 53 -j DROP
[ -z "$(ip6tables -vnL INPUT --line-numbers | grep -Ei "udp *dpt:53 *reject")" ] && ip6tables -I INPUT -p udp --dport 53 -j REJECT
fi
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
##tproxy tcp+udp
tproxy4
tproxy6
##redir dns
redirect_dns
if [ "$mode" = "2" ] ; then
logger -t "【${bashname}】" "▶创建路由自身走透明代理"
tproxy4_out
tproxy6_out
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
[ ! -z "$(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp *dpt:53 *")" ] && IFS=$'\n' && for m in $(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp *dpt:53 *" | awk '{print $1}' | sed '1!G;h;$!d' ) ; do iptables -t nat -D PREROUTING $m ;done
[ ! -z "$(ip6tables -vnL INPUT --line-numbers | grep -Ei "udp *dpt:53 *reject")" ] && IFS=$'\n' && for m in $(ip6tables -vnL INPUT --line-numbers | grep -Ei "udp *dpt:53 *reject" | awk '{print $1}' | sed '1!G;h;$!d' ) ; do ip6tables -D INPUT $m ;done
if [ -z "$(ip6tables -t nat -nL 2>&1 |grep "can't.*nat")" ] ; then
ip6tables -t nat -F OUTPUT
ip6tables -t nat -F PREROUTING
fi
}

stop_iptables () {
ipt0
}

start_iptables () {
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
log1=1
net=1
skip=1
t=1
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
		local_ip4=\$(ip addr | grep -w inet | awk '{print \$2}' | sed 's@\.[0-9]*/@\.0/@g' | sort -u)
		if [ ! -z "\$local_ip4" ] ; then
			for a in \$local_ip4 ; do [ -z "\$(iptables -t mangle -nL \$name | grep -Ei "RETURN.*\$a")" ] && echo -e \\\\n">> ipv4 \$name：RETURN local ip \$a" >> ./keep.txt && insert_num=\$(iptables -t mangle -vnL \$name --line-number | awk '!/match-set.*TPROXY/&&/TPROXY redirect/{print \$1}' | head -n 1) && iptables -t mangle -I \$name \$insert_num -d \$a -j RETURN && tproxy_ok=0 ; done
			[ "\$mode" = "2" ] && for a in \$local_ip4 ; do [ -z "\$(iptables -t mangle -nL \${name}_mask | grep -Ei "RETURN.*\$a")" ] && echo -e \\\\n">> ipv4 \${name}_mask：RETURN local ip \$a" >> ./keep.txt && insert_num=\$(iptables -t mangle -vnL \${name}_mask --line-number | awk '!/match-set.*MARK set/&&/MARK set/{print \$1}' | head -n 1) && iptables -t mangle -I \${name}_mask \$insert_num -d \$a -j RETURN && tproxy_ok=0 ; done
		fi
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
if [ "\$server_port_ok" = "1" -a "\$tproxy_ok" = "1" ] ; then
	echo -e "\$(timenow) \${name} [\$v] 进程OK，端口OK，[\$t] tproxy OK" >> ./keep.txt
elif [ "\$server_port_ok" = "1" -a "\$tproxy_ok" = "close" ] ; then
	echo -e "\$(timenow) \${name} [\$v] 进程OK，端口OK" >> ./keep.txt
fi
##+1
t=\$((t+1))
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
su $user_name -c "nohup $run > $dirtmp/${name}_log.txt 2>&1 &"
}

test_json () {
if [ -s ./config.json ] ; then
	test_json_status=$(./${name} -test ./config.json)
	if [ ! -z "$(echo $test_json_status | grep "Configuration OK")" ] ; then
		logger -t "【${bashname}】" "✔ $name配置文件config.json测试通过Configuration OK..." && echo -e \\n"\e[1;32m  ✔ $name配置文件config.json测试通过Configuration OK...\e[0m"
	else
		logger -t "【${bashname}】" "✘配置文件config.json配置文件测试不通过。结束脚本。" && echo -e \\n"\e[1;31m✘配置文件config.json配置文件测试不通过。结束脚本。\e[0m"
		#exit
	fi
else
	logger -t "【${bashname}】" "✘配置文件config.json不存在或为空，请检查配置文件是否有错误，结束脚本。" && echo -e \\n"\e[1;31m✘配置文件config.json不存在或为空，请检查配置文件是否有错误，结束脚本。\e[0m"
	#exit
fi
}

get_config_file () {
configfile=config.json
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
	[ -z "$config" -o "$config" = "0" ] && logger -t "【${bashname}】" "✖ 配置文件下载链接为空或等于0，结束脚本。" && echo -e \\n"\e[36m✖ 配置文件下载链接为空或等于0，结束脚本。\e[0m" && exit
	logger -t "【${bashname}】" "▶直接github下载配置文件$configfile" && echo -e \\n"\e[36m▶直接github下载配置文件$configfile \e[0m"
	down_config
fi
[ ! -h $dirtmp/confdir ] && echo "▷创建软链接$dirconf/confdir → $dirtmp/confdir" && ln -s $dirconf/confdir $dirtmp/confdir
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
all_sh=$(ps -w | grep -v grep| grep ${bashname} | wc -l)
[ "$all_sh" -gt "2" ] && echo -e "▷关闭脚本${bashname}重复进程 x $((all_sh-1))" && ps -w | grep -v grep| grep ${bashname} && ps -w | grep -v grep | grep ${bashname} | awk '{print $1}' | xargs kill -9
}

start_0 () {
echo -e \\n"$(timenow)"\\n
stop_0
#下载文件
echo -e \\n"\e[1;36m▶检查与下载${name}资源文件...\e[0m"
get_config_file &
down_program &
down_geoip &
down_geosite &
wait
#启动主程序
start_program
#等待30秒
if [ "$mode" = "1" -o "$mode" = "2" ] ; then
	check_work_all && waitwork check_work_all 30
else
	check_work && waitwork check_work 30
fi
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
	psskeep_status=$(psskeep | wc -l) && [ "$psskeep_status" -gt "1" ] && echo -e "▷检测到进程守护脚本keep.sh进程重复 x $psskeep_status，重启脚本keep.sh" && echo -e "\\n$(timenow) ▷检测到进程守护脚本keep.sh进程重复 x $psskeep_status，重启脚本keep.sh \\n" >> $dirtmp/keep.txt && stop_keep
	start_keep
fi
}

start_1 () {
[ "$mode" != "1" ] && mode=1 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=$mode" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && run_restart_keep=1
echo "🔒keep_lock" && > skip_keep_check_start_1
start_0
start_iptables && waitwork start_iptables 6 &
wait && [ ! -z "$(ls skip_keep_check_* 2>/dev/null)" ] && echo "🔓keep_unlock" && rm skip_keep_check_*
}
start_2 () {
[ "$mode" != "2" ] && mode=2 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=$mode" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && run_restart_keep=1
echo "🔒keep_lock" && > skip_keep_check_start_2
start_0
start_iptables && waitwork start_iptables 6 &
wait && [ ! -z "$(ls skip_keep_check_* 2>/dev/null)" ] && echo "🔓keep_unlock" && rm skip_keep_check_*
}
start_3 () {
[ "$mode" != "3" ] && mode=3 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=$mode" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && run_restart_keep=1
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
down_geoip &
down_geosite &
[ "$config" != "0" ] && down_config &
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
│░█░█░▀▀▄░█▀▄░█▀█░█░█░│
│░▀▄▀░▄▀░░█▀▄░█▀█░░█░░│
│░░▀░░▀▀▀░▀░▀░▀░▀░░▀░░│
└─────────────────────┘
"
}

#状态
zhuangtai () {
toilet_font
pidd=$(pid)
if [ ! -z "$pidd" ] ; then
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
if [ -s /tmp/config.json ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat /tmp/config.json | awk -F// '/【/{print $2}')\e[0m临时"
elif [ -s $dirconf/config.json ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat $dirconf/config.json | awk -F// '/【/{print $2}')\e[0m闪存"
elif [ -s ./config.json ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat ./config.json | awk -F// '/【/{print $2}')\e[0m在线：$config"
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
start_iptables)
	start_iptables
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
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start_1：启动$name✚tproxy透明代理\e[0m"
	echo -e "\e[1;32m【2】\e[0m\e[1;36m start_2：启动$name✚tproxy透明代理✚代理自身\e[0m"
	echo -e "\e[1;32m【3】\e[0m\e[1;36m start_3：只启动$name\e[0m"
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