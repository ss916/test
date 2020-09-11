#!/bin/sh
shname="網易云解鎖"
address="https://github.com/cnsilvan/UnblockNeteaseMusic/releases"
os="linux-mipsle"
filename=UnblockNeteaseMusic
filetgz=$filename-$os.zip
http_port=1235
https_port=1236

if [ ! -z "$(ps -w |grep -v grep| grep "clash.*-d")" ] ; then
	curl="curl -x 127.0.0.1:8005"
else
	curl="curl"
fi
dir=/tmp/netease
[ ! -d $dir ] && mkdir -p $dir
cd $dir
jincheng="ps -w"

download_file () {
url=$($curl -sL $address | awk -F\" '/releases.*'$os'/{print "https://github.com" $2}' | head -n 1)
new=`echo $url|grep -Eo "releases.*$os"|awk -F\/ '{print $3}'|sed 's/^v//'`
echo -e \\n"\e[1;36m▶下載主程序$filetgz，最新版【$new】...\e[0m"\\n
$curl -# -L $url -o $filetgz
[ ! -s /opt/bin/unzip ] && echo -e "  >> 检测到opt需要安装unzip..." && opkg update && opkg install unzip
unzip $filetgz
chmod +x -R ./
}
download_file2 () {
url2=https://raw.fastgit.org/ss916/test/master/t/UnblockNeteaseMusic
url3=https://raw.fastgit.org/ss916/test/master/t/createCertificate.sh
echo -e \\n"\e[1;36m▶下載主程序$filetgz，最新版【$new】...\e[0m"\\n
$curl -# -L $url2 -O
$curl -# -L $url3 -O
chmod +x -R ./
}
check_file () {
[ ! -s ./$filename ] && download_file && [ ! -s ./$filename ] && download_file
if [ ! -s ./server.crt ] ; then
	if [ ! -s ./createCertificate.sh ] ; then
		echo -e \\n"\e[1;31m！！證書腳本文件createCertificate.sh不存在，重新下載$filetgz \e[0m"\\n
		download_file
	else
		echo -e \\n"\e[1;36m▶生成證書文件server.crt...\e[0m"\\n
		./createCertificate.sh
	fi
fi
}

stop () {
[ ! -z "`$jincheng | grep -v grep | grep $filename`" ] && echo -e \\n"\e[1;36m▷結束$filename...\e[0m"\\n && killall $filename
}
start_1 () {
check_file
stop
echo -e \\n"\e[1;36m▶啟動$filename...\e[0m"\\n
nohup $dir/$filename -p $http_port -sp $https_port -b >/dev/null 2>&1 &
status
}

status () {
echo -e \\n"\e[1;33m当前状态：\e[1;37m $shname \e[0m"\\n
if [ -s ./$filename ] ; then
	echo -e "★ \e[1;36m $filename 版本：\e[1;32m【$(./$filename -v 2>&1|awk '/Version/{print $2}')】\e[0m"
else
	echo -e "☆ \e[1;36m $filename 版本：\e[1;31m【不存在】\e[0m"
fi
echo " "
jc=$($jincheng |grep -v grep |grep ${filename}.*-p)
if [ ! -z "$jc" ] ; then
	echo -e "● \e[1;36m $filename 进程：\e[1;32m【已运行】\e[0m"
else
	echo -e "○ \e[1;36m $filename 进程：\e[1;31m【未运行】\e[0m"
fi
#port=`netstat -anp | grep $filename`
port=`netstat -anp | grep UnblockNet`
if [ ! -z "$port" ] ; then
	echo -e "● \e[1;36m $filename 端口：\e[1;32m【已监听】\e[0m"
	echo -e "  \e[1;36m http 端口：\e[1;37m$http_port \e[1;36m https 端口：\e[1;37m$https_port \e[0m"
else
	echo -e "○ \e[1;36m $filename 端口：\e[1;31m【未监听】\e[0m"
fi
}
remove () {
echo -e \\n"\e[1;33m▷刪除所有...\e[0m"\\n
stop
rm -rf $dir
}
case $1 in
0)
	stop &
	;;
1)
	start_1 &
	;;
9)
	remove &
	;;
*)
	status
	echo -e \\n"\e[1;33m脚本管理：\e[0m"\\n
	echo -e "\e[1;32m【0】\e[0m\e[1;36m stop ：結束程序 \e[0m"
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start_1 ：啟動程序 \e[0m"
	echo -e "\e[1;32m【9】\e[0m\e[1;36m remove ：卸載 \e[0m"
	echo " "
	read -n 1 -p "请输入数字：" num
	if [ "$num" = "0" ] ; then
		stop &
	elif [ "$num" = "1" ] ; then
		start_1 &
	elif [ "$num" = "9" ] ; then
		remove &
	else
		echo -e \\n"\e[1;31m输入错误，目前功能只有\e[1;32m 0、1、9 \e[1;31m功能\e[0m "\\n
	fi
	;;
esac