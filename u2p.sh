#!/bin/bash
sh_ver=9

path=${0%/*}
bashname=${0##*/}
name=yt-dlp
network=4


[ "${path}" = "sh" -a "${bashname}" = "sh" -o "${path}" = "bash" -a "${bashname}" = "bash"  ] && echo -e \\n"❗ \e[1;37m获取不到脚本真实路径path与脚本名字bashname，其值为$path。依赖路径与名字的功能将会失效。请下载脚本到本地再运行。\e[0m❗"\\n
[ "$path" = "$bashname" ] && path=.

[ ! -d ${path}/${name} ] && mkdir -p ${path}/${name} && > ${path}/${name}/settings.txt

s1=$1
s2=$2
s3=$3
s4=$4
s5=$5
s6=$6
s7=$7
s8=$8

os1="x86_64 GNU/Linux"
os2="mips GNU/Linux"
os3="aarch64 Android"
a=$(uname -a)
if [ ! -z "$(echo $a | grep "$os1")" ] ; then
	os=debian
elif [ ! -z "$(echo $a | grep "$os2")" ] ; then
	os=padavan
elif [ ! -z "$(echo $a | grep "$os3")" ] ; then
	os=android
else
	echo " ✖ 未识别系统，结束脚本。" && exit
fi
if [ "$os" = "debian" ] ; then
bin_file=/usr/local/bin/${name}
package=apt
package_install="$package install -y"
filedir=/var/local/filebrowser
fi
if [ "$os" = "padavan" ] ; then
bin_file=/opt/bin/${name}
package=opkg
package_install="$package install"
filedir=/media/AiDisk_a1/123/download
fi
if [ "$os" = "android" ] ; then
echo "暂未支持" && exit
fi


[ ! -z "$s8" ] && proxy_port=$s8 && echo "* use http_proxy $proxy_port *" && export http_proxy=http://127.0.0.1:$proxy_port && export https_proxy=http://127.0.0.1:$proxy_port


[ ! -d $filedir ] && mkdir -p $filedir

install () {
if [ "$os" = "debian" ] ; then
install_ytdlp_github
else
echo -e \\n"   \e[1;33m   $package更新...\e[0m"\\n
$package update
echo -e \\n"   \e[1;33m   $package安装/更新 yt-dlp、ffmpeg...\e[0m"\\n
$package_install ffmpeg yt-dlp -y
fi
}
install_ytdlp_github () {
address="https://github.com/yt-dlp/yt-dlp"
o="yt-dlp_linux"
o2="yt-dlp_linux_aarch64"
url=`curl -sL $address/releases | awk -F\" '/releases.*'$o'/{print "https://github.com" $2}' | head -n 1`
url2=$(echo $url | sed "s/$o/$o2/")
new=`echo $url|grep -Eo "releases.*$o"|awk -F\/ '{print $3}'|sed 's/^v//'`
if [ -s ${path}/${name}/settings.txt ] ; then
	ver=$(cat ${path}/${name}/settings.txt |awk -F 'ver=' '/^ver=/{print $2}' | head -n 1)
	[ ! -z "$ver" ] && old=$ver || old=none
else
	old=nofile
fi
if [ "$new" = "$old" ] ; then
	echo -e \\n"    ● \e[1;36m 版本${new} 无需更新\e[1;32m✔ \e[0m"
else
	echo -e \\n"   \e[1;33m   github安装yt-dlp...\e[0m"\\n
	echo -e \\n"new：$new\\nold：$old\\nurl：$url"\\n
	curl -o /usr/local/bin/yt-dlp -L $url
	[ -s /usr/local/bin/yt-dlp ] && [ ! -x /usr/local/bin/yt-dlp ] && echo ">> 赋予主程序文件/usr/local/bin/yt-dlp执行权限" && chmod +x /usr/local/bin/yt-dlp
	ver=$(${name} --version)
	echo -e \\n"\e[1;33m当前版本：\e[1;32m【$ver】\e[0m"\\n
	sed -i '/ver=/d' ${path}/${name}/settings.txt && echo "ver=$ver" >> ${path}/${name}/settings.txt
fi
}

install_aria () {
echo -e \\n"   \e[1;33m   $package安装/更新 aria2...\e[0m"\\n
$package update
$ppackage_install aria2
ver=$(aria2c -v 2>&1 | awk '/aria2 version/{print $3}')
echo -e \\n"\e[1;33maria2版本：\e[1;32m【$ver】\e[0m"\\n
}

youtube () {
[ -z "$(which ${name})" ] && install
if [ "$s7" = "4" ] ; then
	network=4
elif [ "$s7" = "6" ] ; then
	network=6
fi
if [ -z "$s2" ] ; then
	echo -e \\n"\e[1;33m 请在下方输入YouTube视频链接URL：\e[0m "
	read -p "【输入URL→】：" url
else
	url=$s2
fi
echo -e \\n"\e[33m 你输入的视频链接为：\e[1;35m$url\e[0m "\\n

if [ -z "$s3" ] ; then
	echo -e \\n"\e[1;33m 是否需要查看视频所有分辨率？按1需要，按任意键则跳过。\e[0m"
	read -n 1 -p "【查看视频分辨率】：" getfile
else
	getfile=$s3
fi
if [ "$getfile" = "1" ] ; then
echo -e \\n"\e[33m 你选择的查看视频分辨率列表：\e[1;35m查看\e[0m "\\n
echo -e "\e[1;35m ！！正在查找视频所有分辨率，请等待视频分辨率查询完成，期间请不要任何输入！！\e[0m "
${name} --no-check-certificate -$network -F $url
else
echo -e \\n"\e[33m 你选择的查看视频分辨率列表：\e[1;35m跳过\e[0m "\\n
fi

if [ -z "$s4" ] ; then
echo -e \\n"\e[1;33m 请输入要下载视频的分辨率：\e[0m "\\n
echo -e "\e[1;32m【0】\e[0m\e[1;36m 自动最高画质bestvideo+bestaudio \e[0m"
echo -e "\e[1;32m【1】\e[0m\e[1;36m 720p 30fps： f=136+140 \e[0m"
echo -e "\e[1;32m【2】\e[0m\e[1;36m1080p 30fps：f=137+140\e[0m"
echo -e "\e[1;32m【3】\e[0m\e[1;36m 720p 60fps： f=298+140 \e[0m"
echo -e "\e[1;32m【4】\e[0m\e[1;36m1080p 60fps：f=299+140\e[0m"
echo -e "\e[1;32m【5】\e[0m\e[1;36m 480p 30fps：f=135+140\e[0m"
echo -e "\e[1;32m【9】\e[0m\e[1;36m自定义 ：格式如【136+140 】\e[0m"\\n
read -p "【请选择】：" fenbian
else
fenbian=$s4
fi
if [ "$fenbian" = "0" ] ; then
	f="bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best"
elif [ "$fenbian" = "1" ] ; then
	f="136+140"
elif [ "$fenbian" = "2" ] ; then
	f="137+140"
elif [ "$fenbian" = "3" ] ; then
	f="298+140"
elif [ "$fenbian" = "4" ] ; then
	f="299+140"
elif [ "$fenbian" = "5" ] ; then
	f="135+140"
elif [ "$fenbian" = "9" ] ; then
	echo -e \\n"\e[33m 请输入的自定义分辨率，格式如【136+140 】\e[0m "\\n
	read zidingyi
	f="$zidingyi"
else
	f="$fenbian"
fi
echo -e \\n"\e[33m 你选择的分辨率为：\e[1;35m$f\e[0m "\\n
[ -z "$(echo $f | grep -E "[0-9]{3}\+[0-9]{3}")" -a "$f" != "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" ] && echo -e \\n"\e[1;31m✘分辨率输入错误，请重新运行脚本。\e[0m"\\n && exit

if [ -z "$s5" ] ; then
echo -e \\n"\e[1;33m 是否自定义视频的保存路径：\e[0m "
echo -e "\e[1;32m【0】\e[1;36m默认保存到【$filedir】 \e[0m"
echo -e "\e[1;32m【1】\e[1;36m自定义保存路径 \e[0m"\\n
read -p "【请选择】：" lujing
else
lujing=$s5
fi
if [ "$lujing" = "0" ] ; then
	dir=$filedir
elif [ "$lujing" = "1" ] ; then
	echo -e \\n"\e[1;33m 输入自定义视频的保存路径：\e[0m "
	read lujing1
	dir=$lujing1
else
	dir=$lujing
fi
echo -e \\n"\e[33m 你选择的文件保存路径为：\e[1;35m$dir\e[0m "\\n
if [ ! -d $dir ] ; then
	mkdir -p $dir
	if [ ! -d $dir ] ; then
		echo -e \\n"\e[1;31m✘检测到无法创建自定义保存文件夹$dir，请尝试更换路径。结束脚本。\e[0m" && exit
	fi
fi

if [ -z "$s6" ] ; then
echo -e \\n"\e[1;33m 准备后台下载视频文件，请选择是否调用aria下载....\e[0m "
echo -e "\e[1;32m【0】\e[1;36m不调用，直接使用${name}单线程下载 \e[0m"
echo -e "\e[1;32m【1】\e[1;36m调用aria多线程下载\e[0m"\\n
read -n 1 -p "【请选择】：" aria
else
aria=$s6
fi
if [ "$aria" = "0" ] ; then
	echo -e \\n"\e[33m [ipv${network}]你选择的下载方式：\e[1;35m直接${name}单线程下载\e[0m "\\n
	${name} --no-check-certificate -$network --write-sub --embed-sub --sub-langs all,-live_chat --no-write-thumbnail --embed-thumbnail --embed-chapters --add-metadata -o "$dir/%(title)s.%(ext)s" -f $f -c -i $url 2>&1 | tee /tmp/${name}.log.txt &
else
	echo -e \\n"\e[33m [ipv${network}]你选择的下载方式：\e[1;35m调用aria多线程下载\e[0m "\\n
	[ -z "$(which aria2c)" ] && install_aria
	${name} --no-check-certificate -$network --write-sub --embed-sub --sub-langs all,-live_chat --no-write-thumbnail --embed-thumbnail --embed-chapters --add-metadata --external-downloader aria2c --external-downloader-args "-x 16 -s 16 -k 1M" -o "$dir/%(title)s.%(ext)s" -f $f -c -i $url 2>&1 | tee /tmp/${name}.log.txt &
fi
echo -e \\n"\e[1;36m 查看日志....\e[0m "
}


toilet_font () {
echo "
┌─────────────────────────────┐
│░█░█░█▀█░█░█░▀█▀░█░█░█▀▄░█▀▀░│
│░░█░░█░█░█░█░░█░░█░█░█▀▄░█▀▀░│
│░░▀░░▀▀▀░▀▀▀░░▀░░▀▀▀░▀▀░░▀▀▀░│
└─────────────────────────────┘
"
}

zhuangtai () {
toilet_font
echo -e "\e[1;33m当前状态：\e[0m"\\n
if [ -s ${path}/${name}/settings.txt ] ; then
	ver=$(cat ${path}/${name}/settings.txt |awk -F 'ver=' '/^ver=/{print $2}' | head -n 1)
	if [ ! -z "$ver" ] ; then
		echo -e "★ \e[1;36m ${name} 版本：\e[1;32m【$ver】\e[0m"
	else
		echo -e "☆ \e[1;36m ${name} 版本：\e[1;31m【未检查】\e[0m"
	fi
else
	echo -e "☆ \e[1;36m ${name} 版本：\e[1;31m【不存在settings.txt文件】\e[0m"
fi
}

help () {
echo "
#YouTube视频下载

u2p.sh 1 url 0 0 0 0 4

1：1=启用下载 
2：url，视频地址
3：列出所有分辨率：0=跳过，1=查看分辨率
4：选择分辨率：0=自动best画质，1=720p30f，2=1080p30f，3=720p60f，4=1080p60f，9=自定义填写如 136+140
5：保存路径：0=$filedir，1=自定义文件保存路径，或者直接写文件路径
6：0=直接下载，1=调用aria下载
7：4=强制使用ipv4下载，默认，可省略。6=强制使用ipv6下载
8：环境变量http proxy代理端口，留空则不启用

示例：https://youtu.be/kenYPzfi-SU

#启用下载、url、不列出所有分辨率、使用自动最高分辨率、默认保存路径、直接下载、默认ipv4、不走代理
./u2p.sh 1 https://youtu.be/kenYPzfi-SU 0 0 0 0

#启用下载、url、不列出所有分辨率、使用自动最高分辨率、默认保存路径、调用aria下载、强制ipv4、本地http代理
./u2p.sh 1 https://youtu.be/kenYPzfi-SU 0 0 0 1 4 8005


"
}


case $1 in
1)
	youtube
	;;
2)
	install &
	;;
h|-h|help|-help)
	help
	;;
*)
	zhuangtai
	echo -e \\n"\e[1;33m脚本管理：\e[0m\e[37m『 \e[0m\e[1;37m$sh_ver\e[0m\e[37m 』\e[0m"\\n
	echo -e "\e[1;32m【1】\e[1;36m 下载YouTube视频 \e[0m "
	echo -e "\e[1;32m【2】\e[1;36m 更新 ${name}、ffmpeg \e[0m "\\n
	read -n 1 -p "【输入数字】:" num
	[ "$num" = "1" ] && youtube
	[ "$num" = "2" ] && install
	;;
esac

