#!/bin/bash
sh_ver=58

path=${0%/*}
bashname=${0##*/}

#程序名字
name=clash
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
#diretc=/etc/storage/pdcn/clash
#diretc=/tmp/clash/etc
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

#iptables设置绕过UID
#创建系统新用户
user_name=${name}
#用户uid/gid
uid=0
gid=20000

#资源文件地址前缀
url1="https://raw.githubusercontent.com/ss916/test/master"
url2="https://cdn.jsdelivr.net/gh/ss916/test"
url3="https://raw.fastgit.org/ss916/test/master"
url4="https://rrr.san99.workers.dev/ss916/test/master"


#alias
run="$dirtmp/${name} -d $dirtmp"
alias pss='ps -w |grep -v grep| grep "$run"'
alias pid='pidof ${name}'
alias port='netstat -anp | grep "${name}"'
alias psskeep='ps -w | grep -v grep |grep "${name}_keep.sh"'
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'
alias log_ok='grep "RESTful API listening at" ./${name}_log.txt'

curl_proxy () {
if [ ! -z "$(pss)" -a ! -z "$(port)" ] ; then
	curl="curl -x 127.0.0.1:8005"
	url=$url1
else
	curl="curl"
	url=$url4
fi
}
curl_proxy
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
echo -e "\e[36m1.启用透明代理（默认）\\n2.透明代理+路由自身走代理\\n3.不启用透明代理\e[0m"
read -n 1 -p "请输入：" mode
echo -e \\n"\e[1;36m↓↓ 請选择DNS模式 ↓↓\e[0m"\\n
echo -e "\e[36m1.redir-host模式（默认）\\n2.fake-dns模式\e[0m"
read -n 1 -p "请输入：" dns
echo -e \\n"\e[1;36m↓↓ 請选择代理模式 ↓↓\e[0m"\\n
echo -e "\e[36m1.gfwlist模式（默认）\\n2.大陆白名单模式\e[0m"
read -n 1 -p "请输入：" chinalist
#功能
echo -e \\n"\e[1;36m↓↓ 請选择是否绕过大陆IP， 大陆IP将不进入${name}↓↓\e[0m"\\n
echo -e "\e[36m0.不启用bypasscnip\\n1.启用bypasscnip\e[0m（默认）"
read -n 1 -p "请输入：" bypasscnip
echo -e \\n"\e[1;36m↓↓ 請选择是否启用去广告功能 ↓↓\e[0m"\\n
echo -e "\e[36m0.不启用adblock（默认）\\n1.启用adblock\e[0m"
read -n 1 -p "请输入：" adblock
echo -e \\n"\e[1;36m↓↓ 請选择网易云解锁 ↓↓\e[0m"\\n
echo -e "\e[36m0.不启用网易云解锁（默认）\\n1.启用网易云解锁\e[0m"
read -n 1 -p "请输入：" unlocknetease
echo -e \\n"\e[1;37m你输入了：	\\n${name}订阅链接1: $link1 \\n${name}订阅链接2: $link2\\n透明代理模式: $mode \\nDNS模式: $dns \\n去广告: $adblock\\n代理模式: $chinalist \\n网易云: $unlocknetease\e[0m"
echo "link1=$link1
link2=$link2
mode=$mode
dns=$dns
chinalist=$chinalist
bypasscnip=$bypasscnip
adblock=$adblock
unlocknetease=$unlocknetease
" > $dirconf/settings.txt
}
#读取参数
read_settings () {
#透明代理模式，mode=1 透明代理（默认），mode=2 透明代理+自身代理，mode=3 不透明代理
mode=$(cat $dirconf/settings.txt |awk -F 'mode=' '/mode=/{print $2}' | head -n 1)
[ -z "$mode" ] && mode=$(cat $dirconf/settings.txt |awk -F 'mode=' '/mode=/{print $2}' | head -n 1) && [ -z "$mode" ] && mode=1 && echo "mode=1" >> $dirconf/settings.txt
#DNS模式，1.redir-host （默认），2.fake-dns
dns=$(cat $dirconf/settings.txt |awk -F 'dns=' '/dns=/{print $2}' | head -n 1)
[ -z "$dns" ] && dns=$(cat $dirconf/settings.txt |awk -F 'dns=' '/dns=/{print $2}' | head -n 1) && [ -z "$dns" ] && dns=1 && echo "dns=1" >> $dirconf/settings.txt
#代理模式，1.gfwlist模式（默认），2.chinalist
chinalist=$(cat $dirconf/settings.txt |awk -F 'chinalist=' '/chinalist=/{print $2}' | head -n 1)
[ -z "$chinalist" ] && chinalist=$(cat $dirconf/settings.txt |awk -F 'chinalist=' '/chinalist=/{print $2}' | head -n 1) && [ -z "$chinalist" ] && chinalist=1 && echo "chinalist=1" >> $dirconf/settings.txt
bypasscnip=$(cat $dirconf/settings.txt |awk -F 'bypasscnip=' '/bypasscnip=/{print $2}' | head -n 1)
[ -z "$bypasscnip" ] && bypasscnip=$(cat $dirconf/settings.txt |awk -F 'bypasscnip=' '/bypasscnip=/{print $2}' | head -n 1) && [ -z "$bypasscnip" ] && bypasscnip=1 && echo "bypasscnip=1" >> $dirconf/settings.txt
#使用自定义配置模板，留空则使用 config=config.yaml （默认）
config=$(cat $dirconf/settings.txt |awk -F 'config=' '/config=/{print $2}' | head -n 1)
[ -z "$config" ] && config=$(cat $dirconf/settings.txt |awk -F 'config=' '/config=/{print $2}' | head -n 1) && [ -z "$config" ] && config=config.yaml && echo "config=config.yaml" >> $dirconf/settings.txt
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
[ -z "$adblock" ] && adblock=$(cat $dirconf/settings.txt |awk -F 'adblock=' '/adblock=/{print $2}' | head -n 1) && [ -z "$adblock" ] && adblock=0 && echo "adblock=0" >> $dirconf/settings.txt
#是否启用网易云解锁，1.unlocknetease启用，0.关闭（默认）
unlocknetease=$(cat $dirconf/settings.txt |awk -F 'unlocknetease=' '/unlocknetease=/{print $2}' | head -n 1)
[ -z "$unlocknetease" ] && unlocknetease=$(cat $dirconf/settings.txt |awk -F 'unlocknetease=' '/unlocknetease=/{print $2}' | head -n 1) && [ -z "$unlocknetease" ] && unlocknetease=0 && echo "unlocknetease=0" >> $dirconf/settings.txt
#是否启用脚本节点记忆与恢复mark，0.关闭（默认，直接使用自带.cache），1.打开
mark=$(cat $dirconf/settings.txt |awk -F 'mark=' '/mark=/{print $2}' | head -n 1)
[ -z "$mark" ] && mark=$(cat $dirconf/settings.txt |awk -F 'mark=' '/mark=/{print $2}' | head -n 1) && [ -z "$mark" ] && mark=0 && echo "mark=0" >> $dirconf/settings.txt
#自定义闪存目录
diretc=$(cat $dirconf/settings.txt |awk -F 'diretc=' '/diretc=/{print $2}' | head -n 1)
[ -z "$diretc" ] && diretc=$(cat $dirconf/settings.txt |awk -F 'diretc=' '/diretc=/{print $2}' | head -n 1) && [ -z "$diretc" ] && diretc=/tmp/$name/etc && echo "diretc=/tmp/$name/etc" >> $dirconf/settings.txt
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
#檢查本地訂閱文件
file1=$dirconf/file1.txt
file2=$dirconf/file2.txt
if [ -f $file1 ] ; then
	testfile1=$(cat $file1|grep "^proxies:$")
	if [ ! -z "$testfile1" ] ; then
		sed -i "s@#mark文件1@  文件1:\n    type: file\n    interval: 30000\n    path: $file1\n    health-check:\n      enable: true\n      interval: 310\n      url: http://clients2.google.com/generate_204@" ./config.yaml
		sed -i 's/#- 文件1/- 文件1/g' ./config.yaml
	else
		[ -z "$testfile1" ] && echo "✗ 本地訂閱文件$file1不合法，缺少字符串【proxies:】"
		sed -i '/文件1/d' ./config.yaml
	fi
else
	sed -i '/文件1/d' ./config.yaml
fi
if [ -f $file2 ] ; then
	testfile2=$(cat $file2|grep "^proxies:$")
	if [ ! -z "$testfile2" ] ; then
		sed -i "s@#mark文件2@  文件2:\n    type: file\n    interval: 30000\n    path: $file2\n    health-check:\n      enable: true\n      interval: 315\n      url: http://clients2.google.com/generate_204@" ./config.yaml
		sed -i 's/#- 文件2/- 文件2/g' ./config.yaml
	else
		[ -z "$testfile2" ] && echo "✗ 本地訂閱文件$file2不合法，缺少字符串【proxies:】"
		sed -i '/文件2/d' ./config.yaml
	fi
else
	sed -i '/文件2/d' ./config.yaml
fi
#检查订阅鏈接
if [ ! -z "$link2" ] ; then
	testlink2=$(echo $link2 | grep ^http)
	if [ ! -z "$testlink2" ] ; then
		sed -i "s@#mark订阅2@  订阅2:\n    type: http\n    url: $link2\n    interval: 30000\n    path: $dirconf/订阅2.txt\n    health-check:\n      enable: true\n      interval: 305\n      url: http://clients1.google.com/generate_204@" ./config.yaml
	else
		[ -z "$testlink2" ] && echo "✗ 订阅链接link2非http链接。"
		sed -i '/订阅2/d' ./config.yaml
	fi
else
	sed -i '/订阅2/d' ./config.yaml
fi
if [ ! -z "$link1" ] ; then
	testlink1=$(echo $link1 | grep ^http)
	if [ ! -z "$testlink1" ] ; then
		sed -i "s@#mark订阅1@  订阅1:\n    type: http\n    url: $link1\n    interval: 30000\n    path: $dirconf/订阅1.txt\n    health-check:\n      enable: true\n      interval: 300\n      url: http://clients1.google.com/generate_204@" ./config.yaml
	else
		[ -z "$testlink1" ] && echo "✗ 订阅链接link1非http链接。"
		sed -i '/订阅1/d' ./config.yaml
	fi
else
	sed -i '/订阅1/d' ./config.yaml
fi
#检验
if [ -z "$link1" -a -z "$link2" -a ! -s $file1 -a ! -s $file2 ] ; then
	echo -e \\n"\e[1;31m【${name}】  ✘ 订阅链接link1与link2為空，本地訂閱文件file1.txt与file2.txt不存在，请初始化配置，結束腳本。\e[0m"
	exit
elif [ -z "$testlink1" -a -z "$testlink2" -a -z "$testfile1" -a -z "$testfile2" ] ; then
	echo -e \\n"\e[1;31m【${name}】  ✘ 订阅链接link1与link2非http鏈接，本地訂閱文件file1.txt与file2.txt不合法，请初始化配置，結束腳本。\e[0m"
	exit
fi
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

#下载文件并解密
#downloadfile address=t/c filename=config.yaml filetgz=c secret=1 password=1+1=1
#下载文件并解压
#downloadfile address=t/Country.mmdb.tgz filename=Country.mmdb filetgz=Country.mmdb.tgz fileout=/tmp
#下载文件
#downloadfile address=t/clash filename=clash filetgz=clash


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
file=Country.mmdb
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	[ -s ./${name}_log.txt ] && [ ! -z "$(grep -o "Can't load mmdb" ./${name}_log.txt)" -o ! -z "$(grep -o "Can't find MMDB" ./${name}_log.txt)" ] && logger -t "【${name}】"  "删除无效$file文件" && echo "  >> 删除无效$file文件 " && rm -rf ./$file && rm -rf $tmp/$file
	downloadfile address=t/$file.tgz filename=$file filetgz=$file.tgz fileout=$tmp
	if [ -s $tmp/$file ] ; then
		[ -f ./$file ] && rm ./$file
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
if [ "$secret" = "1" ] ; then
	downloadfile address=s/$file filename=$file filetgz=$file secret=1 password=$password
else
	downloadfile address=$file filename=$file filetgz=$file
fi
}
#download ipset.cnip.txt
down_ipset_cnip () {
file="ipset.cnip.txt"
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filename=$file filetgz=$file fileout=./
fi
}

setmark () {
config=./config.yaml
secret=$(cat $config | awk '/secret:/{print $2}' | sed 's/"//g')
port=$(cat $config | awk -F: '/external-controller/{print $3}')
curl -s -X GET "http://127.0.0.1:$port/proxies" -H "Authorization: Bearer $secret" | sed 's/\},/\},\n/g'  | grep "Selector" | grep "now" |grep -Eo "name.*" > ./mark/setmark_new.txt
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
	if [ -z "$(echo "$group"  | grep -E '^[A-Za-z0-9]+$')" ] ; then
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
	if [ -z "$(echo "$group"  | grep -E '^[A-Za-z0-9]+$')" ] ; then
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
config=./config.yaml
secret=$(cat $config | awk '/secret:/{print $2}' | sed 's/"//g')
port=$(cat $config | awk -F: '/external-controller/{print $3}')
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
if [ ! -z "$(pss)" -a ! -z "$(port)" -a ! -z "$(grep "RESTful API listening at" ./${name}_log.txt)" ] ; then
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
filename=.cache
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
ipset add localipv6 fc00::/7
ipset add localipv6 fe80::/10
ipset add localipv6 ff00::/8
}

bypass_lan_ip () {
[ ! -f $dirconf/bypasslan.txt ] && > $dirconf/bypasslan.txt
echo -e \\n"\e[1;37m...局域网绕过IP列表$dirconf/bypasslan.txt..\e[0m"
cat $dirconf/bypasslan.txt
echo -e \\n"\e[1;37m.↓↓输入IP地址则添加IP，输入0将重置列表↓↓\e[0m"
read -p "请输入：" lanip
if [ "$lanip" = "0" ] ; then
	> $dirconf/bypasslan.txt
	echo -e \\n"\e[1;37m.已重置IP列表bypasslan.txt。\e[0m"
else
	echo "$lanip" | grep -Eo '([0-9]+\.){3}[0-9]+' >> $dirconf/bypasslan.txt
	sed -i '/^ *$/d' $dirconf/bypasslan.txt
fi
}
onlyallow_lan_ip () {
[ ! -f $dirconf/onlyallowlan.txt ] && > $dirconf/onlyallowlan.txt
echo -e \\n"\e[1;37m...局域网只允许通过代理的IP列表$dirconf/onlyallowlan.txt..\e[0m"
cat $dirconf/onlyallowlan.txt
echo -e \\n"\e[1;37m.↓↓输入IP地址则添加IP，输入0将重置列表↓↓\e[0m"
read -p "请输入：" lanip
if [ "$lanip" = "0" ] ; then
	> $dirconf/onlyallowlan.txt
	echo -e \\n"\e[1;37m.已重置IP列表onlyallowlan.txt。\e[0m"
else
	echo "$lanip" | grep -Eo '([0-9]+\.){3}[0-9]+' >> $dirconf/onlyallowlan.txt
	sed -i '/^ *$/d' $dirconf/onlyallowlan.txt
fi
}
bypasslan () {
#局域网绕过
if [ -s $dirconf/bypasslan.txt ] ; then
	logger -t "【${name}】" "▶添加iptables绕过局域网IP.." && echo -e \\n"\e[1;36m▶添加iptables绕过局域网IP...\e[0m"
	[ ! -z "$(ipset list | grep bypass_lan_ip)" ] && ipset -X bypass_lan_ip
	ipset -N bypass_lan_ip hash:net
	IFS=$'\n'
	for ip in $(cat $dirconf/bypasslan.txt)
	do
		ipset add bypass_lan_ip $ip/32
	done
	iptables -t mangle -I $name -m set --match-set bypass_lan_ip src -j RETURN
fi
}
onlyallowlan () {
#仅局域网IP通过
if [ -s $dirconf/onlyallowlan.txt ] ; then
	logger -t "【${name}】" "▶添加iptables只允许局域网IP通过代理.." && echo -e \\n"\e[1;36m▶添加iptables只允许局域网IP通过代理..\e[0m"
	[ ! -z "$(ipset list | grep onlyallow_lan_ip)" ] && ipset -X onlyallow_lan_ip
	ipset -N onlyallow_lan_ip hash:net
	IFS=$'\n'
	for ip in $(cat $dirconf/onlyallowlan.txt)
	do
		ipset add onlyallow_lan_ip $ip/32
	done
	iptables -t mangle -A PREROUTING -m set --match-set onlyallow_lan_ip src -j $name
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
#判断是否仅允许代理的局域网IP
if [ ! -s $dirconf/onlyallowlan.txt ] ; then
iptables -t mangle -A PREROUTING -j $name
else
onlyallowlan
fi
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
[ -z "$(lsmod | grep xt_TPROXY)" ] && echo "▶加載內核模塊 xt_TPROXY" && modprobe xt_TPROXY
#从配置文件提取参数
config=./config.yaml
if [ -s $config ] ; then
	#提取redir-port透明代理端口
	redir_port=$(cat $config | awk '/redir-port:/{print $2}' | sed 's/"//g')
	#提取tproxy-port透明代理端口
	tproxy_port=$(cat $config | awk '/tproxy-port:/{print $2}' | sed 's/"//g')
	#提取DNS监听端口
	dns_port=$(cat $config | awk -F: '/listen:/{print $NF}')
else
	redir_port=8002
	tproxy_port=8001
	dns_port=5300
fi
##########
logger -t "【${name}】" "▶创建透明代理"
[ -z "$(ipset list | grep localipv4)" ] && ipset_local_ipv4
[ -z "$(ipset list | grep localipv6)" ] && ipset_local_ipv6
##tproxy tcp+udp
tproxy4
tproxy6
##redir dns
redirect_dns
#判断是否绕过cn IP
if [ "$bypasscnip" = "1" ] ; then
	#检查是否存在 ipset cnip表
	if [ -z "$(ipset list | grep cnip)" ] ; then
		ipset_cnip
	else
		ipset_cnip_ok=1
	fi
	if [ "$ipset_cnip_ok" = "1" ] ; then
		logger -t "【${name}】" "▶绕过大陆IP ipset模式：大陆IP不走$name。" && echo -e \\n"\e[1;36m▶绕过大陆IP ipset模式：大陆IP不走$name。\e[0m"\\n
		iptables -t mangle -I $name -m set --match-set cnip dst -j RETURN
	fi
fi
if [ "$mode" = "2" ] ; then
logger -t "【${name}】" "▶创建路由自身走透明代理" && echo -e \\n"\e[1;36m▶创建路由自身走透明代理\e[0m"\\n
tproxy4_out
tproxy6_out
fi
#判断是否绕过局域网ip
bypasslan
##fake-dns
if [ "$dns" = "2" ] ; then
#logger -t "【${name}】" "▶透明代理DNS模式：fake-dns" && echo -e \\n"\e[1;36m▶透明代理DNS模式：fake-dns\e[0m"\\n
echo -e \\n"\e[1;36m暂不提供透明代理DNS模式fake-dns\e[0m"\\n
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
#tproxy tcp+udp
pre1=$(iptables -t mangle -vnL PREROUTING --line-numbers | grep -i $name | wc -l)
pre2=$(ip6tables -t mangle -vnL PREROUTING --line-numbers | grep -i $name | wc -l)
#redir dns
pre3=$(iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp.*dpt:53" | wc -l)
#output DNS
out3=$(iptables -t nat -vnL OUTPUT --line-numbers | grep -Ei "udp.*dpt:53" | wc -l)
#output ipv4
out1=$(iptables -t mangle -vnL OUTPUT --line-numbers | grep -i $name | wc -l)
#output ipv6
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
	if [ ! -z "$(pss)" -a ! -z "$(port)" -a ! -z "$(grep "RESTful API listening at" ./${name}_log.txt)" ] ; then
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
#[ -z "$(cat $pdcn/START_WAN.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▶创建开机自启任务...\e[0m" && echo "sh $pdcn/${name}.sh $mode > $tmp/${name}_start_wan.txt 2>&1 &" >> $pdcn/START_WAN.SH
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
#检查iptables
[ "$mode" = "1" -o "$mode" = "2" ] && start_iptables
}

#进程守护
start_keep () {
if [ ! -s ./${name}_keep.sh ] ; then
echo "▶生成进程守护脚本."
cat > ./${name}_keep.sh << \EOF
#!/bin/sh
name=clash
tmp=/tmp
etc=/etc/storage
dirtmp=$tmp/${name}
pdcn=$etc/pdcn
dirconf=$pdcn/${name}
run="$dirtmp/${name} -d $dirtmp"
alias pss='ps -w |grep -v grep| grep "$run"'
alias pid='pidof ${name}'
alias port='netstat -anp | grep "${name}"'
alias psskeep='ps -w | grep -v grep |grep "${name}_keep.sh"'
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'
mode=$(cat $dirconf/settings.txt |awk -F 'mode=' '/mode=/{print $2}' |head -n 1)
mark=$(cat $dirconf/settings.txt |awk -F 'mark=' '/mark=/{print $2}' |head -n 1)
t=1
m=1
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
#m：检查mark
if [ "$mark" = "1" ] ; then
	sh $pdcn/${name}.sh start_setmark >> ./keep.txt 2>&1 &
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
if [ "$server_port_ok" = "1" -a "$mark_ok" = "1" -a "$tproxy_ok" = "1" ] ; then
	echo -e "$(timenow) ${name} [$v] 进程OK，端口OK，[$t] tproxy OK，[$m] mark OK" >> ./keep.txt
elif [ "$server_port_ok" = "1" -a "$mark_ok" = "1" -a "$tproxy_ok" = "close" ] ; then
	echo -e "$(timenow) ${name} [$v] 进程OK，端口OK，[$m] mark OK" >> ./keep.txt
elif [ "$server_port_ok" = "1" -a "$mark_ok" = "close" -a "$tproxy_ok" = "1" ] ; then
	echo -e "$(timenow) ${name} [$v] 进程OK，端口OK，[$t] tproxy OK" >> ./keep.txt
elif [ "$server_port_ok" = "1" -a "$mark_ok" = "close" -a "$tproxy_ok" = "close" ] ; then
	echo -e "$(timenow) ${name} [$v] 进程OK，端口OK" >> ./keep.txt
fi
#+1
t=$(($t+1))
m=$(($m+1))
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
	else
		logger -t "【${name}】" "✦ ${name}进程已启动，但没监听端口..." && echo -e \\n"\e[1;36m✦ ${name}进程已启动，但没监听端口...\e[0m"
	fi
else
	logger -t "【${name}】" "✖ ${name}进程启动失败，端口无监听，请检查网络问题！！" && echo -e \\n"\e[1;31m✖ ${name}进程启动失败，端口无监听，请检查网络问题！！\e[0m"
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
if [ ! -z "$(pid)" -a ! -z "$(port)" -a ! -z "$(grep "RESTful API listening at" ./${name}_log.txt)" ] ; then
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
[ ! -z "$(pss)" ] && logger -t "【${name}】" "▷关闭${name}..." && echo -e \\n"\e[1;36m▷关闭${name}...\e[0m" && pss | awk '{print $1}' | xargs kill -9 && curl_proxy
}
#启动
start_program () {
[ -f ./${name}_log.txt ] && mv -f ./${name}_log.txt ./old_${name}_log.txt
logger -t "【${name}】" "▶启动${name}主程序..." && echo -e \\n"\e[1;36m▶启动${name}主程序...\e[0m"
#if [ "$mode" = "2" ] ; then
[ -z "$(grep "$user_name" /etc/passwd)" ] && echo "▶添加用戶$user_name，uid为$uid，gid为$gid" && echo "$user_name:x:$uid:$gid:::" >> /etc/passwd
#adduser -u $uid $user_name -D -S -H -s /bin/sh
su $user_name -c "nohup $run > $dirtmp/${name}_log.txt 2>&1 &"
#else
#nohup $run > $dirtmp/${name}_log.txt 2>&1 &
#fi
}

get_config_file () {
config=config.yaml
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
[ "$mode" = "1" -o "$mode" = "2" ] && stop_iptables
stop_program
}
#关闭所有
stop_1 () {
stop_0
stop_wan
stop_cron
stop_keep
}

#启动模式0，只启动主程序
start_0 () {
echo -e \\n"$(timenow)"\\n
#关闭所有
stop_0
#下载文件
get_config_file &
down_program &
down_geoip &
down_web &
[ "$bypasscnip" = "1" ] && down_ipset_cnip &
wait
#编辑配置文件
edit_link
edit_chinalist
edit_dns
edit_adblock
edit_unlocknetease
#检查是否存在cache文件
check_cache_file
#启动主程序
start_program
#等待30秒
check_work_all && waitwork check_work_all 30
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
#启动模式1：iptables透明代理
start_1 () {
[ "$mode" != "1" ] && mode=1 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=1" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && run_restart_keep=1
start_0
if [ "$keep_run_status" = "1" ] ; then
	#keep脚本进程已存在，则立即执行透明代理
	start_iptables && waitwork start_iptables 60 &
else
	echo -e \\n"\e[1;36m◆keep.sh脚本为初始化启动，透明代理只由keep.sh启动。（避免重复加载透明代理规则）\e[0m"
fi
[ "$mark" = "1" ] && start_remark && waitwork start_remark 60
}
#启动模式2：iptables透明代理+路由自身走代理
start_2 () {
[ "$mode" != "2" ] && mode=2 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=2" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && run_restart_keep=1
start_0
if [ "$keep_run_status" = "1" ] ; then
	#keep脚本进程已存在，则立即执行透明代理
	start_iptables && waitwork start_iptables 60 &
else
	echo -e \\n"\e[1;36m◆keep.sh脚本为初始化启动，透明代理只由keep.sh启动。（避免重复加载透明代理规则）\e[0m"
fi
[ "$mark" = "1" ] && start_remark && waitwork start_remark 60
}
#启动模式3：不启用iptables透明代理
start_3 () {
[ "$mode" != "3" ] && mode=3 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=3" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && run_restart_keep=1
[ ! -z "$(iptables -t mangle -vnL PREROUTING --line-numbers | grep -i $name)" ] && ipt0
start_0
}


#8更新文件
renew () {
startrenew=1
echo -e \\n"\e[1;33m檢查更新文件：\e[0m"\\n
down_program &
down_geoip &
down_web &
down_config &
down_ipset_cnip &
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


upweb () {
#蓝色主题
filename="clash-dashboard-gh-pages.zip"
filedir="clash-dashboard-gh-pages"
address="https://codeload.github.com/Dreamacro/clash-dashboard/zip/gh-pages"
$curl -sL $address -o $filename
new=$(openssl SHA1 ./$filename |awk '{print $2}')
old=$(awk -F ' ' '/'$filename'/{print $2}' /tmp/SHA1.TXT)
if [ ! -z "$old" -a ! -z "$new" ]; then
	if [ "$new" = "$old" ]; then
		echo -e \\n"    ● \e[1;36m ${name} Web1蓝色主题\e[1;32m✔ \e[0m"
		rm -rf $filename
	else
		[ ! -s /opt/bin/unzip ] && opkg install unzip
		[ -d ./$filedir ] && rm -rf ./$filedir
		unzip -o $filename
		tar czvf $filedir.tgz $filedir
		echo -e \\n"    ○ \e[1;36m ${name} Web1蓝色主题\e[1;31m【需要更新】 \\n  \e[1;33m文件已下载$filedir.tgz\e[0m"
	fi
else
	[ -z "$old" ] && echo -e \\n"\e[1;31m   ✘ $filename旧版本sha1为空。\e[0m"\\n
	[ -z "$new" ] && echo -e \\n"\e[1;31m   ✘ $filename新版本sha1为空。\e[0m"\\n
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
		echo -e \\n"    ● \e[1;36m ${name} Web2暗黑主题\e[1;32m✔ \e[0m"
		rm -rf $filename
	else
		[ ! -s /opt/bin/unzip ] && opkg install unzip
		[ -d ./$filedir ] && rm -rf ./$filedir
		unzip -o $filename
		tar czvf $filedir.tgz $filedir
		echo -e \\n"    ○ \e[1;36m ${name} Web2暗黑主题\e[1;31m【需要更新】 \\n  \e[1;33m已下载文件$filedir.tgz \e[0m"
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
		echo -e \\n" \e[1;32m✔$filename版本一致，无需更新[$new]\e[0m"
	else
		echo "$new" > ./$filename.ver
		echo -e \\n" \e[1;33m>> $filename版本不一致，需要更新... \\n  new：$new  \\n  old：$old\e[0m"
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
os1="linux-mipsle-hardfloat"
#os2="linux-armv8"
echo -e \\n"\e[1;4;36m▶正在检查$filename是否需要更新～\e[0m"
#tmpclash
#tmpclash_address="https://tmpclashpremiumbindary.cf"
#tmpclash_url1=$($curl -sL $tmpclash_address | awk -F\" '/'$os1'/{print $2}' | sed 's@^@$tmpclash_address/@')
#tmpclash_url2=$(echo $tmpclash_url1 | sed "s/$os1/$os2/")
#tmpclash_ver=$(echo $tmpclash_url1 | awk -F '-' '{print $NF}' | sed 's/\.gz//')
#github
#github_address="https://github.com/Dreamacro/clash"
github_address="https://github.com/Dreamacro/clash/releases/tag/premium"
github_url1=$($curl -sL $github_address | awk -F\" '/releases.*premium.*'$os1'/{print "https://github.com" $2}' | head -n 1)
#github_url2=$(echo $github_url1 | sed "s/$os1/$os2/")
github_ver=$(echo $github_url1 |grep -Eo "$os1.*gz"|awk -F '-' '{print $NF}'|sed 's/.gz//')
#new=$($curl -sL https://github.com/Dreamacro/clash/releases | grep -Eo "title=\"v.*\">" |head -n1 |awk -F'v' '{print $2}' |sed 's/">//')
old=$($curl -sL $url/t/clash.ver)
if [ "$github_ver" = "$old" ]; then
	echo -e \\n"  \e[1;32m✔ $filename 版本一致，无需更新！\e[0m\\n  github版本：\e[1;37m【$github_ver】\e[0m \\n  old 旧版本：\e[1;32m【$old】\e[0m"\\n
else
	echo -e \\n"  $filename 正在更新... \\n  github版本：\e[1;37m【$github_ver】\e[0m \\n  old 旧版本：\e[1;33m【$old】\e[0m"\\n
	echo -e \\n"\e[36m▶下载新版$filename主程序压缩包...\e[0m"
	#$curl -# -LO $github_url2 &
	$curl -# -LO $github_url1
	echo -e \\n"\e[36m▶解压$filename压缩包到临时目录...\e[0m"
	#gzip -kfd *$os2*gz &
	gzip -kfd *$os1*gz
	chmod +x -R ./
	echo -e \\n"\e[36m▶校验$filename文件...\e[0m"
	ver=$(./*$os1*$github_ver -v | awk '/Clash/{print $2}'|sed 's/v//')
	if [ ! -z "$ver" ] ; then
		if [ "$ver" = "$old" ]; then
			echo -e " ✔ $filename新下载文件版本\e[1;32m【$ver】\e[0m与 旧版本\e[1;32m【$old】\e[0m一致，无需更新。"
			rm -rf ./clash*
		else
			echo "$ver" > ./$filename.ver
			echo -e "\e[32m  >> $filename文件校验通过，版本不一致～\e[0m"
			echo -e "   clash新下载版本：\e[1;32m【$ver】\e[0m，旧版本：\e[1;33m【$old】\e[0m"
			echo "$ver" >  ./clash.ver
			echo -e " \e[1;33m>>upx压缩$filename...\e[0m"
			if [ -z "`upx -V`" ] ; then
				echo -e "  >> 检测到opt需要安装upx～"
				[ ! -z "$(ps -w | grep -v grep | grep "clash.*-d")" -a ! -z "$(netstat -anp | grep clash)" ] && echo "走clash本地http代理更新opt upx" && export http_proxy=http://127.0.0.1:8005 && export https_proxy=http://127.0.0.1:8005
				opkg update && opkg install upx
			fi
			[ -s ./$filename ] && rm ./$filename
			upx --brute *$os1*$github_ver -o $filename && echo -e \\n"\e[32m   ✓ $filename upx压缩完成！！\e[0m"\\n &
		fi
	else
		gzsize=$(ls -lh *$os1*$github_ver.gz | awk -F ' ' '{print $5}')
		size=$(ls -lh *$os1*$github_ver | awk -F ' ' '{print $5}')
		if [ ! -s ./*$os1*$github_ver ] ; then
			echo -e "\e[1;31m✖找不到$filename主程序，解压缩文件错误，请手动重新下载。gz压缩包大小【$gzsize】\e[0m"
		else
			echo -e "\e[1;31m✖解压成功，但$filename主程序无法运行，请手动重新下载。gz压缩包大小【$gzsize】，主程序大小【$size】\e[0m"
		fi
		rm -rf ./clash*
	fi
fi
}
upcnip () {
#生成ipset cnip 
filename="cnip.txt"
address="https://ftp.apnic.net/stats/apnic/delegated-apnic-latest"
echo -e \\n"\e[1;4;36m▶正在检查$filename是否需要更新～\e[0m"
$curl -sL $address -o cnip_delegated-apnic-latest
cat cnip_delegated-apnic-latest | awk -F '|' '/CN/&&/ipv4/ {print $4 "/" 32-log($5)/log(2)}' | sort -n > $filename
new=$(openssl sha1 ./$filename |awk '{print $2}')
old=$(awk -F ' ' '/\/'$filename'/{print $2}' /tmp/SHA1.TXT)
if [ ! -z "$old" -a ! -z "$new" ]; then
	if [ "$new" = "$old" ]; then
		echo -e \\n"    ● \e[1;36m ${filename} 文件对比一致，无需更新\e[1;32m✔ \e[0m"
		rm -rf $filename cnip_delegated-apnic-latest
	else
		[ ! -z "$(ipset list | grep cnip)" ] && ipset -X cnip
		#创建ipset表
		ipset -N cnip hash:net
		#添加cn IP到cnip表
		for ip in $(cat $filename) ; do ipset add cnip $ip ; done
		#保存ipset表cnip
		ipset save cnip -f ipset.cnip.txt
		sort -nr ipset.cnip.txt -o ipset.cnip.txt
		echo -e \\n"    ○ \e[1;36m ${filename} \e[1;31m【需要更新】 \\n  \e[1;33m已生成文件ipset.cnip.txt ，行数$(sed -n '$=' ipset.cnip.txt)\e[0m"
	fi
else
	[ -z "$old" ] && echo -e \\n"\e[1;31m   ✘ $filename旧版本sha1为空。\e[0m"\\n
	[ -z "$new" ] && echo -e \\n"\e[1;31m   ✘ $filename新版本sha1为空。\e[0m"\\n
fi
}
up_all () {
echo -e \\n"\e[1;36m......▼开始检查更新所有▼......\e[0m "\\n
upweb &
upgeoip &
upclash &
upcnip &
wait
echo -e \\n"\e[1;32m......▲完成检查更新所有▲......\e[0m "\\n
}
up () {
[ ! -d ./update ] && mkdir -p ./update
cd ./update
echo -e \\n"\e[1;32m【1】\e[0m\e[1;36m 更新Web \e[0m"
echo -e "\e[1;32m【2】\e[0m\e[1;36m 更新geoip\e[0m"
echo -e "\e[1;32m【3】\e[0m\e[1;36m 更新clash\e[0m"
echo -e "\e[1;32m【4】\e[0m\e[1;36m 更新ipset cnip\e[0m"
echo -e "\e[1;33m【9】 检查更新所有\e[0m"\\n
read -n 1 -p "请输入数字检查更新:" numx
[ "$numx" = "1" ] && upweb &
[ "$numx" = "2" ] && upgeoip &
[ "$numx" = "3" ] && upclash &
[ "$numx" = "4" ] && upcnip &
[ "$numx" = "9" ] && up_all &
}

#状态
zhuangtai () {
echo -e \\n"\e[1;33m当前状态：\e[0m"\\n
if [ -s ./${name} ] ; then
	echo -e "★ \e[1;36m ${name} 版本：\e[1;32m【$(./${name} -v |grep -i $name | awk '{print $2}'|sed 's/v//')】\e[0m"
else
	echo -e "☆ \e[1;36m ${name} 版本：\e[1;31m【不存在】\e[0m"
fi
if [ -s $tmp/$config ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat $tmp/$config | awk -F// '/【/{print $2}')\e[0m临时"
elif [ -s $dirconf/$config ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat $dirconf/$config | awk -F// '/【/{print $2}')\e[0m闪存"
elif [ -s ./$config ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat ./config.yaml | awk -F// '/【/{print $2}')\e[0m"
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
	echo -e "● \e[1;36m ${name} 透明代理①：\e[1;32m【已启用】\e[0m"
elif [ "$mode" = "2" -a "$iptables_mode" = "2" ] ; then
	echo -e "● \e[1;36m ${name} 透明代理②：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 透明代理：\e[1;31m【未启用】\e[0m"
	echo "    mode：$mode，iptables_mode：$iptables_mode，$pre1 $pre2 $pre3 $out3 $out1 $out2"
	[ "$pre3" != "0" ] && iptables -t nat -vnL PREROUTING --line-numbers | grep -Ei "udp.*dpt:53"
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
5)
	onlyallow_lan_ip
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
upcnip)
	upcnip
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
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start_1：启动${name} ✚ tproxy透明代理\e[0m"
	echo -e "\e[1;32m【2】\e[0m\e[1;36m start_2：启动${name} ✚ tproxy透明代理 ✚ 自身走代理\e[0m"
	echo -e "\e[1;32m【3】\e[0m\e[1;36m start_3：仅启动${name}\e[0m"
	echo -e "\e[1;32m【5】\e[0m\e[1;36m onlyallow_lan_ip：仅允许通过代理的局域网IP列表\e[0m"
	echo -e "\e[1;32m【6】\e[0m\e[1;36m bypass_lan_ip：局域网绕过代理IP列表\e[0m"
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
	elif [ "$num" = "5" ] ; then
		onlyallow_lan_ip
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