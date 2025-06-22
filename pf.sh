#!/bin/bash
sh_ver=101

path=${0%/*}
bashname=${0##*/}
bashpid=$$

name=pf
dirtmp=/tmp/${name}
diretc=$dirtmp
dirconf=${path}/pdcn
[ ! -d $dirconf ] && mkdir -p $dirconf
tmp=/tmp
file_cron=/etc/storage/cron/crontabs/admin
file_wan=/etc/storage/post_wan_script.sh
file_wan2=/etc/storage/post_iptables_script.sh

#资源文件地址前缀
url1="https://raw.githubusercontent.com/ss916/test/main"
#url2=""
url3="https://rrr.ariadl.eu.org/ss916/test/main"
url4="https://fastly.jsdelivr.net/gh/ss916/test@main"
url5="https://gcore.jsdelivr.net/gh/ss916/test@main"
#url6="https://testingcf.jsdelivr.net/gh/ss916/test@main"
url7="https://yyellow.ariadl.eu.org/916"

[ "${path}" = "sh" -a "${bashname}" = "sh" -o "${path}" = "bash" -a "${bashname}" = "bash" ] && echo -e \\n"❗ \e[1;37m获取不到脚本真实路径path与脚本名字bashname，其值为$path。依赖路径与名字的功能将会失效。请下载脚本到本地再运行。\e[0m❗"\\n

read_settings () {
for a in $(cat $dirconf/$name/settings.txt | grep '=' | grep -Ev '^#' | sed '1!G;h;$!d') ; do n=$(echo $a | awk -F= '{print $1}') ; b=$(echo $a | sed "s/${n}=//g") ; eval $n=$b ; done
}
[ -s $dirconf/$name/settings.txt ] && read_settings


#alias
[ "$(shopt 2>/dev/null | awk '/expand_aliases/{print $2}')" = "off" ] && shopt -s expand_aliases
alias timenow='date "+%Y-%m-%d_%H:%M:%S"'

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
#检验文件算法
[ -z "$hash" ] && hash=SHA1
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




#开机自启
stop_wan () {
[ ! -z "$(cat $file_wan | grep ${bashname})" ] && echo -e \\n"\e[1;36m□删除开机自启$file_wan\e[0m" && sed -i "/${bashname}/d" $file_wan
[ ! -z "$(cat $file_wan2 | grep ${bashname})" ] && echo -e \\n"\e[1;36m□删除开机自启$file_wan2\e[0m" && sed -i "/${bashname}/d" $file_wan2
}
start_wan () {
if [ "$(cat $file_wan | grep ${bashname} | wc -l)" != "1" -o "$(cat $file_wan2 | grep ${bashname} | wc -l)" != "1" ] ; then
stop_wan
echo -e \\n"\e[1;36m■添加开机自启到$file_wan\e[0m" && echo "sh ${path}/${bashname} set_path" >> $file_wan
echo -e \\n"\e[1;36m■添加开机自启到$file_wan2\e[0m" && echo "sh ${path}/${bashname} set_path" >> $file_wan2
fi
}

#定时任务
stop_cron () {
[ ! -z "$(cat $file_cron | grep ${bashname})" ] && echo -e \\n"\e[1;36m▷删除定时任务crontab...\e[0m" && sed -i "/${bashname}/d" $file_cron
}
start_cron () {
[ -z "$(cat $file_cron | grep ${bashname})" ] && echo -e \\n"\e[1;36m▶创建定时任务crontab，每3天0点22分更新脚本...\e[0m" && echo "22 0 */3 * * sh ${path}/${bashname} up > $tmp/${bashname}_start_cron.txt 2>&1 &" >> $file_cron
}
start_cron_3 () {
if [ "$(cat $file_cron | grep ${bashname} | wc -l)" != "1" ] ; then
stop_cron
echo -e \\n"\e[1;36m▶创建定时任务crontab，每3天0点33分更新脚本+更新文件...\e[0m" && echo "33 0 */3 * * sh ${path}/${bashname} cron_update_all > $tmp/${bashname}_cron_update_all.txt 2>&1 &" >> $file_cron
fi
}


up_sh () {
uptime
sh="clash.sh opt.sh v2ray.sh speederv2.sh u2p.sh ipv6.sh caddy.sh hysteria.sh speedtest.sh warpip.sh kcptun.sh cf.sh natmap.sh"
for s in $sh
do
{
echo -e \\n"\e[1;33m【$s】檢查更新文件...$(timenow)...\e[0m"\\n
downloadfile address=$s filetgz=$s fileout=$dirconf filename=$s
if [ "$download_ok" = "1" ] ; then
	if [ -s $dirconf/$s ] ; then
		ver=$(cat $dirconf/$s | awk -F = '/^sh_ver/{print $2}')
		if [ ! -z "$ver" ] ; then
			echo -e "\e[1;37;42m✔  $s：『 $ver 』\e[0m"
			chmod +x $dirconf/$s
			[ "$force_renew" = "1" ] && sh_keep=$(echo $s | sed 's/\.sh$/_keep.sh/g') && [ ! -z "$(ps | grep -v grep | grep $sh_keep)" ] && echo " 🆕 [$s] $sh_keep正在运行，renew强制更新所有文件..." && $dirconf/$s 8
		else
			echo -e "\e[1;37;41m✖  $s版本为空\e[0m"
		fi
	else
		echo -e "\e[1;37;41m✖  $dirconf/$s文件不存在\e[0m"
	fi
else
	echo -e "\e[1;37;41m✖  $s下载失败。\e[0m"
fi
echo -e \\n"\e[1;33m【$s】更新完成...$(timenow)...\e[0m"\\n
} &
sleep 1
done
mtd_storage.sh save &
}

up_pf () {
if [ ! -z "${force_url}" ] ; then
u=$(set | grep -E "^url${force_url}=" | sed '/"/d' | sed -E "s/'//g;s/^url${force_url}=//g")
#else
#u=$url4
fi
s=${name}.sh
echo -e \\n"\e[1;33m〘$s〙檢查更新文件...$(timenow)...\e[0m"\\n
downloadfile address=$u/$s filetgz=$s fileout=${path} filename=$s
if [ "$download_ok" = "1" ] ; then
if [ -s ${path}/$s ] ; then
ver=$(cat ${path}/$s | awk -F = '/^sh_ver/{print $2}')
if [ ! -z "$ver" ] ; then
echo -e "\e[1;37;42m✔  $s：『 $ver 』\e[0m"
chmod +x ${path}/$s
else
echo -e "\e[1;37;41m✖  $s版本为空\e[0m"
fi
else
echo -e "\e[1;37;41m✖  ${path}/$s文件不存在\e[0m"
fi
else
echo -e "\e[1;37;41m✖  $s下载失败。\e[0m"
fi
echo -e \\n"\e[1;33m〘$s〙更新完成...$(timenow)...\e[0m"\\n
}

up () {
up_sh
up_pf
}
up_and_renew () {
force_renew=1
up
}
cron_update_all () {
#延迟100秒内启动
random_mum=$(cat /proc/sys/kernel/random/uuid | sed 's/[a-zA-Z]//g;s/-//g' | head -c 2)
[ -z "$(echo $random_mum | grep -E '^[0-9]+$')" ] && random_mum=0
echo -e \\n"[$(timenow)] Start cron_update_all after a 〘$random_mum〙 second break"\\n
sleep $random_mum
up_pf
bash ${path}/${bashname} up_and_renew
}


set_path () {
if [ ! -s /etc/storage/profile -o -z "`grep "storage/pdcn" /etc_ro/profile`" ] ; then
	echo -e \\n"\e[1;36m■设置环境变量\e[0m"
	[ ! -z "`grep "storage/pdcn" /etc_ro/profile`" ] && umount /etc_ro/profile
	oldpath=`cat /etc_ro/profile |awk -F\' '/export PATH/{print $2}'|tail -n 1`
	newpath="/etc/storage:/etc/storage/pdcn"
	cp -f /etc_ro/profile /etc/storage/profile
	sed -i "/export PATH/s@$oldpath@$oldpath:$newpath@g" /etc/storage/profile
	mount --bind /etc/storage/profile /etc_ro/profile
	source /etc/profile
	if [ ! -z "`df -h|grep profile`" ] ; then
		echo "✔ 环境变量profile挂载成功！" && logger -t "【${bashname}】" "✔ 环境变量profile挂载成功！"
	else
		echo "✖ 环境变量profile挂载失败！" && logger -t "【${bashname}】" "✖ 环境变量profile挂载失败！"
	fi
fi
[ -z "$(pidof crond)" ] && echo "▶启动crontab进程crond " && crond
up_pf &
}
un_set_path () {
[ ! -z "`grep "storage/pdcn" /etc_ro/profile`" ] && echo -e \\n"\e[1;36m□还原环境变量\e[0m" && umount /etc_ro/profile && source /etc/profile
[ -s /etc/storage/profile ] && echo -e \\n"\e[1;36m□删除环境变量文件/etc/storage/profile\e[0m" && rm /etc/storage/profile
}


stop () {
stop_cron
stop_wan
un_set_path
}

start_1 () {
stop
set_path
start_wan
}

start_2 () {
stop
set_path
start_wan
start_cron
}

start_3 () {
stop
set_path
start_wan
start_cron_3
}


#7
resettings () {
echo -e \\n"\e[1;37m--------------------\\n    【重置参数】\\n当前settings设置参数列表\\n$dirconf/$name/settings.txt\\n--------------------\e[0m"
if [ ! -d $dirconf/$name ] ; then
mkdir -p $dirconf/$name
else
[ ! -f $dirconf/$name/settings.txt ] && > $dirconf/$name/settings.txt 
fi
if [ -s $dirconf/$name/settings.txt ] ; then
cat $dirconf/$name/settings.txt | awk '{print "\e[1;33m第"NR"行\e[0m " "\e[1;36m" $0 "\e[0m"}'
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
		vi $dirconf/$name/settings.txt
	else
		echo -e \\n"\e[1;37m✖输入非0、1，退出脚本 \e[0m"\\n
	fi
else
	echo -e \\n"\e[1;37m✖输入非数字，退出脚本 \e[0m"\\n
fi
}


other () {
start_wan
start_cron_3

}


view_all_logs () {
log_file=${bashname}_cron_update_all.txt && [ -s $tmp/$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && cat $tmp/$log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
}

toilet_font () {
echo "
┌─────────────────┐
│░█▀█░█▀▄░█▀▀░█▀█░│
│░█▀▀░█░█░█░░░█░█░│
│░▀░░░▀▀░░▀▀▀░▀░▀░│
└─────────────────┘
"
}

#状态
zhuangtai () {
toilet_font
echo -e "\e[1;33m当前状态：\e[0m"\\n
if [ ! -z "$(df -h|grep profile)" ] ; then
	echo -e "● \e[1;36m ${name} 环境变量：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 环境变量：\e[1;31m【未启用】\e[0m"
fi
if [ ! -z "$(cat $file_wan | grep ${bashname})" ] ; then
	echo -e "● \e[1;36m ${name} 开机自启：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 开机自启：\e[1;31m【未启用】\e[0m"
fi
if [ ! -z "$(cat $file_cron | grep ${bashname} | grep ' up ')" ] ; then
	echo -e "● \e[1;36m ${name} 定时重启②：\e[1;32m【已启用】\e[0m"
elif [ ! -z "$(cat $file_cron | grep ${bashname} | grep ' cron_update_all ')" ] ; then
	echo -e "● \e[1;36m ${name} 定时任务③：\e[1;32m【已启用】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 定时任务：\e[1;31m【未启用】\e[0m"
fi
}

#按钮
case $1 in
0|stop)
	stop
	;;
1|start_1)
	start_1
	;;
2|start_2)
	start_2
	;;
3|start_3)
	start_3
	;;
7)
	resettings
	;;
8|up)
	force_url=$2
	[ -z "$(echo $force_url | grep -E '^[0-9]+$')" ] && force_url=""
	up &
	;;
9|up_and_renew)
	other
	force_url=$2
	[ -z "$(echo $force_url | grep -E '^[0-9]+$')" ] && force_url=""
	up_and_renew &
	;;
10|cron_update_all)
	other
	force_url=$2
	[ -z "$(echo $force_url | grep -E '^[0-9]+$')" ] && force_url=""
	cron_update_all
	;;
up_sh)
	force_url=$2
	[ -z "$(echo $force_url | grep -E '^[0-9]+$')" ] && force_url=""
	up_sh &
	;;
up_pf)
	force_url=$2
	[ -z "$(echo $force_url | grep -E '^[0-9]+$')" ] && force_url=""
	up_pf &
	;;
update_pf)
	up_pf
	;;
set_path)
	set_path
	;;
un_set_path)
	un_set_path
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
	start_cron_3
	;;
*)
	#状态
	zhuangtai
	#
	echo -e \\n"\e[1;33m脚本管理：\e[0m\e[37m『 \e[0m\e[1;37m$sh_ver\e[0m\e[37m 』\e[0m"\\n
	echo -e "\e[1;32m【0】\e[0m\e[1;36m stop：还原设置 \e[0m "
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start_1：自启设置环境变量 \e[0m "
	echo -e "\e[1;32m【2】\e[0m\e[1;36m start_2：自启设置环境变量、定时更新脚本 \e[0m "
	echo -e "\e[1;32m【3】\e[0m\e[1;36m start_3：自启设置环境变量、定时更新脚本与资源文件 \e[0m "
	echo -e "\e[1;32m【7】\e[0m\e[1;36m resettings：重置初始化配置\e[0m"
	echo -e "\e[1;32m【8】\e[0m\e[1;36m up：更新脚本 \e[0m"
	echo -e "\e[1;32m【9】\e[0m\e[1;36m up_and_renew：更新脚本与资源文件 \e[0m"\\n
	read -n 1 -p "请输入数字:" num
	if [ "$num" = "0" ] ; then
		stop
	elif [ "$num" = "1" ] ; then
		start_1
	elif [ "$num" = "2" ] ; then
		start_2
	elif [ "$num" = "3" ] ; then
		start_3
	elif [ "$num" = "7" ] ; then
		resettings
	elif [ "$num" = "8" ] ; then
		up &
	elif [ "$num" = "9" ] ; then
		up_and_renew &
	else
		echo -e \\n"\e[1;31m输入错误。\e[0m "\\n
	fi
	;;
esac
