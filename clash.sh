#!/bin/sh
##################################
#程序名字
name=clash
#内存根目录
tmp=/tmp
#闪存根目录
etc=/etc/storage

#内存目录文件夹
dirtmp=$tmp/$name
#脚本目录
pdcn=$etc/pdcn
#闪存配置文件夹
dirconf=$pdcn/$name

#闪存资源文件夹
#diretc=/etc/storage/pdcn/clash
#diretc=/tmp/clash/etc
if [ -s $dirconf/settings.txt ] ; then
	diretc=$(cat $dirconf/settings.txt |awk -F 'diretc=' '/diretc=/{print $2}' | head -n 1)
	if [ ! -z "$diretc" ] ; then
		size=$(df $etc |awk '!/Available/{print $4}')
		if [ "$size" -lt "5120" ] ; then
			echo "检测到闪存$etc剩余空间$size KB小于5MB，资源文件將下载保存到內存中$dirtmp"
			diretc=/tmp/clash/etc
		fi
	else
		diretc=/tmp/clash/etc
		echo "diretc=/tmp/clash/etc" >> $dirconf/settings.txt
	fi
else
	diretc=/tmp/clash/etc
fi

#系统定时任务文件
file_cron=$etc/cron/crontabs/admin
#开机自启文件
file_wan=$etc/post_wan_script.sh

#iptables设置绕过UID
#创建系统新用户
user_name=$name
#用户UID
user_id=998


#资源文件地址前缀
url1="https://raw.githubusercontent.com/ss916/test/master"
url2="https://cdn.jsdelivr.net/gh/ss916/test"
url3="https://raw.fastgit.org/ss916/test/master"

if [ ! -z "$(ps -w |grep -v grep| grep "clash.*-d")" -a ! -z "$(netstat -anp | grep clash)" ] ; then
	curl="curl -x 127.0.0.1:8005"
	url=$url1
else
	curl="curl"
	url=$url3
fi

[ ! -d $dirtmp ] && mkdir -p $dirtmp
[ ! -d $diretc ] && mkdir -p $diretc
[ ! -d $dirconf ] && mkdir -p $dirconf
cd $dirtmp

#初始化settings.txt
settings () {
echo -e \\n"\e[1;36m↓↓ 初始化设置，請輸入订阅链接link ↓↓\e[0m"\\n
read -p "订阅链接1：" link1
read -p "订阅链接2(按回车可跳过)：" link2
#模式
echo -e \\n"\e[1;36m↓↓ 請选择透明代理模式mode ↓↓\e[0m"\\n
echo -e "\e[36m1.启用透明代理（默认）\\n2.透明代理+路由自身走代理\\n5.不启用透明代理\e[0m"
read -n 1 -p "请输入：" mode
echo -e \\n"\e[1;36m↓↓ 請选择DNS模式 ↓↓\e[0m"\\n
echo -e "\e[36m1.redir-host模式（默认）\\n2.fake-dns模式\e[0m"
read -n 1 -p "请输入：" dns
echo -e \\n"\e[1;36m↓↓ 請选择代理模式 ↓↓\e[0m"\\n
echo -e "\e[36m1.gfwlist模式（默认）\\n2.大陆白名单模式\e[0m"
read -n 1 -p "请输入：" chinalist
#功能
echo -e \\n"\e[1;36m↓↓ 請选择是否启用去广告功能 ↓↓\e[0m"\\n
echo -e "\e[36m0.不启用adblock（默认）\\n1.启用adblock\e[0m"
read -n 1 -p "请输入：" adblock
echo -e \\n"\e[1;36m↓↓ 請选择网易云解锁 ↓↓\e[0m"\\n
echo -e "\e[36m0.不启用网易云解锁（默认）\\n1.启用网易云解锁\e[0m"
read -n 1 -p "请输入：" unlocknetease
echo -e \\n"\e[1;37m你输入了：	\\n$name订阅链接1: $link1 \\n$name订阅链接2: $link2\\n透明代理模式: $mode \\nDNS模式: $dns \\n去广告: $adblock\\n代理模式: $chinalist \\n网易云: $unlocknetease\e[0m"
echo "link1=$link1
link2=$link2
mode=$mode
dns=$dns
chinalist=$chinalist
adblock=$adblock
unlocknetease=$unlocknetease
" > $dirconf/settings.txt
}
#读取参数
read_settings () {
#透明代理模式，mode=1 透明代理（默认），mode=2 透明代理+自身代理，mode=5 不透明代理
mode=$(cat $dirconf/settings.txt |awk -F 'mode=' '/mode=/{print $2}' | head -n 1)
[ -z "$mode" ] && mode=1 && echo "mode=1" >> $dirconf/settings.txt
#DNS模式，1.redir-host （默认），2.fake-dns
dns=$(cat $dirconf/settings.txt |awk -F 'dns=' '/dns=/{print $2}' | head -n 1)
[ -z "$dns" ] && dns=1 && echo "dns=1" >> $dirconf/settings.txt
#代理模式，1.gfwlist模式（默认），2.chinalist
chinalist=$(cat $dirconf/settings.txt |awk -F 'chinalist=' '/chinalist=/{print $2}' | head -n 1)
[ -z "$chinalist" ] && chinalist=1 && echo "chinalist=1" >> $dirconf/settings.txt
#使用自定义配置模板，留空则使用 config=config.yaml （默认）
config=$(cat $dirconf/settings.txt |awk -F 'config=' '/config=/{print $2}' | head -n 1)
[ -z "$config" ] && config=config.yaml && echo "config=config.yaml" >> $dirconf/settings.txt
#模板是否需要解密文件，secret=1 则进入解密模式
secret=$(cat $dirconf/settings.txt |awk -F 'secret=' '/secret=/{print $2}' | head -n 1)
#密码
password=$(cat $dirconf/settings.txt |awk -F 'password=' '/password=/{print $2}' | head -n 1)
#订阅地址1，不可为空
link1=$(cat $dirconf/settings.txt |awk -F 'link1=' '/link1=/{print $2}' | head -n 1)
#订阅地址2，可空
link2=$(cat $dirconf/settings.txt |awk -F 'link2=' '/link2=/{print $2}' | head -n 1)
#功能
#是否启用去广告，adblock=1则启用，关闭0（默认）
adblock=$(cat $dirconf/settings.txt |awk -F 'adblock=' '/adblock=/{print $2}' | head -n 1)
[ -z "$adblock" ] && adblock=0 && echo "adblock=0" >> $dirconf/settings.txt
#是否启用网易云解锁，1.unlocknetease启用，0.关闭（默认）
unlocknetease=$(cat $dirconf/settings.txt |awk -F 'unlocknetease=' '/unlocknetease=/{print $2}' | head -n 1)
[ -z "$unlocknetease" ] && unlocknetease=0 && echo "unlocknetease=0" >> $dirconf/settings.txt
#自定义闪存目录
diretc=$(cat $dirconf/settings.txt |awk -F 'diretc=' '/diretc=/{print $2}' | head -n 1)
[ -z "$diretc" ] && diretc=/tmp/clash/etc && echo "diretc=/tmp/clash/etc" >> $dirconf/settings.txt
}
if [ ! -z "$2" -a ! -z "$3" ] ; then
	#一键快速设置参数：./clash.sh 1 mode=1 config=config.yaml link1=https://123.com/link1.txt link2=https://123.com/link2.txt adblock=1 chinalist=1 unlocknetease=0 dns=1
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

edit_chinalist () {
#是否启用大陆白名单功能，2启用chinalist，1则默认gfwlist
if [ "$chinalist" = "2" ] ; then
sed -i '/#markgfwlistorchinalist1/s@- 直连 #@- 代理 #@g;/#markgfwlistorchinalist2/s@- 代理 #@- 直连 #@g' ./config.yaml
fi
}
edit_dns () {
#DNS模式，2启用fake-ip，非2则默认redir-host
[ "$dns" = "2" ] && sed -i '/#markdns/s/redir-host/fake-ip/;/#markdns/s/ipv6: true/ipv6: false/' ./config.yaml
}
edit_link () {
#检查订阅是否可用
testlink1=$(echo $link1 | grep ^http)
testlink2=$(echo $link2 | grep ^http)
if [ ! -z "$link2" -a ! -z "$testlink2" ] ; then
	sed -i "s@#mark订阅2@  订阅2:\n    type: http\n    url: $link2\n    interval: 30000\n    path: $dirconf/订阅2.txt\n    health-check:\n      enable: true\n      interval: 600\n      url: http://clients1.google.com/generate_204@" ./config.yaml
else
	sed -i '/订阅2/d' ./config.yaml
fi
if [ ! -z "$link1" ] ; then
	if [ ! -z "$testlink1" ] ; then
		sed -i "s@#mark订阅1@  订阅1:\n    type: http\n    url: $link1\n    interval: 30000\n    path: $dirconf/订阅1.txt\n    health-check:\n      enable: true\n      interval: 600\n      url: http://clients1.google.com/generate_204@" ./config.yaml
	else
		echo -e \\n"\e[1;31m【$name】  ✘ 订阅链接1非http链接，请初始化配置。\e[0m"
		exit
	fi
else
	echo -e \\n"\e[1;31m【$name】  ✘ 订阅链接1為空，请初始化配置。\e[0m"
	exit
fi
#sed -i "s@#mark文件1@  文件1:\n    type: file\n    interval: 30000\n    path: ./文件1.txt\n    health-check:\n      enable: true\n      interval: 600\n      url: http://clients2.google.com/generate_204@" ./config.yaml
#sed -i "s@#mark文件2@  文件2:\n    type: file\n    interval: 30000\n    path: ./文件2.txt\n    health-check:\n      enable: true\n      interval: 600\n      url: http://clients2.google.com/generate_204@" ./config.yaml
}
edit_adblock () {
#是否启用去广告功能，1启用，非1则默认关闭
[ "$adblock" != "1" ] && sed -i '/#markadblock/d' ./config.yaml
}
edit_unlocknetease () {
#是否启用网易云解锁功能，1启用，非1则默认直连
if [ "$unlocknetease" = "1" ] ; then
sed -i '/#markunlocknetease1/s@- 直连 #@- 網易云解鎖 #@g;/#markunlocknetease2/s@- 網易云解鎖 #@- 直连 #@g' ./config.yaml
fi
}

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
	echo -e \\n"\e[36m▶下载校验文件SHA1.TXT......\e[0m"
	$curl -# $url/SHA1.TXT -o $tmp/SHA1.TXT
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
	logger -t "【$filename】" "▷github下载文件$filetgz..." && echo -e \\n"\e[1;7;37m▷『$filename』github下载文件$filetgz...\e[0m"
	[ ! -z "$(ps -w | grep -v grep | grep "curl.*$filetgz")" ] && echo "！已存在curl下載$filetgz進程，先kill。" && ps -w | grep "curl.*$filetgz" | grep -v grep | awk '{print $1}' | xargs kill -9
	$curl -# $link -o ./$filetgz
	new=$(openssl SHA1 ./$filetgz |awk '{print $2}')
fi
old=$(cat $etc/SHA1.TXT | grep $address | awk -F ' ' '/\/'$filetgz'=/{print $2}')
echo -e \\n"文件：$filetgz \\nnew：$new \\nold：$old"
if [ ! -z "$new" -a ! -z "$old" ] ; then
	if [ "$new" = "$old" ] ; then
		if [ -s ./$filetgz ] ; then
			echo -e \\n"\e[36m▷新下载文件$filetgz校验成功，复制到$diretc/$filetgz...\e[0m"
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
		echo -e \\n"\e[36m▷解压文件$filetgz...\e[0m"
		tar xzvf $diretc/$filetgz -C $fileout
		echo -e \\n"\e[32m✔文件$filetgz解压完成...\e[0m"\\n
	elif [ "$type" = "zip" ] ; then
		echo -e \\n"\e[36m▷解压文件$filetgz...\e[0m"
		[ ! -s /opt/bin/unzip ] && echo -e "  >> 检测到opt需要安装unzip..." && opkg update && opkg install unzip
		unzip -o $diretc/$filetgz -d $fileout
		echo -e \\n"\e[32m✔文件$filetgz解压完成...\e[0m"\\n
	elif [ "$secret" = "1" ] ; then
		echo -e \\n"\e[36m▷解密文件$filetgz到...\e[0m"
		cat $diretc/$filetgz | openssl enc -aes-256-ctr -d -a -md md5 -k $password > $fileout/$filename
		echo -e \\n"\e[32m✔ $filetgz文件解密$filename完成...\e[0m"\\n
	else
		cp -f $diretc/$filetgz ./$filetgz
		echo -e \\n"\e[32m✔ 直接复制$diretc/$filetgz文件到./$filetgz...\e[0m"\\n
	fi
	#跳出循环
	break
fi
n=$(expr $n + 1)
done
[ "$n" -gt "$m" ] && logger -t "【$filename】" "✖下载[$m]次都失败！！！" && echo -e \\n"\e[1;31m✖『$filename』下载[$m]次都失败！！！\e[0m"\\n
}

#下载文件并解密
#downloadfile address=t/c filename=config.yaml filetgz=c secret=1 password=1+1=1
#下载文件并解压
#downloadfile address=t/Country.mmdb.tgz filename=Country.mmdb filetgz=Country.mmdb.tgz fileout=/tmp
#下载文件
#downloadfile address=t/clash filename=clash filetgz=clash


#下载主程序clash
down_clash () {
file=$name
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filename=$file filetgz=$file
	[ -s ./$file ] && chmod +x -R ./
fi
}
#下载geoip
down_geoip () {
file=Country.mmdb
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	[ -s ./clash_log.txt ] && [ ! -z "$(grep -o "Can't load mmdb" ./clash_log.txt)" -o ! -z "$(grep -o "Can't find MMDB" ./clash_log.txt)" ] && logger -t "【$name】"  "删除无效$file文件" && echo "  >> 删除无效$file文件 " && rm -rf ./$file && rm -rf $tmp/$file
	downloadfile address=t/$file.tgz filename=$file filetgz=$file.tgz fileout=$tmp
	if [ -s $tmp/$file ] ; then
		[ -f $dirtmp/$file ] && rm $dirtmp/$file
		ln -s $tmp/$file $dirtmp/$file
	else
		echo "$tmp/$file文件为空，跳过创建软链接。"
	fi
fi
}
#下载主題Web文件
down_web () {
file="clash-dashboard-gh-pages"
if [ ! -s ./$file/index.html -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file.tgz filename=$file filetgz=$file.tgz fileout=./
fi
}
#下载config.yaml
down_config () {
file=$config
if [ -s $tmp/config.yaml ] ; then
	cp -f $tmp/$file ./config.yaml
	ver=$(cat ./config.yaml | awk -F// '/【/{print $2}')
	logger -t "【$name】" "▶进入测试模式，使用本地配置文件$file，版本$ver" && echo -e \\n"\e[1;36m▶进入测试模式，使用本地配置文件。\\n    $file\e[0m\e[1;32m$ver\e[0m"
else
	#if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=$file filename=$file filetgz=$file
	#fi
fi
}

#transocks
transocks_stop () {
[ ! -z "$(ps -w | grep -v grep | grep tran)" ] && logger -t "【clash.sh】" "▷检测到transocks正在运行，先stop..." && echo -e \\n"\e[1;33m▷检测到transocks正在运行，先stop...\e[0m" && nvram set app_27=0 && /etc/storage/script/Sh58_tran_socks.sh stop
[ ! -z "$(ps -w | grep -v grep | grep chinadns)" ] && nvram set app_1=0 && /etc/storage/script/Sh19_chinadns.sh stop
}
transocks_start () {
logger -t "【clash.sh】" "▶启动transocks透明代理..." && echo -e \\n"\e[1;33m▶启动transocks透明代理......\e[0m"
#啟動1
nvram set app_27=1
#代理模式
nvram set transocks_proxy_mode_x=socks5
#路由模式 0 为chnroute, 1 为 gfwlist, 2 为全局
nvram set app_28=1
lan_ipaddr=$(nvram get lan_ipaddr)
#透明重定向的代理服务器IP
nvram set app_30=$lan_ipaddr
#透明重定向的代理端口
nvram set app_31=8005
#远端服务器IP
nvram set app_32=$lan_ipaddr
#chinadns
nvram set app_1=1
nvram set app_5="223.5.5.5,127.0.0.1:5300"
/etc/storage/script/Sh58_tran_socks.sh start &
/etc/storage/script/Sh19_chinadns.sh start &
}
#ipt2socks
ipt2socks_stop () {
[ ! -z "$(ps -w | grep -v grep | grep ipt2socks)" ] && logger -t "【clash.sh】" "▷检测到ipt2socks正在运行，先stop..." && echo -e \\n"\e[1;33m▷检测到ipt2socks正在运行，先stop...\e[0m" && nvram set app_104=0 && /etc/storage/script/Sh39_ipt2socks.sh stop
[ ! -z "$(ps -w | grep -v grep | grep chinadns)" ] && nvram set app_1=0 && /etc/storage/script/Sh19_chinadns.sh stop
}
ipt2socks_start () {
logger -t "【clash.sh】" "▶启动ipt2socks透明代理..." && echo -e \\n"\e[1;33m▶启动ipt2socks透明代理......\e[0m"
#啟動1
nvram set app_104=1
#代理模式
nvram set transocks_proxy_mode_x=socks5
#路由模式 0 为chnroute, 1 为 gfwlist, 2 为全局
nvram set app_28=1
lan_ipaddr=$(nvram get lan_ipaddr)
#透明重定向的代理服务器IP
nvram set app_30=$lan_ipaddr
#透明重定向的代理端口
nvram set app_31=8005
#远端服务器IP
nvram set app_32=$lan_ipaddr
#chinadns
nvram set app_1=1
nvram set app_5="223.5.5.5,127.0.0.1:5300"
/etc/storage/script/Sh39_ipt2socks.sh start &
/etc/storage/script/Sh19_chinadns.sh start &
}

setmark () {
[ ! -d $dirtmp/mark ] && mkdir -p $dirtmp/mark
config=$dirtmp/config.yaml
secret=$(cat $config | awk '/secret:/{print $2}' | sed 's/"//g')
port=$(cat $config | awk -F: '/external-controller/{print $3}')
curl -s -X GET "http://127.0.0.1:$port/proxies" -H "Authorization: Bearer $secret" | sed 's/\},/\},\n/g'  | grep "Selector" | grep "now" |grep -Eo "name.*" > $dirtmp/mark/mark_new.txt
if [ ! -s $dirtmp/mark/mark_old.txt ] ; then
	if [ ! -s $dirconf/mark.txt ] ; then
		echo -e \\n"\e[1;36m▶直接保存[节点位置记录]到$dirconf/mark.txt ...\e[0m"
		cp -f $dirtmp/mark/mark_new.txt $dirtmp/mark/mark_old.txt
		cp -f $dirtmp/mark/mark_new.txt $dirconf/mark.txt
		[ -f $dirtmp/mark/mark_ok_* ] && rm $dirtmp/mark/mark_ok_*
		> $dirtmp/mark/mark_ok_0
		exit
	else
		cp -f $dirconf/mark.txt $dirtmp/mark/mark_old.txt
	fi
fi
new=$(openssl SHA1 $dirtmp/mark/mark_new.txt |awk '{print $2}')
old=$(openssl SHA1 $dirtmp/mark/mark_old.txt |awk '{print $2}')
if [ "$new" != "$old" ] ; then
	echo -e \\n"\e[1;36m▶保存新[节点位置记录]到$dirconf/mark.txt ...\e[0m"
	cp -f $dirtmp/mark/mark_new.txt $dirtmp/mark/mark_old.txt
	cp -f $dirtmp/mark/mark_new.txt $dirconf/mark.txt
	[ -f $dirtmp/mark/mark_ok_* ] && rm $dirtmp/mark/mark_ok_*
	> $dirtmp/mark/mark_ok_0
else
	#echo "节点位置记录文件无需更新"
	[ -f $dirtmp/mark/mark_ok_* ] && rm $dirtmp/mark/mark_ok_*
	> $dirtmp/mark/mark_ok_1
fi
}

remark_while () {
while read a
do
	names=$(echo $a|grep -Eo "name.*"|awk -F\" '{print $3}')
	now=$(echo $a|grep -Eo "now.*"|awk -F\" '{print $3}')
	if [ -z "$(echo "$names"  | grep -E '^[A-Za-z0-9]+$')" ] ; then
		nameencode=$(curl -sv -G --data-urlencode "$names" -X GET "http://127.0.0.1:$port" 2>&1 |awk '/GET/{print $3}'|sed 's@/?@@')
	else
		nameencode=$names
	fi
	echo -e \\n"★$a"
	echo -e "●策略组：$names → 上次选中：$now"
	echo -e "■encode编码：$nameencode"
	curl -sv -X PUT "http://127.0.0.1:$port/proxies/$nameencode" -H "Authorization: Bearer $secret" -d "{\"name\": \"$now\"}" 2>&1
done < $dirconf/mark.txt
}
remark_for () {
IFS=$'\n'
for a in $(cat $dirconf/mark.txt)
do
	names=$(echo $a|grep -Eo "name.*"|awk -F\" '{print $3}')
	now=$(echo $a|grep -Eo "now.*"|awk -F\" '{print $3}')
	if [ -z "$(echo "$names"  | grep -E '^[A-Za-z0-9]+$')" ] ; then
		nameencode=$(curl -sv -G --data-urlencode "$names" -X GET "http://127.0.0.1:$port" 2>&1 |awk '/GET/{print $3}'|sed 's@/?@@')
	else
		nameencode=$names
	fi
	echo -e \\n"★$a"
	echo -e "●策略组：$names → 上次选中：$now"
	echo -e "■encode编码：$nameencode"
	curl -sv -X PUT "http://127.0.0.1:$port/proxies/$nameencode" -H "Authorization: Bearer $secret" -d "{\"name\": \"$now\"}" 2>&1
done
}
remark () {
[ ! -d $dirtmp/mark ] && mkdir -p $dirtmp/mark
config=$dirtmp/config.yaml
secret=$(cat $config | awk '/secret:/{print $2}' | sed 's/"//g')
port=$(cat $config | awk -F: '/external-controller/{print $3}')
if [ -s $dirconf/mark.txt ] ; then
echo -e \\n"\e[1;36m▶还原节点位置记录...\e[0m"
#remark_for > $dirtmp/mark/mark_status.txt
remark_while > $dirtmp/mark/mark_status.txt
sed -i "1i\######$(date "+%Y-%m-%d %H:%M:%S") #######" $dirtmp/mark/mark_status.txt
else
echo -e \\n"\e[1;37m▷节点位置记录文件不存在$dirconf/mark.txt，跳过还原。\e[0m"
fi
}
start_remark () {
if [ ! -z "$(ps -w |grep -v grep| grep "$name.*-d")" -a ! -z "$(netstat -anp | grep $name)" -a ! -z "$(grep "RESTful API listening at" $dirtmp/clash_log.txt)" ] ; then
	remark
else
	echo "    ✖ start_remark：$name进程或端口没启动成功，跳过还原节点记录。"
fi
}

bypasslan () {
#局域网绕过
if [ -s $dirconf/bypasslan.txt ] ; then
	logger -t "【$name】" "▶添加iptables绕过局域网IP.." && echo -e \\n"\e[1;36m▶添加iptables绕过局域网IP...\e[0m"
	IFS=$'\n'
	for ip in $(cat $dirconf/bypasslan.txt)
	do
		iptables -t nat -I clash -s $ip/32 -j RETURN
		iptables -t mangle -I clash -s $ip/32 -j RETURN
	done 
fi
}
bypass_lan_ip () {
[ ! -f $dirconf/bypasslan.txt ] && > $dirconf/bypasslan.txt
echo -e \\n"\e[1;37m...局域网绕过IP列表$dirconf/bypasslan.txt..\e[0m"
cat $dirconf/bypasslan.txt
echo -e \\n"\e[1;37m.↓↓输入IP地址则添加IP，输入0将重置列表↓↓\e[0m"
read -p "请输入：" lanip
if [ "$lanip" = "0" ] ; then
	> $dirconf/bypasslan.txt
	echo -e \\n"\e[1;37m.已重置IP列表。\e[0m"
else
	echo "$lanip" | grep -Eo '([0-9]+\.){3}[0-9]+' >> $dirconf/bypasslan.txt
	sed -i '/^ *$/d' $dirconf/bypasslan.txt
fi
}

#透明代理
ipt1 () {
#检查是否缺少tproxy模块modprobe 
[ -z "$(lsmod | grep xt_TPROXY)" ] && echo "▶加載內核模塊 xt_TPROXY" && modprobe xt_TPROXY
#从配置文件提取参数
config=$dirtmp/config.yaml
if [ -s $config ] ; then
	#提取redir-port透明代理端口
	redir_port=$(cat $config | awk '/redir-port:/{print $2}' | sed 's/"//g')
	#提取DNS监听端口
	dns_port=$(cat $config | awk -F: '/listen:/{print $NF}')
else
	redir_port=8002
	dns_port=5300
fi
##########
logger -t "【$name】" "▶创建局域网透明代理" && echo -e \\n"\e[1;36m▶创建局域网透明代理\e[0m"\\n
#TCP
iptables -t nat -N clash >/dev/null 2>&1
iptables -t nat -F clash
iptables -t nat -A clash -d 0.0.0.0/8 -j RETURN
iptables -t nat -A clash -d 10.0.0.0/8 -j RETURN
iptables -t nat -A clash -d 127.0.0.0/8 -j RETURN
iptables -t nat -A clash -d 169.254.0.0/16 -j RETURN
iptables -t nat -A clash -d 172.16.0.0/12 -j RETURN
iptables -t nat -A clash -d 192.168.0.0/16 -j RETURN
iptables -t nat -A clash -d 224.0.0.0/4 -j RETURN
iptables -t nat -A clash -d 240.0.0.0/4 -j RETURN
iptables -t nat -A clash -p tcp -j REDIRECT --to-port "$redir_port"
iptables -t nat -A PREROUTING -p tcp -j clash
##udp
ip rule add fwmark 1 table 100
ip route add local default dev lo table 100
iptables -t mangle -N clash >/dev/null 2>&1
iptables -t mangle -F clash
iptables -t mangle -A clash -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A clash -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A clash -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A clash -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A clash -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A clash -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A clash -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A clash -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A clash -p udp -j TPROXY --on-port "$redir_port" --tproxy-mark 1
iptables -t mangle -A PREROUTING -p udp ! --dport 53 -j clash
#DNS流量
iptables -t nat -N CLASHDNS >/dev/null 2>&1
iptables -t nat -F CLASHDNS
iptables -t nat -A CLASHDNS -p udp -j REDIRECT --to-ports "$dns_port"
iptables -t nat -A PREROUTING -p udp --dport 53 -j CLASHDNS
#路由自身UDP53走代理
iptables -t nat -A OUTPUT -m owner ! --uid-owner "$user_id" -p udp --dport 53 -j CLASHDNS
if [ "$mode" = "2" ] ; then
	logger -t "【$name】" "▶创建路由自身走透明代理" && echo -e \\n"\e[1;36m▶创建路由自身走透明代理\e[0m"\\n
	iptables -t nat -A OUTPUT -m owner ! --uid-owner "$user_id" -p tcp -j clash
fi
#绕过局域网
bypasslan
}

ipt0 () {
logger -t "【$name】" "▷删除透明代理iptables规则" && echo -e \\n"\e[1;36m▷删除透明代理iptables规则\e[0m"\\n
iptables -t nat -F clash >/dev/null 2>&1
[ ! -z "$(iptables -t nat -nL PREROUTING | grep clash)" ] && iptables -t nat -D PREROUTING -p tcp -j clash
iptables -t nat -F CLASHDNS >/dev/null 2>&1
[ ! -z "$(iptables -t nat -nL PREROUTING | grep CLASHDNS)" ] && iptables -t nat -D PREROUTING -p udp --dport 53 -j CLASHDNS
ip rule del fwmark 1 table 100 >/dev/null 2>&1
ip route del local default dev lo table 100 >/dev/null 2>&1
iptables -t mangle -F clash >/dev/null 2>&1
[ ! -z "$(iptables -t mangle -nL PREROUTING | grep clash)" ] && iptables -t mangle -D PREROUTING -p udp ! --dport 53 -j clash
[ ! -z "$(iptables -t nat -nL OUTPUT | grep clash)" ] && iptables -t nat -D OUTPUT -m owner ! --uid-owner "$user_id" -p tcp -j clash
[ ! -z "$(iptables -t nat -nL OUTPUT | grep CLASHDNS)" ] && iptables -t nat -D OUTPUT -m owner ! --uid-owner "$user_id" -p udp --dport 53 -j CLASHDNS
}
stop_iptables () {
ipt0
}

start_iptables () {
pre1=$(iptables -t nat -nL PREROUTING | grep clash | wc -l)
pre2=$(iptables -t nat -nL PREROUTING | grep CLASHDNS | wc -l)
pre3=$(iptables -t mangle -nL PREROUTING | grep clash | wc -l)
out1=$(iptables -t nat -nL OUTPUT | grep CLASHDNS | wc -l)
out2=$(iptables -t nat -nL OUTPUT | grep clash | wc -l)
if [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "0" ] ; then
	iptables_mode=1
elif [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "1" ] ; then
	iptables_mode=2
else
	iptables_mode=0
fi
if [ "$mode" = "1" -a "$iptables_mode" = "1" ] ; then
	echo "    ✓ start_iptables：$name当前模式mode 1，iptables mode 1，iptables规则正常，跳过设置。"
elif [ "$mode" = "2" -a "$iptables_mode" = "2" ] ; then
	echo "    ✓ start_iptables：$name当前模式mode 2，iptables mode 2，iptables规则正常，跳过设置。"
else
	#删除iptables规则
	[ "$pre1" != "0" ] && ipt0
	[ "$pre2" != "0" ] && ipt0
	[ "$pre3" != "0" ] && ipt0
	[ "$out1" != "0" ] && ipt0
	[ "$out2" != "0" ] && ipt0
	if [ ! -z "$(ps -w |grep -v grep| grep "$name.*-d")" -a ! -z "$(netstat -anp | grep $name)" -a ! -z "$(grep "RESTful API listening at" $dirtmp/clash_log.txt)" ] ; then
		ipt1
	else
		echo "    ✖ start_iptables：$name进程或端口没启动成功，跳过设置透明代理。"
	fi
fi
}


dnsmasq1 () {
if [ -z "$(grep "#clashDNS" /etc/storage/dnsmasq/dnsmasq.conf)" ] ; then
echo "▶添加dnsmasq clash規則"
echo "server=127.0.0.1#5300 #clashDNS
no-resolv #clashDNS" >> /etc/storage/dnsmasq/dnsmasq.conf
restart_dhcpd
fi
}
dnsmasq0 () {
[ ! -z "$(grep "#clashDNS" /etc/storage/dnsmasq/dnsmasq.conf)" ] && sed -i '/#clashDNS/d' /etc/storage/dnsmasq/dnsmasq.conf && echo "▷刪除dnsmasq clash規則" && restart_dhcpd
}


#开机自启
stop_wan () {
[ -f $pdcn/START_WAN.SH -a ! -z "$(cat $pdcn/START_WAN.SH | grep $name.sh)" ] && echo -e \\n"\e[1;36m▷删除开机自启任务...\e[0m" && sed -i "/$name.sh/d" $pdcn/START_WAN.SH
}
start_wan () {
[ -z "$(cat $file_wan | grep START_WAN.SH)" ] && echo "sh $pdcn/START_WAN.SH &" >> $file_wan
[ ! -f $pdcn/START_WAN.SH ] && > $pdcn/START_WAN.SH
[ -z "$(cat $pdcn/START_WAN.SH | grep $name.sh)" ] && echo -e \\n"\e[1;36m▶创建开机自启任务...\e[0m" && echo "sh $pdcn/$name.sh $mode &" >> $pdcn/START_WAN.SH
}

#定时任务
stop_cron () {
[ -f $pdcn/START_CRON.SH -a ! -z "$(cat $pdcn/START_CRON.SH | grep $name.sh)" ] && echo -e \\n"\e[1;36m▷删除定时任务crontab...\e[0m" && sed -i "/$name.sh/d" $pdcn/START_CRON.SH
}
start_cron () {
[ -z "$(cat $file_cron | grep START_CRON.SH)" ] && echo "1 5 * * * sh $pdcn/START_CRON.SH &" >> $file_cron
[ ! -f $pdcn/START_CRON.SH ] && > $pdcn/START_CRON.SH
[ -z "$(cat $pdcn/START_CRON.SH | grep $name.sh)" ] && echo -e \\n"\e[1;36m▶创建定时任务crontab...\e[0m" && echo "sh $pdcn/$name.sh $mode &" >> $pdcn/START_CRON.SH
}

#进程守护
start_keep () {
if [ ! -s $dirtmp/clash_keep.sh ] ; then
echo "▶生成进程守护脚本."
cat > $dirtmp/clash_keep.sh << \EOF
#!/bin/sh
name=clash
dir=/tmp/clash
etc=/etc/storage/pdcn
mode=$(cat $etc/$name/settings.txt |awk -F 'mode=' '/mode=/{print $2}')
cd $dir
v=1
w=1
a=1
log1=1
while true ; do
#检查进程与端口
server=$(ps -w | grep -v grep |grep "$name.*-d")
port=$(netstat -anp | grep $name)
pre1=$(iptables -t nat -nL PREROUTING | grep clash | wc -l)
pre2=$(iptables -t nat -nL PREROUTING | grep CLASHDNS | wc -l)
pre3=$(iptables -t mangle -nL PREROUTING | grep clash | wc -l)
out1=$(iptables -t nat -nL OUTPUT | grep CLASHDNS | wc -l)
out2=$(iptables -t nat -nL OUTPUT | grep clash | wc -l)
if [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "0" ] ; then
	iptables_mode=1
elif [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "1" ] ; then
	iptables_mode=2
else
	iptables_mode=0
fi
if [ "$mode" = "1" -o "$mode" = "2" ] ; then
	if [ -z "$server" -o -z "$port" ] ; then
		[ -z "$server" ] && echo -e "$(date "+%Y-%m-%d_%H:%M:%S") [$v]检测$name进程不存在，重启程序！" >> ./keep.txt
		[ -z "$port" ] && echo -e "$(date "+%Y-%m-%d_%H:%M:%S") [$v]检测$name端口没监听，重启程序！" >> ./keep.txt
		nohup sh $etc/$name.sh $mode & > ./keep.txt 2>&1 &
		v=0
	elif [ "$mode" = "1" -a "$iptables_mode" != "1" ] ; then
		echo -e "$(date "+%Y-%m-%d_%H:%M:%S") [$w]检测$name需要重置iptables规则1！" >> ./keep.txt
		echo "mode：$mode ， iptables_mode：$iptables_mode，$pre1 $pre2 $pre3 $out1 $out2" >> ./keep.txt
		sh $etc/$name.sh start_iptables &
		w=0
	elif [ "$mode" = "2" -a "$iptables_mode" != "2" ] ; then
		echo -e "$(date "+%Y-%m-%d_%H:%M:%S") [$w]检测$name需要重置iptables规则2！" >> ./keep.txt
		echo "mode：$mode ， iptables_mode：$iptables_mode，$pre1 $pre2 $pre3 $out1 $out2" >> ./keep.txt
		sh $etc/$name.sh start_iptables &
		w=0
	else
		sh $etc/$name.sh setmark
		[ -f $dir/mark/mark_ok_0 ] && a=0
		echo -e "$(date "+%Y-%m-%d_%H:%M:%S") $name [$v] 进程OK，端口OK，[$w] iptables $iptables_mode OK，[$a] setmark OK" >> ./keep.txt
	fi
else
	if [ -z "$server" -o -z "$port" ] ; then
		[ -z "$server" ] && echo -e "$(date "+%Y-%m-%d_%H:%M:%S") [$v]检测$name进程不存在，重启程序！" >> ./keep.txt
		[ -z "$port" ] && echo -e "$(date "+%Y-%m-%d_%H:%M:%S") [$v]检测$name端口没监听，重启程序！" >> ./keep.txt
		nohup sh $etc/$name.sh $mode & > ./keep.txt 2>&1 &
		v=0
	else
		sh $etc/$name.sh setmark
		[ -f $dir/mark/mark_ok_0 ] && a=1
		echo -e "$(date "+%Y-%m-%d_%H:%M:%S") $name [$v] 进程OK，端口OK，[$a] setmark OK" >> ./keep.txt
	fi
fi
v=$(expr $v + 1)
w=$(expr $w + 1)
a=$(expr $a + 1)
#日志文件大于1万条后删除1000条
[ -s ./keep.txt ] && [ "$(sed -n '$=' ./keep.txt)" -ge "10000" ] && echo -e "❴d:$log1❵ $(sed -n '$=' ./keep.txt)—1000_[$(date "+%H:%M:%S")]" >> ./keep.txt && sed -i '1,1000d' ./keep.txt && log1=$(($log1+1))
sleep 120
done
EOF
chmod +x $dirtmp/clash_keep.sh
fi
[ -z "$(ps -w |grep -v grep |grep clash_keep.sh)" ] && echo -e \\n"\e[1;36m▶启动进程守护脚本...\e[0m" && nohup sh $dirtmp/clash_keep.sh >> $dirtmp/keep.txt 2>&1 &
}
stop_keep () {
[ ! -z "$(ps -w |grep -v grep |grep clash_keep.sh)" ] && echo -e \\n"\e[1;36m▷关闭进程守护脚本...\e[0m" && ps -w |grep -v grep |grep clash_keep.sh | awk '{print $1}' | xargs kill -9
}

#状态
status_clash () {
echo -e \\n"\e[36m■查看$name进程：\e[0m"
ps -w |grep -v grep| grep "clash.*-d"
echo -e \\n"\e[36m■查看$name网络监听端口：\e[0m"
netstat -anp | grep clash
#判断是否启动
if [ ! -z "$(ps -w |grep -v grep| grep "clash.*-d")" ] ; then
	if [ ! -z "$(netstat -anp|grep clash)" ] ; then
		logger -t "【$name】" "✔ $name已启动！！" && echo -e \\n"\e[1;36m✔ $name已启动！！\e[0m"\\n
	else
		logger -t "【$name】" "✦ $name进程已启动，但没监听端口..." && echo -e \\n"\e[1;36m✦ $name进程已启动，但没监听端口...\e[0m"
	fi
else
	logger -t "【$name】" "✖ $name进程启动失败，端口无监听，请检查网络问题！！" && echo -e \\n"\e[1;31m✖ $name进程启动失败，端口无监听，请检查网络问题！！\e[0m"
fi
}

#关闭
stop_clash () {
[ ! -z "$(ps -w |grep -v grep| grep "clash.*-d")" ] && logger -t "【$name】" "▷关闭clash..." && echo -e \\n"\e[1;36m▷关闭clash...\e[0m" && ps -w |grep -v grep| grep "clash.*-d" | awk '{print $1}' | xargs kill -9
}
#启动
start_clash () {
[ -f ./clash_log.txt ] && mv -f ./clash_log.txt ./old_clash_log.txt
logger -t "【$name】" "▶启动$name主程序..." && echo -e \\n"\e[1;36m▶启动$name主程序...\e[0m"
if [ "$mode" = "2" ] ; then
	[ -z "$(grep "$user_name" /etc/passwd)" ] && echo "▶添加用戶$user_name，uid為$user_id" && adduser -u $user_id $user_name -D -S -H -s /bin/sh
	su $user_name -c "nohup $dirtmp/clash -d $dirtmp > $dirtmp/clash_log.txt 2>&1 &"
else
	nohup $dirtmp/clash -d $dirtmp > $dirtmp/clash_log.txt 2>&1 &
fi
}

#關閉
stop_0 () {
#transocks_stop
#ipt2socks_stop
#dnsmasq0
stop_iptables
stop_clash
}
#关闭所有
stop_1 () {
stop_0
stop_wan
stop_cron
stop_keep
}

#启动模式0，只启动clash主程序
start_0 () {
#关闭所有
stop_0
#下载文件
down_clash &
down_geoip &
down_web &
down_config &
wait
#编辑配置文件
edit_link
edit_chinalist
edit_dns
edit_adblock
edit_unlocknetease
#启动主程序
start_clash
#查看状态
sleep 2
status_clash
#创建开机自启
start_wan
#创建定时任务
start_cron
#keep进程守护
start_keep
#还原节点记录
start_remark &
}
#启动模式1：iptables透明代理
start_1 () {
start_0
start_iptables && sleep 10 && start_iptables && sleep 10 && start_iptables
}
#启动模式2：iptables透明代理+路由自身走代理
start_2 () {
start_0
start_iptables && sleep 10 && start_iptables && sleep 10 && start_iptables
}

#启动模式3：重启clash + ip2socks透明代理
start_3 () {
start_0
if [ ! -z "$(ps -w | grep -v grep | grep "clash.*-d")" -a ! -z "$(netstat -anp | grep clash)" ] ; then
	ipt2socks_start
else
	logger -t "【$name】" "✘检测到未启动clash进程或端口没监听，取消ipt2socks透明代理" && echo -e \\n"\e[1;31m✘检测到未启动clash进程或端口没监听，取消ipt2socks透明代理\e[0m"\\n
fi
}
#启动模式4：重启clash + transocks透明代理
start_4 () {
start_0
if [ ! -z "$(ps -w | grep -v grep | grep "clash.*-d")" -a ! -z "$(netstat -anp | grep clash)" ] ; then
	transocks_start
else
	logger -t "【$name】" "✘检测到未启动clash进程或端口没监听，取消transocks透明代理" && echo -e \\n"\e[1;31m✘检测到未启动clash进程或端口没监听，取消transocks透明代理\e[0m"\\n
fi
}

#8更新文件
renew () {
startrenew=1
echo -e \\n"\e[1;33m檢查更新文件：\e[0m"\\n
down_clash &
down_geoip &
down_web &
down_config &
wait
echo -e \\n"\e[1;33m...更新完成...\e[0m"\\n
exit
}

remove () {
echo -e \\n"\e[1;33m卸载全部～\e[0m"\\n
stop_1
rm -rf $dirtmp
rm -rf $diretc
rm -rf $dirconf
}


upweb () {
#蓝色主题
filename="clash-dashboard-gh-pages.zip"
filedir="clash-dashboard-gh-pages"
address="https://codeload.github.com/Dreamacro/clash-dashboard/zip/gh-pages"
$curl -sL $address -o $filename
new=$(openssl SHA1 ./$filename |awk '{print $2}')
old=$(awk -F ' ' '/'$filename'/{print $2}' /tmp/SHA1.TXT)
if [ ! -z "$new" -a ! -z "$old" -a "$new" = "$old" ]; then
	echo -e "    ● \e[1;36m clash Web1蓝色主题\e[1;32m✔ \e[0m"
	rm -rf $filename
else
	[ ! -s /opt/bin/unzip ] && opkg install unzip
	[ -d ./$filedir ] && rm -rf ./$filedir
	unzip -o $filename
	tar czvf $filedir.tgz $filedir
	echo -e "    ○ \e[1;36m clash Web1蓝色主题\e[1;31m【需要更新】\e[1;33m文件已下载$filedir.tgz\e[0m"
fi
#暗黑主题
filename="yacd-gh-pages.zip"
filedir="yacd-gh-pages"
address="https://github.com/haishanh/yacd/archive/gh-pages.zip"
$curl -sL $address -o $filename
new=$(openssl sha1 ./$filename |awk '{print $2}')
old=$(awk -F ' ' '/'$filename'/{print $2}' /tmp/SHA1.TXT)
if [ ! -z "$old" -a ! -z "$new" ]; then
	if [ "$new" = "$old" ]; then
		echo -e "    ● \e[1;36m clash Web2暗黑主题\e[1;32m✔ \e[0m"
		rm -rf $filename
	else
		[ ! -s /opt/bin/unzip ] && opkg install unzip
		[ -d ./$filedir ] && rm -rf ./$filedir
		unzip -o $filename
		tar czvf $filedir.tgz $filedir
		echo -e "    ○ \e[1;36m clash Web2暗黑主题\e[1;31m【需要更新】\e[1;33m已下载文件$filedir.tgz \e[0m"
	fi
else
	[ -z "$old" ] && echo -e \\n"\e[1;31m   ✘ $filename旧版本sha1为空。\e[0m"\\n
	[ -z "$new" ] && echo -e \\n"\e[1;31m   ✘ $filename新版本sha1为空。\e[0m"\\n
fi
}
upgeoip () {
filename="Country.mmdb"
address="https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/Country.mmdb"
address2="https://cdn.jsdelivr.net/gh/alecthw/mmdb_china_ip_list@release/Country.mmdb"
echo -e \\n"\e[1;4;36m▶正在检查geoip是否需要更新～\e[0m"
new=$($curl -sL https://raw.githubusercontent.com/alecthw/mmdb_china_ip_list/release/version)
old=$($curl -sL $url/t/Country.mmdb.ver)
if [ ! -z "$old" -a ! -z "$new" ]; then
	if [ "$old" = "$new" ]; then
		echo -e " \e[1;32m✔$filename版本一致，无需更新[$new]！\e[0m"
	else
		echo "$new" > ./$filename.ver
		echo -e " \e[1;33m>> $filename版本不一致，需要更新。new：$new ，old：$old...\e[0m"
		$curl -# -L $address -o ./$filename
		echo -e " \e[1;33m>>创建$filename.tgz新的压缩包...\e[0m"
		tar czvf $filename.tgz $filename && echo -e \\n"\e[32m   ✓ $filename.tgz创建新的压缩包完成！！\e[0m"\\n
	fi
else
	[ -z "$old" ] && echo -e \\n"\e[1;31m   ✘ $filename旧版本ver为空。\e[0m"\\n
	[ -z "$new" ] && echo -e \\n"\e[1;31m   ✘ $filename新版本ver为空。\e[0m"\\n
fi
}
upclash () {
filename="clash"
os="linux-mipsle-softfloat"
echo -e \\n"\e[1;4;36m▶正在检查$filename是否需要更新～\e[0m"
clashp_url=$(curl -s https://tmpclashpremiumbindary.cf | awk -F\" '/'$os'/{print $2}' | sed 's@^@https://tmpclashpremiumbindary.cf/@')
clashp_ver=$(echo $clashp_url | awk -F '-' '{print $NF}' | sed 's/\.gz//')
new=$($curl -sL https://github.com/Dreamacro/clash/releases | grep -Eo "title=\"v.*\">" |head -n1 |awk -F'v' '{print $2}' |sed 's/">//')
old=$($curl -sL $url/t/clash.ver)
address="https://github.com/Dreamacro/clash/releases/download/v$new/clash-$os-v$new.gz"
if [ "$clashp_ver" = "$old" ]; then
	echo -e "  ✔ $filename github版本：\e[1;37m【$new】\e[0m。clashp版本：\e[1;32m【$clashp_ver】\e[0m，旧版本：\e[1;32m【$old】\e[0m，版本一致，无需更新！"
else
	echo -e "   $filename github版本：\e[1;37m【$new】\e[0m。clashp版本：\e[1;32m【$clashp_ver】\e[0m，旧版本：\e[1;33m【$old】\e[0m，正在更新～"
	echo -e \\n"\e[36m▶下载新版$filename主程序压缩包...\e[0m"
	#$curl -# -L $address -o ./clash-$os-v$new.gz
	$curl -# -L $clashp_url -O
	echo -e \\n"\e[36m▶解压$filename压缩包到临时目录...\e[0m"
	gzip -kfd *gz
	chmod +x -R ./
	echo -e \\n"\e[36m▶校验$filename文件...\e[0m"
	#ver=$(./clash-$os-v$new -v | awk '/Clash/{print $2}'|sed 's/v//')
	ver=$(./*$clashp_ver -v | awk '/Clash/{print $2}'|sed 's/v//')
	if [ ! -z "$ver" ] ; then
		if [ "$ver" = "$old" ]; then
			echo -e " ✔ $filename新下载文件版本\e[1;32m【$ver】\e[0m与 旧版本\e[1;32m【$old】\e[0m一致，无需更新。"
			rm -rf ./clash*
		else
			echo "$ver" > ./$filename.ver
			echo -e "\e[32m  >> $filename文件校验通过，版本不一致～\e[0m"
			echo -e "   clash新下载版本：\e[1;32m【$ver】\e[0m，旧版本：\e[1;33m【$old】\e[0m"
		fi
	else
		gzsize=$(ls -lh *.gz | awk -F ' ' '{print $5}')
		size=$(ls -lh *$clashp_ver | awk -F ' ' '{print $5}')
		if [ ! -s ./*$clashp_ver ] ; then
			echo -e "\e[1;31m✖找不到$filename主程序，解压缩文件错误，请手动重新下载。gz压缩包大小【$gzsize】\e[0m"
		else
			echo -e "\e[1;31m✖解压成功，但$filename主程序无法运行，请手动重新下载。gz压缩包大小【$gzsize】，主程序大小【$size】\e[0m"
		fi
		rm -rf ./clash*
	fi
fi
}
up () {
[ ! -d $dirtmp/update ] && mkdir -p $dirtmp/update
cd $dirtmp/update
echo -e \\n"\e[1;32m【1】\e[0m\e[1;36m 更新Web \e[0m"
echo -e "\e[1;32m【2】\e[0m\e[1;36m 更新geoip\e[0m"
echo -e "\e[1;32m【3】\e[0m\e[1;36m 更新clash\e[0m"
echo -e "\e[1;32m【9】\e[0m\e[1;36m 检查更新以上\e[0m"\\n
read -n 1 -p "请输入数字检查更新:" numx
[ "$numx" = "1" ] && upweb &
[ "$numx" = "2" ] && upgeoip &
[ "$numx" = "3" ] && upclash &
if [ "$numx" = "9" ] ; then
upweb
upgeoip
upclash 
fi
}

#状态
zhuangtai () {
echo -e \\n"\e[1;33m当前状态：\e[0m"\\n
if [ -s ./$name ] ; then
	echo -e "★ \e[1;36m $name 版本：\e[1;32m【$(./clash -v|awk '/Clash/{print $2}'|sed 's/v//')】\e[0m"
else
	echo -e "☆ \e[1;36m $name 版本：\e[1;31m【不存在】\e[0m"
fi
if [ -s ./$config ] ; then
	echo -e "★ \e[1;36m $name 配置：\e[1;32m$(cat ./config.yaml | awk -F// '/【/{print $2}')\e[0m"
else
	echo -e "☆ \e[1;36m $name 配置：\e[1;31m【不存在】\e[0m"
fi
if [ ! -z "$(ps -w |grep -v grep| grep "clash.*-d")" ] ; then
	echo -e \\n"● \e[1;36m $name 进程：\e[1;32m【已运行】\e[0m"
else
	echo -e \\n"○ \e[1;36m $name 进程：\e[1;31m【未运行】\e[0m"
fi
if [ ! -z "$(netstat -anp | grep clash)" ] ; then
	echo -e "● \e[1;36m $name 端口：\e[1;32m【已监听】\e[0m"
else
	echo -e "○ \e[1;36m $name 端口：\e[1;31m【未监听】\e[0m"
fi
#
if [ ! -z "$(ps -w |grep -v grep |grep clash_keep.sh)" ] ; then
	echo -e "● \e[1;36m $name 进程守护：\e[1;32m【已运行】\e[0m"
else
	echo -e "○ \e[1;36m $name 进程守护：\e[1;31m【未运行】\e[0m"
fi
if [ ! -z "$(cat $pdcn/START_CRON.SH | grep $name.sh)" ] ; then
	echo -e "● \e[1;36m $name 定时重启：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m $name 定时重启：\e[1;31m【未启用】\e[0m"
fi
if [ ! -z "$(cat $pdcn/START_WAN.SH | grep $name.sh)" ] ; then
	echo -e "● \e[1;36m $name 开机自启：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m $name 开机自启：\e[1;31m【未启用】\e[0m"
fi
pre1=$(iptables -t nat -nL PREROUTING | grep clash | wc -l)
pre2=$(iptables -t nat -nL PREROUTING | grep CLASHDNS | wc -l)
pre3=$(iptables -t mangle -nL PREROUTING | grep clash | wc -l)
out1=$(iptables -t nat -nL OUTPUT | grep CLASHDNS | wc -l)
out2=$(iptables -t nat -nL OUTPUT | grep clash | wc -l)
if [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "0" ] ; then
	iptables_mode=1
elif [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "1" ] ; then
	iptables_mode=2
else
	iptables_mode=0
fi
if [ "$mode" = "1" -a "$iptables_mode" = "1" ] ; then
	echo -e "● \e[1;36m $name 透明代理①：\e[1;32m【已启用】\e[0m"
elif [ "$mode" = "2" -a "$iptables_mode" = "2" ] ; then
	echo -e "● \e[1;36m $name 透明代理②：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m $name 透明代理：\e[1;31m【未启用】\e[0m"
	echo "    mode：$mode，iptables_mode：$iptables_mode，$pre1 $pre2 $pre3 $out1 $out2"
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
#3)
	#start_3 &
	#;;
#4)
	#start_4 &
	#;;
5)
	start_0 &
	;;
6)
	bypass_lan_ip
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
stop_keep)
	stop_keep
	;;
start_keep)
	start_keep
	;;
start_iptables)
	start_iptables
	;;
stop_iptables)
	stop_iptables
	;;
dnsmasq0)
	dnsmasq0
	;;
dnsmasq1)
	dnsmasq1
	;;
transocks_stop)
	transocks_stop
	;;
transocks_start)
	transocks_start
	;;
ipt2socks_stop)
	ipt2socks_stop
	;;
ipt2socks_start)
	ipt2socks_start
	;;
start_remark)
	start_remark
	;;
remark)
	remark
	;;
setmark)
	setmark
	;;
up)
	up
	;;
upweb)
	upweb
	;;
upgeoip)
	upgeoip
	;;
upclash)
	upclash
	;;
*)
	#状态
	zhuangtai
	#
	echo -e \\n"\e[1;33m脚本管理： \e[0m"\\n
	echo -e "\e[1;32m【0】\e[0m\e[1;36m stop：关闭所有 \e[0m "
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start_1：启动clash✚iptables透明代理\e[0m"
	echo -e "\e[1;32m【2】\e[0m\e[1;36m start_2：启动clash✚iptables透明代理✚自身走代理\e[0m"
	#echo -e "\e[1;32m【3】\e[0m\e[1;36m start_3：启动clash✚ip2socks 透明代理\e[0m"
	#echo -e "\e[1;32m【4】\e[0m\e[1;36m start_4：启动clash✚transocks 透明代理 \e[0m"
	echo -e "\e[1;32m【5】\e[0m\e[1;36m start_5：只重启clash\e[0m"
	echo -e "\e[1;32m【6】\e[0m\e[1;36m bypass_lan_ip：局域网IP绕过列表\e[0m"
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
	#elif [ "$num" = "3" ] ; then
		#start_3 &
	#elif [ "$num" = "4" ] ; then
		#start_4 &
	elif [ "$num" = "5" ] ; then
		start_0 &
	elif [ "$num" = "6" ] ; then
		bypass_lan_ip
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