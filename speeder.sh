#!/bin/bash
sh_ver=1

#程序名字
name=speederv2
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

#资源文件地址前缀
url1="https://raw.githubusercontent.com/ss916/test/master"
url2="https://cdn.jsdelivr.net/gh/ss916/test"
url3="https://raw.fastgit.org/ss916/test/master"

#alias
alias pss='ps -w |grep -v grep| grep ${name}'
alias pid='pidof ${name}'
alias port='netstat -anp | grep "${name}"'
alias psskeep='ps -w | grep -v grep |grep "${name}_keep.sh"'
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'

curl_proxy () {
if [ ! -z "$(ps -w |grep -v grep| grep "clash -d")" -a ! -z "$(netstat -anp | grep clash)" ] ; then
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
echo -e \\n"\e[1;36m↓↓ $name初始化设置，請輸入服务器IP或域名 ↓↓\e[0m"\\n
read -p "域名：" server_domain
echo -e \\n"\e[1;36m↓↓ 請输入服务器端口↓↓\e[0m"\\n
read -p "端口：" server_port
echo -e \\n"\e[1;36m↓↓ 請输入服务器密码↓↓\e[0m"\\n
read -p "端口：" server_key
echo -e \\n"\e[1;37m你输入了：	\\n${name}服务器域名: $server_domain \\n服务器端口: $server_port \\n服务器密码: $server_key\e[0m"
echo "server_domain=$server_domain
server_port=$server_port
server_key=$server_key
" > $dirconf/settings.txt
}
#读取参数
read_settings () {
server_domain=$(cat $dirconf/settings.txt |awk -F 'server_domain=' '/server_domain=/{print $2}' | head -n 1)
server_port=$(cat $dirconf/settings.txt |awk -F 'server_port=' '/server_port=/{print $2}' | head -n 1)
server_key=$(cat $dirconf/settings.txt |awk -F 'server_key=' '/server_key=/{print $2}' | head -n 1)
diretc=$(cat $dirconf/settings.txt |awk -F 'diretc=' '/diretc=/{print $2}' | head -n 1)
[ -z "$diretc" ] && diretc=/tmp/$name/etc && echo "diretc=/tmp/$name/etc" >> $dirconf/settings.txt
mode=$(cat $dirconf/settings.txt |awk -F 'mode=' '/mode=/{print $2}' | head -n 1)
[ -z "$mode" ] && mode=1 && echo "mode=1" >> $dirconf/settings.txt
}
if [ ! -z "$2" -a ! -z "$3" ] ; then
	#一键快速设置参数：./speeder.sh 1 server_domain=domain.com server_port=443 server_key=123
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

#下载主程序
down_program () {
file=${name}
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filename=$file filetgz=$file
	[ -s ./$file ] && chmod +x -R ./
fi
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
}

#进程守护
start_keep () {
if [ ! -s ./${name}_keep.sh ] ; then
echo "▶生成进程守护脚本."
cat > ./${name}_keep.sh << \EOF
#!/bin/sh
name=speederv2
tmp=/tmp
etc=/etc/storage
dirtmp=$tmp/${name}
pdcn=$etc/pdcn
dirconf=$pdcn/${name}
alias pss='ps -w |grep -v grep| grep "${name}"'
alias pid='pidof ${name}'
alias port='netstat -anp | grep "${name}"'
alias psskeep='ps -w | grep -v grep |grep "${name}_keep.sh"'
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'
mode=$(cat $dirconf/settings.txt |awk -F 'mode=' '/mode=/{print $2}' |head -n 1)
cd $dirtmp
v=1
log1=1
while true ; do
pss_status=$(pss|wc -l)
port_status=$(port|wc -l)
if [ "$pss_status" != "1" -o -z "$port_status" ] ; then
	if [ "$pss_status" = "0" ] ; then
		echo -e "$(timenow) [$v]检测${name}进程不存在，重启程序！" >> ./keep.txt
	elif [ "$pss_status" -gt "1" ] ; then
		echo -e "$(timenow) [$v]检测${name}进程重复 x $pss_status，重启程序！" >> ./keep.txt
	fi
	[ -z "$port_status" ] && echo -e "$(timenow) [$v]检测${name}端口没监听，重启程序！" >> ./keep.txt
	nohup sh $pdcn/${name}.sh $mode >> ./keep.txt 2>&1 &
	v=0
else
	echo -e "$(timenow) ${name} [$v] 进程OK，端口OK" >> ./keep.txt
fi
v=$(expr $v + 1)
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
[ ! -z "$(pss)" ] && logger -t "【${name}】" "▷关闭${name}..." && echo -e \\n"\e[1;36m▷关闭${name}...\e[0m" && pss | awk '{print $1}' | xargs kill -9
}
#启动
start_program () {
[ -f ./${name}_log.txt ] && mv -f ./${name}_log.txt ./old_${name}_log.txt
logger -t "【${name}】" "▶启动${name}主程序..." && echo -e \\n"\e[1;36m▶启动${name}主程序...\e[0m"
server_domain=$(cat $dirconf/settings.txt |awk -F 'server_domain=' '/server_domain=/{print $2}' | head -n 1)
server_port=$(cat $dirconf/settings.txt |awk -F 'server_port=' '/server_port=/{print $2}' | head -n 1)
server_key=$(cat $dirconf/settings.txt |awk -F 'server_key=' '/server_key=/{print $2}' | head -n 1)
server_ip=$(nslookup $server_domain 8.8.4.4 | sed -n '/Name/,$p' | grep -E -o '([0-9]+\.){3}[0-9]+')
[ -z "$server_ip" ] && echo -e "\e[1;31m✖服务器$server_domain解析DNS为空，取消启动。\e[0m" && exit
nohup $dirtmp/${name} -c -l 0.0.0.0:44420 -r $server_ip:$server_port -k "$server_key" -f 2:2 --timeout 0 --fifo $dirtmp/fec  > $dirtmp/${name}_log.txt 2>&1 &
}

#關閉
stop_0 () {
stop_program
}
#关闭所有
stop_1 () {
stop_0
stop_wan
stop_cron
stop_keep
}

#启动模式0
start_0 () {
echo -e \\n"$(timenow)"\\n
#关闭所有
stop_0
#下载文件
down_program
#启动主程序
start_program
#等待15秒
check_work && waitwork check_work 15
#查看状态
status_program
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
}

#8更新文件
renew () {
startrenew=1
echo -e \\n"\e[1;33m檢查更新文件：\e[0m"\\n
down_program
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
echo -e \\n" \e[1;32m✔$name卸载完成！\e[0m"
fi
}

#状态
zhuangtai () {
echo -e \\n"\e[1;33m当前状态：\e[0m"\\n
if [ -s ./${name} ] ; then
	echo -e "★ \e[1;36m ${name} 版本：\e[1;32m【$(./${name} -h |grep -o "version.*")】\e[0m"
else
	echo -e "☆ \e[1;36m ${name} 版本：\e[1;31m【不存在】\e[0m"
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
}
#按钮
case $1 in
0)
	stop_1 &
	;;
1)
	start_1 &
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
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start_1：启动$name\e[0m"
	echo -e "\e[1;32m【7】\e[0m\e[1;36m settings：重置初始化配置\e[0m"
	echo -e "\e[1;32m【8】\e[0m\e[1;36m renew：更新所有文件 \e[0m"
	echo -e "\e[1;32m【9】\e[0m\e[1;36m remove：卸载 \e[0m"\\n
	read -n 1 -p "请输入数字:" num
	if [ "$num" = "0" ] ; then
		stop_1 &
	elif [ "$num" = "1" ] ; then
		start_1 &
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