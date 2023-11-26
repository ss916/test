#!/bin/bash
sh_ver=59
#
path=${0%/*}
bashname=${0##*/}
bashpid=$$

#程序名字
name=speedtest

#闪存配置文件夹
dirconf=${path}/${name}
[ ! -d $dirconf ] && mkdir -p $dirconf

tmp=/tmp
#系统定时任务文件
file_cron=/etc/storage/cron/crontabs/admin
#开机自启文件
file_wan=/etc/storage/post_wan_script.sh

user_name=${name}
#用户uid/gid
uid=0
gid=20005

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
echo -e \\n"\e[1;36m$name初始化设置\e[0m"\\n
echo -e \\n"\e[1;36m↓↓ 請输入监听端口port，按回车则使用默认8989↓↓\e[0m"\\n
read -p "请输入→：" listen_port
#自启
echo -e \\n"\e[1;36m↓↓ 請选择开机自启模式wan↓↓\e[0m"\\n
echo -e "\e[36m0.不启用\\n1.开机自启，仅检查进程（默认）\\n2.开机自启，强制重启进程\e[0m"
read -n 1 -p "请输入：" wan
echo -e \\n"\e[1;36m↓↓ 請选择定时启动模式cron↓↓\e[0m"\\n
echo -e "\e[36m0.不启用\\n1.定时启动，仅检查进程（默认）\\n2.定时启动，强制重启进程\e[0m"
read -n 1 -p "请输入：" cron
###
echo -e \\n"\e[1;37m你输入了：\\n\\n监听端口port：$listen_port \\n开机自启wan: $wan \\n定时启动cron: $cron \e[0m"\\n
echo "listen_port=$listen_port
wan=$wan
cron=$cron
" > $dirconf/settings.txt
sed -i '/^.*=$/'d $dirconf/settings.txt
}
#读取参数
read_settings () {
##读取配置文件全部参数
for a in $(cat $dirconf/settings.txt | grep '=' | sed '1!G;h;$!d') ; do n=$(echo $a | awk -F= '{print $1}') ; b=$(echo $a | sed "s/${n}=//g") ; eval $n=$b ; done
##缺省参数补全
[ -z "$listen_port" ] && listen_port=8989 && echo "listen_port=$listen_port" >> $dirconf/settings.txt
[ -z "$mode" ] && mode=1 && echo "mode=$mode" >> $dirconf/settings.txt
[ -z "$wan" ] && wan=1 && echo "wan=$wan" >> $dirconf/settings.txt
[ -z "$cron" ] && cron=1 && echo "cron=$cron" >> $dirconf/settings.txt
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
	#一键快速设置参数：./speedtest.sh 1 listen_port=8989
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


run="$dirtmp/${name} -c $dirtmp/settings.toml"

pss='ps -w |grep -v grep| grep "${name} -c"'
pid='pidof ${name}'
port='netstat -anp 2>/dev/null | grep "${name}"'
psskeep='ps -w | grep -v grep |grep "${name}_keep.sh"'
timenow='date "+%Y-%m-%d_%H:%M:%S"'
#version="$dirtmp/${name} -v | grep -i ${name} | cut -f 3 -d ' ' | sed 's/v//' "

#alias
alias pss=$pss
alias pid=$pid
alias port=$port
alias psskeep=$psskeep
alias timenow=$timenow
#alias version=$version

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


down_config () {
echo "▶生成配置文件settings.toml"
cat > ./settings.toml << EOF
bind_address=""
listen_port="$listen_port"
EOF
}

#下载主程序
down_program () {
file=${name}
if [ ! -s ./$file -o "$startrenew" = "1" ] ; then
	downloadfile address=t/$file filetgz=$file fileout=./ filename=$file
fi
[ -s ./$file ] && [ ! -x ./$file ] && echo ">> 赋予主程序文件$file执行权限" && chmod +x ./$file
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
if [ "\$server_port_ok" = "1" ] ; then
	echo -e "\$(timenow) \${name} [\$v] 进程OK，端口OK" >> ./keep.txt
fi
##+1
v=\$((v+1))
##休息
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
#[ ! -s ./${name}_ver.txt ] && echo "▶查询主程序$name 版本号..." && echo "$(version)" | sed '/^ *$/d' > ./${name}_ver.txt
[ -z "$(grep "$gid$" ${path}/RETURN_UID_GID.TXT 2>/dev/null)" ] && echo "▶add $user_name,$uid,$gid to ${path}/RETURN_UID_GID.TXT" && echo "$user_name,$uid,$gid" >> ${path}/RETURN_UID_GID.TXT
[ -z "$(grep "$user_name" /etc/passwd)" ] && echo "▶添加用戶$user_name，uid为$uid，gid为$gid" && echo "$user_name:x:$uid:$gid:::" >> /etc/passwd
su $user_name -c "nohup $run > $dirtmp/${name}_log.txt 2>&1 &"
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
all_sh=$(ps -w | grep -v grep| grep ${bashname} | wc -l)
[ "$all_sh" -gt "2" ] && echo -e "▷关闭脚本${bashname}重复进程 x $((all_sh-1))" && ps -w | grep -v grep| grep ${bashname} && ps -w | grep -v grep | grep ${bashname} | awk '{print $1}' | xargs kill -9
}

#启动模式0
start_0 () {
echo -e \\n"$(timenow)"\\n
#关闭所有
stop_0
#生成配置文件
down_config
#下载文件
echo -e \\n"\e[1;36m▶检查与下载${name}资源文件...\e[0m"
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
if [ "$run_restart_keep" = "1" ] ; then
	restart_keep
else
	psskeep_status=$(psskeep | wc -l) && [ "$psskeep_status" -gt "1" ] && echo -e "▷检测到进程守护脚本keep.sh进程重复 x $psskeep_status，重启脚本keep.sh" && echo -e "\\n$(timenow) ▷检测到进程守护脚本keep.sh进程重复 x $psskeep_status，重启脚本keep.sh \\n" >> $dirtmp/keep.txt && stop_keep
	start_keep
fi
}
#启动模式1：iptables透明代理
start_1 () {
[ "$mode" != "1" ] && mode=1 && sed -i '/mode=/d' $dirconf/settings.txt && echo "mode=$mode" >> $dirconf/settings.txt && echo -e \\n"◆启动模式mode已改变为【$mode】 ◆ "\\n && run_restart_keep=1
echo "🔒keep_lock" && > skip_keep_check_start_1
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
down_program
echo -e \\n"\e[1;33m...更新完成...\e[0m"\\n
#[ -s ./$name ] && echo "$(version)" | sed '/^ *$/d' > ./${name}_ver.txt
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
┌─────────────────────────────────────┐
│░█▀▀░█▀█░█▀▀░█▀▀░█▀▄░▀█▀░█▀▀░█▀▀░▀█▀░│
│░▀▀█░█▀▀░█▀▀░█▀▀░█░█░░█░░█▀▀░▀▀█░░█░░│
│░▀▀▀░▀░░░▀▀▀░▀▀▀░▀▀░░░▀░░▀▀▀░▀▀▀░░▀░░│
└─────────────────────────────────────┘
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
if [ ! -s ./${name} ] ; then
	echo -e "☆ \e[1;36m ${name} 版本：\e[1;31m【不存在】\e[0m"
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
	echo -e "● \e[1;36m ${name} 端口：\e[1;32m【已监听】\e[0m listen_port：\e[1;37m$listen_port\e[0m"
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
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start_1：启动$name\e[0m"
	echo -e "\e[1;32m【7】\e[0m\e[1;36m resettings：重置初始化配置\e[0m"
	echo -e "\e[1;32m【8】\e[0m\e[1;36m renew：更新所有文件 \e[0m"
	echo -e "\e[1;32m【9】\e[0m\e[1;36m remove：卸载 \e[0m"\\n
	read -n 1 -p "请输入数字:" num
	if [ "$num" = "0" ] ; then
		stop_1 &
	elif [ "$num" = "1" ] ; then
		start_1 &
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