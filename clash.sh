#!/bin/sh
sh_ver=28

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
#用户UID
user_id=998

#资源文件地址前缀
url1="https://raw.githubusercontent.com/ss916/test/master"
url2="https://cdn.jsdelivr.net/gh/ss916/test"
url3="https://raw.fastgit.org/ss916/test/master"


#alias
run="$dirtmp/${name} -d $dirtmp"
alias pss='ps -w |grep -v grep| grep "$run"'
alias port='netstat -anp | grep "${name}"'
alias psskeep='ps -w | grep -v grep |grep "${name}_keep.sh"'
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'

curl_proxy () {
if [ ! -z "$(pss)" -a ! -z "$(port)" ] ; then
	curl="curl -x 127.0.0.1:8005"
	url=$url1
else
	curl="curl"
	url=$url3
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
echo -e \\n"\e[1;36m↓↓ 請选择是否绕过大陆IP， 大陆IP将不进入clash↓↓\e[0m"\\n
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
[ -z "$mode" ] && mode=1 && echo "mode=1" >> $dirconf/settings.txt
#DNS模式，1.redir-host （默认），2.fake-dns
dns=$(cat $dirconf/settings.txt |awk -F 'dns=' '/dns=/{print $2}' | head -n 1)
[ -z "$dns" ] && dns=1 && echo "dns=1" >> $dirconf/settings.txt
#代理模式，1.gfwlist模式（默认），2.chinalist
chinalist=$(cat $dirconf/settings.txt |awk -F 'chinalist=' '/chinalist=/{print $2}' | head -n 1)
[ -z "$chinalist" ] && chinalist=1 && echo "chinalist=1" >> $dirconf/settings.txt
bypasscnip=$(cat $dirconf/settings.txt |awk -F 'bypasscnip=' '/bypasscnip=/{print $2}' | head -n 1)
[ -z "$bypasscnip" ] && bypasscnip=1 && echo "bypasscnip=1" >> $dirconf/settings.txt
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
[ -z "$diretc" ] && diretc=/tmp/$name/etc && echo "diretc=/tmp/$name/etc" >> $dirconf/settings.txt
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
		sed -i "s@#mark文件1@  文件1:\n    type: file\n    interval: 30000\n    path: $file1\n    health-check:\n      enable: true\n      interval: 300\n      url: http://clients2.google.com/generate_204@" ./config.yaml
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
		sed -i "s@#mark文件2@  文件2:\n    type: file\n    interval: 30000\n    path: $file2\n    health-check:\n      enable: true\n      interval: 300\n      url: http://clients2.google.com/generate_204@" ./config.yaml
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
		sed -i "s@#mark订阅2@  订阅2:\n    type: http\n    url: $link2\n    interval: 30000\n    path: $dirconf/订阅2.txt\n    health-check:\n      enable: true\n      interval: 300\n      url: http://clients1.google.com/generate_204@" ./config.yaml
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
	echo -e \\n"\e[36m▶下载校验文件SHA1.TXT......\e[0m"
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
	logger -t "【$filename】" "▷github下载文件$filetgz..." && echo -e \\n"\e[1;7;37m▷『$filename』github下载文件$filetgz...\e[0m"
	[ ! -z "$(ps -w | grep -v grep | grep "curl.*$filetgz")" ] && echo "！已存在curl下載$filetgz進程，先kill。" && ps -w | grep "curl.*$filetgz" | grep -v grep | awk '{print $1}' | xargs kill -9
	$curl -# -L $link -o ./$filetgz
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
	[ -s ./clash_log.txt ] && [ ! -z "$(grep -o "Can't load mmdb" ./clash_log.txt)" -o ! -z "$(grep -o "Can't find MMDB" ./clash_log.txt)" ] && logger -t "【${name}】"  "删除无效$file文件" && echo "  >> 删除无效$file文件 " && rm -rf ./$file && rm -rf $tmp/$file
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
if [ -s $tmp/config.yaml -o -s $dirconf/config.yaml ] ; then
	if [ -s $tmp/config.yaml ] ; then
		cp -f $tmp/config.yaml ./config.yaml
		ver=$(cat ./config.yaml | awk -F// '/【/{print $2}')
		logger -t "【${name}】" "▶进入测试模式，使用本地配置文件$file，版本$ver" && echo -e \\n"\e[1;36m▶进入测试模式，使用本地配置文件。\\n    $file\e[0m\e[1;32m$ver\e[0m"
	elif [ -s $dirconf/config.yaml ] ; then
		cp -f $dirconf/config.yaml ./config.yaml
		ver=$(cat ./config.yaml | awk -F// '/【/{print $2}')
		logger -t "【${name}】" "▶使用闪存配置文件$dirconf/config.yaml，版本$ver" && echo -e \\n"\e[36m▶使用本地配置文件$dirconf/config.yaml，版本$ver \e[0m"
	fi
else
	#if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=$file filename=$file filetgz=$file
	#fi
fi
}
#download ipset.cnip.txt
down_ipset_cnip () {
file="ipset.cnip.txt"
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filename=$file filetgz=$file fileout=./
fi
}

#transocks
transocks_stop () {
[ ! -z "$(ps -w | grep -v grep | grep tran)" ] && logger -t "【${name}】" "▷检测到transocks正在运行，先stop..." && echo -e \\n"\e[1;33m▷检测到transocks正在运行，先stop...\e[0m" && nvram set app_27=0 && /etc/storage/script/Sh58_tran_socks.sh stop
[ ! -z "$(ps -w | grep -v grep | grep chinadns)" ] && nvram set app_1=0 && /etc/storage/script/Sh19_chinadns.sh stop
}
transocks_start () {
logger -t "【${name}】" "▶启动transocks透明代理..." && echo -e \\n"\e[1;33m▶启动transocks透明代理......\e[0m"
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
[ ! -z "$(ps -w | grep -v grep | grep ipt2socks)" ] && logger -t "【${name}】" "▷检测到ipt2socks正在运行，先stop..." && echo -e \\n"\e[1;33m▷检测到ipt2socks正在运行，先stop...\e[0m" && nvram set app_104=0 && /etc/storage/script/Sh39_ipt2socks.sh stop
[ ! -z "$(ps -w | grep -v grep | grep chinadns)" ] && nvram set app_1=0 && /etc/storage/script/Sh19_chinadns.sh stop
}
ipt2socks_start () {
logger -t "【${name}】" "▶启动ipt2socks透明代理..." && echo -e \\n"\e[1;33m▶启动ipt2socks透明代理......\e[0m"
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
if [ ! -z "$(pss)" -a ! -z "$(port)" -a ! -z "$(grep "RESTful API listening at" ./clash_log.txt)" ] ; then
	remark
	[ -f ./mark/start_remark_ok_* ] && rm ./mark/start_remark_ok_*
	> ./mark/start_remark_ok_1
else
	echo "    ✖ start_remark：${name}进程或端口没启动成功，跳过还原节点记录。"
	[ -f ./mark/start_remark_ok_* ] && rm ./mark/start_remark_ok_*
	> ./mark/start_remark_ok_0
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
	iptables -t mangle -I clash -m set --match-set bypass_lan_ip src -j RETURN
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
	iptables -t mangle -A PREROUTING -p udp ! --dport 53 -m set --match-set onlyallow_lan_ip src -j clash
	iptables -t mangle -A PREROUTING -p tcp -m set --match-set onlyallow_lan_ip src -j clash
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


iptables_tcp () {
#redir TCP
iptables -t nat -N clash >/dev/null 2>&1
iptables -t nat -F clash
iptables -t nat -A clash -m set --match-set localipv4 dst -j RETURN
#iptables -t nat -A clash -d 0.0.0.0/8 -j RETURN
#iptables -t nat -A clash -d 10.0.0.0/8 -j RETURN
#iptables -t nat -A clash -d 127.0.0.0/8 -j RETURN
#iptables -t nat -A clash -d 169.254.0.0/16 -j RETURN
#iptables -t nat -A clash -d 172.16.0.0/12 -j RETURN
#iptables -t nat -A clash -d 192.168.0.0/16 -j RETURN
#iptables -t nat -A clash -d 224.0.0.0/4 -j RETURN
#iptables -t nat -A clash -d 240.0.0.0/4 -j RETURN
iptables -t nat -A clash -p tcp -j REDIRECT --to-port "$redir_port"
iptables -t nat -I PREROUTING -p tcp -j clash
}
iptables_udp () {
#tproxy udp
ip rule add fwmark 1 table 100
ip route add local default dev lo table 100
iptables -t mangle -N clash >/dev/null 2>&1
iptables -t mangle -F clash
iptables -t mangle -A clash -m set --match-set localipv4 dst -j RETURN
iptables -t mangle -A clash -p udp -j TPROXY --on-port "$redir_port" --tproxy-mark 1
iptables -t mangle -A PREROUTING -p udp ! --dport 53 -j clash
}

iptables_tproxy () {
#tproxy tcp+udp
ip rule add fwmark 1 table 100
ip route add local default dev lo table 100
iptables -t mangle -N clash >/dev/null 2>&1
iptables -t mangle -F clash
iptables -t mangle -A clash -m set --match-set localipv4 dst -j RETURN
iptables -t mangle -I clash -m mark --mark 0xff -j RETURN
iptables -t mangle -A clash -p tcp -j TPROXY --on-port "$tproxy_port" --tproxy-mark 1
iptables -t mangle -A clash -p udp -j TPROXY --on-port "$tproxy_port" --tproxy-mark 1
#判断是否仅允许代理的局域网IP
if [ ! -s $dirconf/onlyallowlan.txt ] ; then
	iptables -t mangle -A PREROUTING -p udp ! --dport 53 -j clash
	iptables -t mangle -A PREROUTING -p tcp -j clash
else
	onlyallowlan
fi
}
iptables_tproxy_output () {
#tproxy代理自身clash_mark
iptables -t mangle -N clash_mark >/dev/null 2>&1
iptables -t mangle -F clash_mark
iptables -t mangle -A clash_mark -d 224.0.0.0/4 -j RETURN 
iptables -t mangle -A clash_mark -d 255.255.255.255/32 -j RETURN 
iptables -t mangle -A clash_mark -d 192.168.0.0/16 -p tcp -j RETURN # 直连局域网
iptables -t mangle -A clash_mark -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN # 直连局域网，53 端口除外（因为要使用 V2Ray 的 DNS）
iptables -t mangle -I clash_mark -m mark --mark 0xff -j RETURN    # 直连 SO_MARK 为 0xff 的流量(0xff 是 16 进制数，数值上等同与上面V2Ray 配置的 255)，此规则目的是避免代理本机(网关)流量出现回环问题
iptables -t mangle -A clash_mark -p udp -j MARK --set-mark 1   # 给 UDP 打标记,重路由
iptables -t mangle -A clash_mark -p tcp -j MARK --set-mark 1   # 给 TCP 打标记，重路由
iptables -t mangle -A OUTPUT -j clash_mark # 应用规则
}

iptables_dns () {
#DNS流量
iptables -t nat -N CLASHDNS >/dev/null 2>&1
iptables -t nat -F CLASHDNS
iptables -t nat -A CLASHDNS -p udp -j REDIRECT --to-ports "$dns_port"
iptables -t nat -I PREROUTING -p udp --dport 53 -j CLASHDNS
#路由自身UDP53走代理
iptables -t nat -A OUTPUT -m owner ! --uid-owner "$user_id" -p udp --dport 53 -j CLASHDNS
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
logger -t "【${name}】" "▶创建局域网透明代理" && echo -e \\n"\e[1;36m▶创建局域网透明代理\e[0m"\\n
[ -z "$(ipset list | grep localipv4)" ] && ipset_local_ipv4
[ -z "$(ipset list | grep localipv6)" ] && ipset_local_ipv6
##redir tcp + tproxy udp
#iptables_tcp
#iptables_udp
##tproxy tcp+udp
iptables_tproxy
##redir dns
iptables_dns
##fake-dns
#判断是否绕过cn IP
if [ "$bypasscnip" = "1" ] ; then
	#检查是否存在 ipset cnip表
	if [ -z "$(ipset list | grep cnip)" ] ; then
		ipset_cnip
	else
		ipset_cnip_ok=1
	fi
	if [ "$ipset_cnip_ok" = "1" ] ; then
		logger -t "【${name}】" "▶绕过大陆IP ipset模式：大陆IP不走clash。" && echo -e \\n"\e[1;36m▶绕过大陆IP ipset模式：大陆IP不走clash。\e[0m"\\n
		iptables -t mangle -I clash -m set --match-set cnip dst -j RETURN
	fi
fi
if [ "$dns" = "2" ] ; then
logger -t "【${name}】" "▶透明代理DNS模式：fake-dns" && echo -e \\n"\e[1;36m▶透明代理DNS模式：fake-dns\e[0m"\\n
iptables -t nat -A OUTPUT -p tcp -d 198.18.0.0/16 -s 127.0.0.1/32 -j REDIRECT --to-port "$redir_port"
fi
if [ "$mode" = "2" ] ; then
logger -t "【${name}】" "▶创建路由自身走透明代理" && echo -e \\n"\e[1;36m▶创建路由自身走透明代理\e[0m"\\n
iptables -t nat -I OUTPUT -m owner ! --uid-owner "$user_id" -p tcp -j clash
#iptables_tproxy_output
fi
#判断是否绕过局域网ip
bypasslan
}

ipt0_redir () {
[ ! -z "$(iptables -t nat -nL PREROUTING | grep clash)" ] && iptables -t nat -D PREROUTING -p tcp -j clash
ip rule del fwmark 1 table 100 >/dev/null 2>&1
ip route del local default dev lo table 100 >/dev/null 2>&1
[ ! -z "$(iptables -t mangle -nL PREROUTING | grep clash)" ] && iptables -t mangle -D PREROUTING -p udp ! --dport 53 -j clash
[ ! -z "$(iptables -t nat -nL OUTPUT | grep clash)" ] && iptables -t nat -D OUTPUT -m owner ! --uid-owner "$user_id" -p tcp -j clash
}
ipt0_tproxy () {
ip rule del fwmark 1 table 100 >/dev/null 2>&1
ip route del local default dev lo table 100 >/dev/null 2>&1
if [ ! -z "$(iptables -t mangle -nL PREROUTING | grep clash | grep udp)" ] ; then
	iptables -t mangle -D PREROUTING -p udp ! --dport 53 -j clash >/dev/null 2>&1
	iptables -t mangle -D PREROUTING -p udp ! --dport 53 -m set --match-set allow_lan_ip src -j clash >/dev/null 2>&1
fi
if [ ! -z "$(iptables -t mangle -nL PREROUTING | grep clash | grep tcp)" ] ; then
	iptables -t mangle -D PREROUTING -p tcp -j clash >/dev/null 2>&1
	iptables -t mangle -D PREROUTING -p tcp -m set --match-set allow_lan_ip src -j clash >/dev/null 2>&1
fi
[ ! -z "$(iptables -t mangle -nL OUTPUT | grep clash_mark)" ] && iptables -t mangle -D OUTPUT -j clash_mark
}
ipt0_dns () {
[ ! -z "$(iptables -t nat -nL PREROUTING | grep CLASHDNS)" ] && iptables -t nat -D PREROUTING -p udp --dport 53 -j CLASHDNS
[ ! -z "$(iptables -t nat -nL OUTPUT | grep CLASHDNS)" ] && iptables -t nat -D OUTPUT -m owner ! --uid-owner "$user_id" -p udp --dport 53 -j CLASHDNS
}

ipt0 () {
logger -t "【${name}】" "▷删除透明代理iptables规则" && echo -e \\n"\e[1;36m▷删除透明代理iptables规则\e[0m"\\n
#ipt0_redir
ipt0_tproxy
ipt0_dns
}
stop_iptables () {
ipt0
}

start_iptables () {
#tproxy tcp+udp
pre1=$(iptables -t mangle -nL PREROUTING | grep clash | grep udp | wc -l)
pre2=$(iptables -t mangle -nL PREROUTING | grep clash | grep tcp | wc -l)
#redir dns
pre3=$(iptables -t nat -nL PREROUTING | grep CLASHDNS | wc -l)
#output dns
out1=$(iptables -t nat -nL OUTPUT | grep CLASHDNS | wc -l)
#output clash_mark
out2=$(iptables -t nat -nL OUTPUT | grep clash_mark | wc -l)
if [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "0" ] ; then
	iptables_mode=1
elif [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "1" ] ; then
	iptables_mode=2
else
	iptables_mode=0
fi
if [ "$mode" = "1" -a "$iptables_mode" = "1" ] ; then
	echo "    ✓ start_iptables：${name}当前模式mode 1，iptables mode 1，iptables规则正常，跳过设置。"
elif [ "$mode" = "2" -a "$iptables_mode" = "2" ] ; then
	echo "    ✓ start_iptables：${name}当前模式mode 2，iptables mode 2，iptables规则正常，跳过设置。"
else
	#删除iptables规则
	[ "$pre1" != "0" ] && ipt0
	[ "$pre2" != "0" ] && ipt0
	[ "$pre3" != "0" ] && ipt0
	[ "$out1" != "0" ] && ipt0
	[ "$out2" != "0" ] && ipt0
	if [ ! -z "$(pss)" -a ! -z "$(port)" -a ! -z "$(grep "RESTful API listening at" ./clash_log.txt)" ] ; then
		ipt1
		[ -f ./start_iptables_* ] && rm ./start_iptables_*
		> ./start_iptables_1
	else
		echo "    ✖ start_iptables：${name}进程或端口没启动成功，跳过设置透明代理。"
		[ -f ./start_iptables_* ] && rm ./start_iptables_*
		> ./start_iptables_0
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
[ -f $pdcn/START_WAN.SH -a ! -z "$(cat $pdcn/START_WAN.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▷删除开机自启任务...\e[0m" && sed -i "/${name}.sh/d" $pdcn/START_WAN.SH
}
start_wan () {
[ -z "$(cat $file_wan | grep START_WAN.SH)" ] && echo "sh $pdcn/START_WAN.SH &" >> $file_wan
[ ! -f $pdcn/START_WAN.SH ] && > $pdcn/START_WAN.SH
#[ -z "$(cat $pdcn/START_WAN.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▶创建开机自启任务...\e[0m" && echo "sh $pdcn/${name}.sh $mode > $tmp/${name}_start_wan.txt &" >> $pdcn/START_WAN.SH
[ -z "$(cat $pdcn/START_WAN.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▶创建开机自启任务...\e[0m" && echo "sh $pdcn/${name}.sh restart > $tmp/${name}_start_wan.txt &" >> $pdcn/START_WAN.SH
}

#定时任务
stop_cron () {
[ -f $pdcn/START_CRON.SH -a ! -z "$(cat $pdcn/START_CRON.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▷删除定时任务crontab...\e[0m" && sed -i "/${name}.sh/d" $pdcn/START_CRON.SH
}
start_cron () {
[ -z "$(cat $file_cron | grep START_CRON.SH)" ] && echo "1 5 * * * sh $pdcn/START_CRON.SH &" >> $file_cron
[ ! -f $pdcn/START_CRON.SH ] && > $pdcn/START_CRON.SH
[ -z "$(cat $pdcn/START_CRON.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▶创建定时任务crontab...\e[0m" && echo "sh $pdcn/${name}.sh $mode > $tmp/${name}_start_cron.txt &" >> $pdcn/START_CRON.SH
#[ -z "$(cat $pdcn/START_CRON.SH | grep ${name}.sh)" ] && echo -e \\n"\e[1;36m▶创建定时任务crontab...\e[0m" && echo "sh $pdcn/${name}.sh restart > $tmp/${name}_start_cron.txt &" >> $pdcn/START_CRON.SH
}

restart () {
#检查进程端口
if [ "$(pss | wc -l)" != "1" -o "$(psskeep | wc -l)" != "1" ] ; then
	sh $pdcn/${name}.sh $mode &
else
	echo -e \\n"$(timenow) ✓ restart：${name}进程与${name}_keep.sh进程守护已运行，无需重启。"\\n
fi
#检查iptables
start_iptables
}

#进程守护
start_keep () {
if [ ! -s ./${name}_keep.sh ] ; then
echo "▶生成进程守护脚本."
cat > ./${name}_keep.sh << \EOF
#!/bin/sh
name=clash
dirtmp=/tmp/clash
etc=/etc/storage/pdcn
mode=$(cat $etc/${name}/settings.txt |awk -F 'mode=' '/mode=/{print $2}' |head -n 1)
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'
cd $dirtmp
v=1
w=1
a=1
log1=1
while true ; do
#检查进程与端口
server=$(ps -w | grep -v grep |grep "${name} -d $dirtmp" |wc -l)
port=$(netstat -anp | grep ${name})
pre1=$(iptables -t mangle -nL PREROUTING | grep clash | grep udp | wc -l)
pre2=$(iptables -t mangle -nL PREROUTING | grep clash | grep tcp | wc -l)
pre3=$(iptables -t nat -nL PREROUTING | grep CLASHDNS | wc -l)
out1=$(iptables -t nat -nL OUTPUT | grep CLASHDNS | wc -l)
out2=$(iptables -t nat -nL OUTPUT | grep clash_mark | wc -l)
if [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "0" ] ; then
	iptables_mode=1
elif [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "1" ] ; then
	iptables_mode=2
else
	iptables_mode=0
fi
if [ "$mode" = "1" -o "$mode" = "2" ] ; then
	if [ "$server" != "1" -o -z "$port" ] ; then
		if [ "$server" = "0" ] ; then
			echo -e "$(timenow) [$v]检测${name}进程不存在，重启程序！" >> ./keep.txt
		elif [ "$server" -gt "1" ] ; then
			echo -e "$(timenow) [$v]检测${name}进程重复 x $server，重启程序！" >> ./keep.txt
		fi
		[ -z "$port" ] && echo -e "$(timenow) [$v]检测${name}端口没监听，重启程序！" >> ./keep.txt
		nohup sh $etc/${name}.sh $mode >> ./keep.txt 2>&1 &
		v=0
	elif [ "$mode" = "1" -a "$iptables_mode" != "1" ] ; then
		echo -e "$(timenow) [$w]检测${name}需要重置iptables规则1！" >> ./keep.txt
		echo "mode：$mode ， iptables_mode：$iptables_mode，$pre1 $pre2 $pre3 $out1 $out2" >> ./keep.txt
		sh $etc/${name}.sh start_iptables &
		w=0
	elif [ "$mode" = "2" -a "$iptables_mode" != "2" ] ; then
		echo -e "$(timenow) [$w]检测${name}需要重置iptables规则2！" >> ./keep.txt
		echo "mode：$mode ， iptables_mode：$iptables_mode，$pre1 $pre2 $pre3 $out1 $out2" >> ./keep.txt
		sh $etc/${name}.sh start_iptables &
		w=0
	else
		sh $etc/${name}.sh start_setmark
		[ -f ./mark/setmark_ok_0 ] && a=0
		echo -e "$(timenow) ${name} [$v] 进程OK，端口OK，[$w] iptables $iptables_mode OK，[$a] setmark OK" >> ./keep.txt
	fi
else
	if [ "$server" != "1" -o -z "$port" ] ; then
		if [ "$server" = "0" ] ; then
			echo -e "$(timenow) [$v]检测${name}进程不存在，重启程序！" >> ./keep.txt
		elif [ "$server" -gt "1" ] ; then
			echo -e "$(timenow) [$v]检测${name}进程重复 x $server，重启程序！" >> ./keep.txt
		fi
		[ -z "$port" ] && echo -e "$(timenow) [$v]检测${name}端口没监听，重启程序！" >> ./keep.txt
		nohup sh $etc/${name}.sh $mode >> ./keep.txt 2>&1 &
		v=0
	else
		sh $etc/${name}.sh start_setmark
		[ -f ./mark/setmark_ok_0 ] && a=0
		echo -e "$(timenow) ${name} [$v] 进程OK，端口OK，[$a] setmark OK" >> ./keep.txt
	fi
fi
v=$(expr $v + 1)
w=$(expr $w + 1)
a=$(expr $a + 1)
#日志文件大于1万条后删除1000条
[ -s ./keep.txt ] && [ "$(sed -n '$=' ./keep.txt)" -ge "10000" ] && echo -e "❴d:$log1❵ $(sed -n '$=' ./keep.txt)—1000_[$(timenow)]" >> ./keep.txt && sed -i '1,1000d' ./keep.txt && log1=$(($log1+1))
sleep 120
done
EOF
chmod +x ./${name}_keep.sh
fi
[ -z "$(psskeep)" ] && echo -e \\n"\e[1;36m▶启动进程守护脚本...\e[0m" && nohup sh $dirtmp/${name}_keep.sh >> $dirtmp/keep.txt 2>&1 &
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
status_clash () {
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

#关闭
stop_clash () {
[ ! -z "$(pss)" ] && logger -t "【${name}】" "▷关闭${name}..." && echo -e \\n"\e[1;36m▷关闭${name}...\e[0m" && pss | awk '{print $1}' | xargs kill -9 && curl_proxy
}
#启动
start_clash () {
[ -f ./${name}_log.txt ] && mv -f ./${name}_log.txt ./old_${name}_log.txt
logger -t "【${name}】" "▶启动${name}主程序..." && echo -e \\n"\e[1;36m▶启动${name}主程序...\e[0m"
if [ "$mode" = "2" ] ; then
	[ -z "$(grep "$user_name" /etc/passwd)" ] && echo "▶添加用戶$user_name，uid為$user_id" && adduser -u $user_id $user_name -D -S -H -s /bin/sh
	su $user_name -c "nohup $run > $dirtmp/${name}_log.txt 2>&1 &"
else
	nohup $run > $dirtmp/${name}_log.txt 2>&1 &
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
}
#启动模式1：iptables透明代理
start_1 () {
[ "$mode" != "1" ] && mode=1 && sed -i 's/mode=.*/mode=1/g' $dirconf/settings.txt
start_0
start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables &
#还原节点记录
start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark &
}
#启动模式2：iptables透明代理+路由自身走代理
start_2 () {
[ "$mode" != "2" ] && mode=2 && sed -i 's/mode=.*/mode=2/g' $dirconf/settings.txt
start_0
start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables && sleep 10 && [ -f ./start_iptables_0 ] && start_iptables &
start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark && sleep 10 && [ -f ./mark/start_remark_ok_0 ] && start_remark &
}
#启动模式3：不启用iptables透明代理
start_3 () {
[ "$mode" != "3" ] && mode=3 && sed -i 's/mode=.*/mode=3/g' $dirconf/settings.txt
start_0
}

start_11 () {
start_0
if [ ! -z "$(pss)" -a ! -z "$(port)" ] ; then
	ipt2socks_start
else
	logger -t "【${name}】" "✘检测到未启动${name}进程或端口没监听，取消ipt2socks透明代理" && echo -e \\n"\e[1;31m✘检测到未启动${name}进程或端口没监听，取消ipt2socks透明代理\e[0m"\\n
fi
}
start_12 () {
start_0
if [ ! -z "$(pss)" -a ! -z "$(port)" ] ; then
	transocks_start
else
	logger -t "【${name}】" "✘检测到未启动${name}进程或端口没监听，取消transocks透明代理" && echo -e \\n"\e[1;31m✘检测到未启动${name}进程或端口没监听，取消transocks透明代理\e[0m"\\n
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
echo -e \\n" \e[1;32m✔clash卸载完成！\e[0m"
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
os1="linux-mipsle-softfloat"
#os2="linux-armv8"
echo -e \\n"\e[1;4;36m▶正在检查$filename是否需要更新～\e[0m"
#tmpclash
tmpclash_address="https://tmpclashpremiumbindary.cf"
tmpclash_url1=$($curl -sL $tmpclash_address | awk -F\" '/'$os1'/{print $2}' | sed 's@^@$tmpclash_address/@')
tmpclash_url2=$(echo $tmpclash_url1 | sed "s/$os1/$os2/")
tmpclash_ver=$(echo $tmpclash_url1 | awk -F '-' '{print $NF}' | sed 's/\.gz//')
#github
github_address="https://github.com/Dreamacro/clash"
github_url1=$($curl -sL $github_address/releases | awk -F\" '/releases.*premium.*'$os1'/{print "https://github.com" $2}' | head -n 1)
#github_url2=$(echo $github_url1 | sed "s/$os1/$os2/")
github_ver=$(echo $github_url1 |grep -Eo "$os1.*gz"|awk -F '-' '{print $NF}'|sed 's/.gz//')
#new=$($curl -sL https://github.com/Dreamacro/clash/releases | grep -Eo "title=\"v.*\">" |head -n1 |awk -F'v' '{print $2}' |sed 's/">//')
old=$($curl -sL $url/t/clash.ver)
if [ "$github_ver" = "$old" ]; then
	echo -e \\n"  ✔ $filename 版本一致，无需更新！\\n  github版本：\e[1;37m【$github_ver】\e[0m \\n  tmpclash版本：\e[1;32m【$tmpclash_ver】\e[0m \\n  old 旧版本：\e[1;32m【$old】\e[0m"\\n
else
	echo -e \\n"  $filename 正在更新... \\n  github版本：\e[1;37m【$github_ver】\e[0m \\n  clashp版本：\e[1;32m【$tmpclash_ver】\e[0m \\n  old 旧版本：\e[1;33m【$old】\e[0m"\\n
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

up () {
[ ! -d ./update ] && mkdir -p ./update
cd ./update
echo -e \\n"\e[1;32m【1】\e[0m\e[1;36m 更新Web \e[0m"
echo -e "\e[1;32m【2】\e[0m\e[1;36m 更新geoip\e[0m"
echo -e "\e[1;32m【3】\e[0m\e[1;36m 更新clash\e[0m"
echo -e "\e[1;32m【4】\e[0m\e[1;36m 更新ipset cnip\e[0m"
echo -e "\e[1;32m【9】\e[0m\e[1;36m 检查更新以上\e[0m"\\n
read -n 1 -p "请输入数字检查更新:" numx
[ "$numx" = "1" ] && upweb &
[ "$numx" = "2" ] && upgeoip &
[ "$numx" = "3" ] && upclash &
[ "$numx" = "4" ] && upcnip &
if [ "$numx" = "9" ] ; then
upweb
upgeoip
upclash 
upcnip
fi
}

#状态
zhuangtai () {
echo -e \\n"\e[1;33m当前状态：\e[0m"\\n
if [ -s ./${name} ] ; then
	echo -e "★ \e[1;36m ${name} 版本：\e[1;32m【$(./${name} -v|awk '/Clash/{print $2}'|sed 's/v//')】\e[0m"
else
	echo -e "☆ \e[1;36m ${name} 版本：\e[1;31m【不存在】\e[0m"
fi
if [ -s $tmp/$config ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat $tmp/$config | awk -F// '/【/{print $2}')\e[0m临时yaml"
elif [ -s $dirconf/$config ] ; then
	echo -e "★ \e[1;36m ${name} 配置：\e[1;32m$(cat $dirconf/$config | awk -F// '/【/{print $2}')\e[0m闪存yaml"
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
pre1=$(iptables -t mangle -nL PREROUTING | grep clash | grep udp | wc -l)
pre2=$(iptables -t mangle -nL PREROUTING | grep clash | grep tcp | wc -l)
pre3=$(iptables -t nat -nL PREROUTING | grep CLASHDNS | wc -l)
out1=$(iptables -t nat -nL OUTPUT | grep CLASHDNS | wc -l)
out2=$(iptables -t nat -nL OUTPUT | grep clash_mark | wc -l)
if [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "0" ] ; then
	iptables_mode=1
elif [ "$pre1" = "1" -a "$pre2" = "1" -a "$pre3" = "1" -a "$out1" = "1" -a "$out2" = "1" ] ; then
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
3)
	start_3 &
	;;
#4)
	#start_4 &
	#;;
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
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start_1：启动clash✚tproxy透明代理\e[0m"
	#echo -e "\e[1;32m【2】\e[0m\e[1;36m start_2：启动clash✚tproxy透明代理✚自身走代理\e[0m"
	echo -e "\e[1;32m【3】\e[0m\e[1;36m start_3：仅启动clash\e[0m"
	#echo -e "\e[1;32m【4】\e[0m\e[1;36m start_4：启动clash✚transocks 透明代理 \e[0m"
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
	#elif [ "$num" = "4" ] ; then
		#start_4 &
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