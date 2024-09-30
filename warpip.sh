#!/bin/bash
sh_ver=35

#Github @luoxue-bot
#Blog https://ty.al
#https://github.com/luoxue-bot/warp_auto_change_ip/blob/main/warp_change_ip.sh


path=${0%/*}
bashname=${0##*/}
bashpid=$$

[ "$path" = "$bashname" ] && path=.
cd $path


name=$bashname
UA_Browser="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36"

if [ ! -z "$(ps -ef 2>&1 | grep -v grep | grep invalid)" ] ; then
pss='ps -w'
else
pss='ps -ef'
fi

check_netflix () {
area=$1
[ -z "$area" ] && area=""

network=$3
[ -z "$network" ] && network=4

if [ -z "$2" ] ; then
curl="curl"
proxy=""
else
curl="curl -x socks5h://127.0.0.1:$2"
proxy="(走本地socks5代理端口：$2)"
fi

n=1
m=1
t=0
tt=10
sleep_time=60
while true
do
	test_warp=$($curl -${network} -m 15 -sL https://cp.cloudflare.com/cdn-cgi/trace)
	warp_status=$(echo $test_warp | sed 's/ /\n/g'|awk -F= '/warp=/{print $2}')
	if [ ! -z "$warp_status" ] ; then
		if [ "$warp_status" = "on" -o "$warp_status" = "plus" ] ; then
			warp=1
		else
			n=0
			ip=$(echo $test_warp | sed 's/ /\n/g'|awk -F= '/ip=/{print $2}')
			echo -e "✖ $(date "+%Y-%m-%d_%H:%M:%S") [$n]「warp=$warp_status」$ip 当前非warp网络，请自行用wgcf安装cloudflare warp VPN后再启动脚本。60秒后重试，如不想继续重试请手动结束脚本。...$proxy"
			sleep 60
			continue
		fi
	else
		n=0
		mm=3
		if [ "$m" -ge "$mm" ] ; then
			echo -e "✖ $(date "+%Y-%m-%d_%H:%M:%S") [$m/$mm] 网络错误，获取warp status为空。重启warp。60秒后重试...$proxy"
			systemctl restart wg-quick@wgcf
			m=1
			sleep 60
		else
			echo -e "✖ $(date "+%Y-%m-%d_%H:%M:%S") [$m/$mm] 网络错误，获取warp status为空。跳过本次循环，5秒后重新连接...$proxy"
			m=$((m+1))
			sleep 5
		fi
		continue
	fi
	result=$($curl -${network} -m 15 --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81215567" 2>&1)
	ip=$($curl -${network} -m 15 --user-agent "${UA_Browser}" -sL https://checkip.amazonaws.com)
	if [ ! -z "$(echo $result | grep -Ei 404)" ] ; then
		[ "$t" -le "$tt" ] && sleep_time=$((60+t*30)) && t=$((t+1))
		echo -e "✖ $(date "+%Y-%m-%d_%H:%M:%S") [$n]「$result」$ip 仅自制剧，刷新warp IP...$proxy。休息 $sleep_time 秒后重试..."
		systemctl restart wg-quick@wgcf
		sleep $sleep_time
		n=0
	elif [ ! -z "$(echo $result | grep -Ei 403)" ] ; then
		if [ -z "$ip" ] ; then
			echo -e "✖ $(date "+%Y-%m-%d_%H:%M:%S") [$n]「$result」$ip 错误，刷新warp IP...60秒后重试..$proxy"
			systemctl restart wg-quick@wgcf
			sleep 60
			n=0
		else
			echo -e "？ $(date "+%Y-%m-%d_%H:%M:%S") [$n] $ip 存在，但「$result」，休息 600 秒后重试..."
			sleep 600
			#n=0
		fi
	elif [ ! -z "$(echo $result | grep -Ei 200)" ] ; then
		region=$($curl -${network} -m 15 --user-agent "${UA_Browser}" -is "https://www.netflix.com/title/80018499" 2>&1 | awk -F/ '/^location:/{print $4}')
		[ -z "$region" ] && region="US"
		if [ ! -z "$area" ] ; then
			if [ -z "$(echo $region | grep -Ei $area)" ] ; then
				echo -e "✖ $(date "+%Y-%m-%d_%H:%M:%S") [$n]「$result」$ip 地区: 【${region}】 不匹配 $area ， 刷新 warp IP...60秒后重试..$proxy"
				systemctl restart wg-quick@wgcf
				sleep 60
				n=0
			else
				echo -e "$(date "+%Y-%m-%d_%H:%M:%S") [$n]「$result」$ip 地区: 【${region}】 已解锁， 休息 600 秒 ✔...$proxy"
				sleep 600
				t=0
			fi
		else
			echo -e "$(date "+%Y-%m-%d_%H:%M:%S") [$n]「$result」$ip 随机获取到默认地区: 【${region}】 已解锁， 休息 600 秒 ✔...$proxy"
			sleep 600
			t=0
		fi
	elif [ ! -z "$(echo $result | grep -Ei 000)" ] ; then
		mm=5
		if [ "$m" -gt "$mm" ] ; then
			echo -e "✖ $(date "+%Y-%m-%d_%H:%M:%S") [$m/$mm]「$result」$ip 网络错误。重启warp，60秒后重试..$proxy"
			systemctl restart wg-quick@wgcf
			m=1
		else
			echo -e "✖ $(date "+%Y-%m-%d_%H:%M:%S") [$m/$mm]「$result」$ip 网络错误，60秒后重试..$proxy"
			m=$((m+1))
		fi
		sleep 60
	fi
	n=$((n+1))
done
}


stop () {
pid=$($pss | grep -v grep | grep -Ei "$bashname start")
if [ ! -z "$pid" ] ; then
echo -e \\n"结束脚本进程\\n$pid"\\n
$pss | grep -v grep | grep -Ei "$bashname start|tee.*warpip.txt" | awk '{print $2}' | xargs kill -9
fi
}

start () {
check_netflix $1 $2 $3 | tee /tmp/warpip.txt 2>&1 &
}


function netflix () {
name="Netflix"
network=$1
[ -z "$network" ] && network=4
if [ -z "$2" ] ; then
curl="curl"
proxy=""
else
curl="curl -x socks5h://127.0.0.1:$2"
proxy="，走本地socks5代理端口：$2"
fi
##
result=$($curl -$network --user-agent "${UA_Browser}" -fsL --write-out %{http_code} --output /dev/null --max-time 10 "https://www.netflix.com/title/81280792" 2>&1)
if [ "$result" = "404" ] ; then
echo -e \\n"▶测试ipv$1 $name$proxy\\n\e[32m $name 仅自制剧\e[0m"
elif [ "$result" = "403" ] ; then
echo -e \\n"▶测试ipv$1 $name$proxy\\n\e[1;31m $name 不支持，页面错误403\e[0m"
elif [ "$result" = "200" ] ; then
region=$($curl -$network --user-agent "${UA_Browser}" -is "https://www.netflix.com/title/80018499" 2>&1 | awk -F/ '/^location:/{print $4}')
if [ ! -z "$region" ] ; then
echo -e \\n"▶测试ipv$1 $name$proxy\\n\e[1;32m $name 完全支持，地区：\e[1;33m${region}\e[0m"
else
echo -e \\n"▶测试ipv$1 $name$proxy\\n\e[1;32m $name 完全支持，地区为空，可能为 \e[1;33mUS\e[0m"
fi
elif [ "$result" = "000" ] ; then
echo -e \\n"▶测试ipv$1 $name$proxy\\n\e[1;31m $name 网络错误，000\e[0m"
fi
}

function youtube () {
name="YouTube"
network=$1
[ -z "$network" ] && network=4
if [ -z "$2" ] ; then
curl="curl"
proxy=""
else
curl="curl -x socks5h://127.0.0.1:$2"
proxy="，走本地socks5代理端口：$2"
fi
##
#result=$($curl -$network --user-agent "${UA_Browser}" -sL --max-time 10 "https://www.youtube.com/red" | sed 's/,/\n/g' | grep "countryCode" | cut -d '"' -f4 )
result=$($curl -$network --user-agent "${UA_Browser}" -sL -m 10 "https://www.youtube.com/premium" 2>&1)
if [ -z "$result" ] ; then
echo -e \\n"▶测试ipv$1 $name$proxy\\n\e[1;31m $name 网络错误，result为空\e[0m"
elif [ ! -z "$(echo $result | grep curl)" ] ; then
echo -e \\n"▶测试ipv$1 $name$proxy\\n\e[1;31m $name 网络错误，curl访问失败\e[0m"
else
	if [ ! -z "$(echo $result | grep countryCode)" ] ; then
	result=$(echo $result | sed 's/,/\n/g' |awk -F'"' '/countryCode/{print $4}')
	echo -e \\n"▶测试ipv$1 $name$proxy\\n\e[1;32m $name 完全支持，地区countryCode：\e[1;33m${result}\e[0m"
	elif [ ! -z "$(echo $result | grep INNERTUBE_CONTEXT_GL)" ] ; then
	result=$(echo $result | sed 's/,/\n/g' |awk -F'"' '/INNERTUBE_CONTEXT_GL/{print $4}')
	echo -e \\n"▶测试ipv$1 $name$proxy\\n\e[1;32m $name 完全支持，地区：\e[1;33m${result}\e[0m"
	else
	echo -e \\n"▶测试ipv$1 $name$proxy\\n\e[1;32m $name 地区为空，可能为 \e[1;33mUS\e[0m"
	fi
fi
}

check () {
echo -e \\n"\e[1;36m Netflix流媒体解锁正在测试中，请稍候...\e[0m"\\n
netflix 4 $1 &
netflix 6 $1 &
wait
echo -e \\n"\e[1;36m YouTube流媒体解锁正在测试中，请稍候...\e[0m"\\n
youtube 4 $1 &
youtube 6 $1 &
wait
echo -e \\n"\e[1;36m......测试结束......\e[0m"\\n
}

restart_warp_cli () {
warp-cli disable-always-on
warp-cli disconnect
kill -9 $(pidof warp-svc)
warp-cli connect
warp-cli enable-always-on
}

view_all_logs () {
log_file=warpip.txt && [ -s /tmp/$log_file ] && echo -e "\\n\e[1;37m▼▼▼▼▼▼▼▼ \e[1;36m 查看日志\e[1;32m $log_file \e[1;37m▼▼▼▼▼▼▼▼\e[0m" && tail -n 100 /tmp/$log_file | grep -v '^ *$' | awk '{print "\e[1;33m第"NR"行\e[0m " $0}' && echo -e "\e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[1;4;32m $log_file \e[1;4;37m▲▲▲▲▲▲▲▲▲▲▲▲▲▲\e[0m\\n"
}

toilet_font () {
echo "
┌─────────────────┐
│░█░█░█▀█░█▀▄░█▀█░│
│░█▄█░█▀█░█▀▄░█▀▀░│
│░▀░▀░▀░▀░▀░▀░▀░░░│
└─────────────────┘
"
}

zhuangtai () {
toilet_font
echo -e "\e[1;33m当前状态：\e[0m"\\n
pid=$($pss | grep -v grep | grep -Ei "$bashname start" | awk '{print $2}')
if [ ! -z "$pid" ] ; then
	echo -e "● \e[1;36m ${name} 进程：\e[1;32m【已运行】\e[0m"
else
	echo -e "○ \e[1;36m ${name} 进程：\e[1;31m【未运行】\e[0m"
fi
}



case $1 in
0)
	stop
	;;
1)
	stop
	bash $path/$bashname start $2 $3 $4
	;;
2|log)
	view_all_logs
	;;
3)
	systemctl restart wg-quick@wgcf
	;;
4)
	systemctl restart warp-go
	;;
5)
	restart_warp_cli
	;;
9|check)
	check $2 &
	;;
start)
	start $2 $3 $4
	;;
*)
	#状态
	zhuangtai
	#
	echo -e \\n"\e[1;33m脚本管理：\e[0m\e[37m『 \e[0m\e[1;37m$sh_ver\e[0m\e[37m 』\e[0m"\\n
	echo -e "\e[1;32m【0】\e[0m\e[1;36m stop：关闭所有 \e[0m "
	echo -e "\e[1;32m【1】\e[0m\e[1;36m start：启动$name\e[0m"
	echo -e "\e[1;32m【2】\e[0m\e[1;36m log：查看日志\e[0m"
	echo -e "\e[1;32m【3】\e[0m\e[1;36m restart：重启wgcf\e[0m"
	echo -e "\e[1;32m【4】\e[0m\e[1;36m restart：重启warp-go\e[0m"
	echo -e "\e[1;32m【5】\e[0m\e[1;36m restart：重启warp-cli\e[0m"
	echo -e "\e[1;32m【9】\e[0m\e[1;36m check：测试流媒体解锁\e[0m"\\n
	read -n 1 -p "请输入数字:" num
	if [ "$num" = "0" ] ; then
		stop
	elif [ "$num" = "1" ] ; then
		echo -e \\n\\n"请输入[地区]："
		read area
		[ -z "$area" ] && echo "地区为空，将使用默认分配地区"
		echo -e \\n\\n"请输入[socks5端口]："
		read socks5
		[ -z "$socks5" ] && echo "socks5端口为空，不走proxy socks5" && socks5=""
		echo -e \\n\\n"请输入[network网络类型]，默认4："
		read network
		[ -z "$network" ] && echo "network为空" && network=""
		stop
		bash $path/$bashname start $area $socks5 $network
	elif [ "$num" = "2" ] ; then
		view_all_logs
	elif [ "$num" = "3" ] ; then
		systemctl restart wg-quick@wgcf
	elif [ "$num" = "4" ] ; then
		systemctl restart warp-go
	elif [ "$num" = "5" ] ; then
		restart_warp_cli
	elif [ "$num" = "9" ] ; then
		echo -e \\n\\n"请输入[socks5端口]："
		read socks5
		[ -z "$socks5" ] && echo "socks5端口为空，不走proxy socks5" && socks5=""
		check $socks5 &
	else
		echo -e \\n"\e[1;31m输入错误。\e[0m "\\n
	fi
	;;
esac
