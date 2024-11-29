#!/bin/bash
sh_ver=111

bashpath=${0%/*}
bashname=${0##*/}
bashpid=$$

dir=/tmp/cf
diretc=$bashpath/cf
tmp=/tmp
dirconf=$diretc
[ ! -d $diretc ] && mkdir -p $diretc

if [ -f $diretc/settings.txt ] ; then
	for a in $(cat $dirconf/settings.txt | grep '=' | grep -Ev '^#' | sed '1!G;h;$!d') ; do n=$(echo $a | awk -F= '{print $1}') ; b=$(echo $a | sed "s/${n}=//g") ; eval $n=$b ; done
else
	> $diretc/settings.txt
fi

#alias
[ "$(shopt 2>/dev/null | awk '/expand_aliases/{print $2}')" = "off" ] && shopt -s expand_aliases
alias timenow='date "+%m-%d_%H:%M:%S"'

[ ! -d $dir ] && mkdir -p $dir
cd $dir


if [ -z "$url" ] ; then
#url=http://speedtest-sgp1.digitalocean.com/1gb.test
#url=http://speedtest-lon1.digitalocean.com/1gb.test
#url=http://speedtest-sfo2.digitalocean.com/1gb.test
#url=http://speedtest-fra1.digitalocean.com/1gb.test
url=http://speed.cloudflare.com/__down?bytes=10000000000
#url=https://speed.cloudflare.com/__down?bytes=10000000000
fi
if [ ! -z "$(echo $url | grep '^https://')" -o ! -z "$(echo $url | grep '^http://')" ] ; then
	url_domain=$(echo $url | awk -F/ '{print $3}')
	[ ! -z "$(echo $url | grep '^https://')" ] && url_port=443
	[ ! -z "$(echo $url | grep '^http://')" ] && url_port=80
else
	echo "✖ speedtest测速文件url不合法：$url"
fi

[ -z "${http_tls}" ] && http_tls=http
if [ "${http_tls}" = "https" ] ; then
http_port=443
else
http_tls=http
http_port=80
fi


#1
one () {
if [ ! -d ./one ] ;then
	mkdir -p ./one
else
	rm -rf ./one && mkdir -p ./one
fi
[ ! -z "$(ls | grep 'one_*')" ] && rm -rf ./one_*
[ ! -s ./ip.txt ] && echo -e \\n\\n"\e[1;31m！！检测到不存在 ip.txt 文件，结束脚本。请先执行nmap操作批量查询IP。\e[0m"\\n && exit
#> ./one.txt
> ./one_start_$(date "+%Y-%m-%d_%H:%M:%S")
#设置线程数
xianchen=100
#########
all_hang=`sed -n '$=' ./ip.txt`
hang=$(($all_hang/$xianchen+1))
echo -e \\n\\n"\e[1;36m ip.txt IP列表文件总行数\e[1;32m $all_hang \e[1;36m，线程数为\e[1;32m $xianchen \e[1;36m，每线程分配处理行数\e[1;32m $hang \e[0m"\\n
[ -z "`split --version`" ] && echo -e "\e[1;33m >>检测到opt需要安装split～\e[0m" && /opt/bin/opkg update && /opt/bin/opkg install coreutils-split
split -l $hang ./ip.txt -d -a 2 ./one/ip.txt_part

file=`find ./one | awk 'NR>1{print $0}'`
for ipfile in $file
do
{
	echo "1～读取IP文件列表：$ipfile"
	x=`cat $ipfile |awk '{print $2}'`
	for ip in $x
	do
	{
		echo "    2～批量查地区 curl：$ip"
		site=$(curl -sL -m 5 ${http_tls}://cp.cloudflare.com/cdn-cgi/trace --resolve cp.cloudflare.com:${http_port}:$ip |awk -F= '/^colo/{print $2}')
		echo ${site} $ip >> ./one_run.txt
	}
	done
}&
done
wait
#成功 IP
cat ./one_run.txt | grep " " | sort -u > ./1.txt
#失败IP
cat ./one_run.txt | sed "/ /d" | sort -u > ./0.txt
> ./one_ok_$(date "+%Y-%m-%d_%H:%M:%S")
}

#2
again () {
#重复筛选
if [ ! -d ./again ] ;then
	mkdir -p ./again
else
	rm -rf ./again && mkdir -p ./again
fi
[ ! -z "$(ls | grep 'again_*')" ] && rm -rf ./again_*
[ ! -s ./0.txt ] && echo -e \\n\\n"\e[1;31m！！检测到不存在 0.txt 失效文件，结束脚本。请先执行one操作批量查询IP。\e[0m"\\n && exit
#若存在FINAL_NEW_*文件，先删除旧文件，再把新文件改名为FINAL_old_*
[ -s ./FINAL_NEW_* ] && rm -rf ./FINAL_old_* && mv -f `ls ./FINAL_NEW_*` `ls ./FINAL_NEW_* | sed 's/NEW/old/'`
#把失败 0.txt 导入到 again_0.txt里
cat ./0.txt > ./again_0.txt
#> ./again.txt
> ./again_start_$(date "+%Y-%m-%d_%H:%M:%S")
#设置线程数
xianchen=100
#########
all_hang=`sed -n '$=' ./again_0.txt`
hang=$(($all_hang/$xianchen+1))
echo -e \\n\\n"\e[1;36m again_0.txt IP列表文件总行数\e[1;32m $all_hang \e[1;36m，线程数为\e[1;32m $xianchen \e[1;36m，每线程分配处理行数\e[1;32m $hang \e[0m"\\n
[ -z "`split --version`" ] && echo -e "\e[1;33m >>检测到opt需要安装split～\e[0m" && /opt/bin/opkg update && /opt/bin/opkg install coreutils-split
split -l $hang ./again_0.txt -d -a 2 ./again/again_0.txt_part
file=`find ./again | awk 'NR>1{print $0}'`
for ipfile in $file
do
{
	echo "1～读取IP文件列表：$ipfile"
	y=`cat $ipfile`
	for ip in $y
	do
	{
		echo "    2～批量查地区 curl：$ip"
		site=$(curl -sL -m 5 ${http_tls}://cp.cloudflare.com/cdn-cgi/trace --resolve cp.cloudflare.com:${http_port}:$ip |awk -F= '/^colo/{print $2}')
		echo ${site} $ip >> ./again_run.txt
	}
	done
}&
done
wait
#成功IP
cat ./again_run.txt | grep " " >> ./1.txt
sort -u ./1.txt > ./FINAL_NEW_`sed -n '$=' ./1.txt`.TXT
awk '{print $2}' ./1.txt > ./pingip.txt
[ "$start_all" = "1" ] && cp -f ./pingip.txt $diretc/pingip.txt
#失败IP
cat ./again_run.txt | sed "/ /d" | sort -u > ./0.txt
> ./again_ok_$(date "+%Y-%m-%d_%H:%M:%S")
}

#3
nmap_ () {
if [ ! -d ./nmap ] ;then
	mkdir -p ./nmap
else
	rm -rf ./nmap && mkdir -p ./nmap
fi
[ ! -z "$(ls | grep 'nmap_*')" ] && rm -rf ./nmap_*
[ -z "`nmap`" ] && echo -e "\e[1;36m >>检测到opt需要安装nmap～\e[0m" && /opt/bin/opkg update && /opt/bin/opkg install nmap
echo -e \\n\\n"\e[1;36m～开始批量nmap扫描 IP～\e[0m"
#检查是否存在自定义IP列表文件testip.txt，不存在则使用自带IP列表
if [ ! -s /tmp/testip.txt ] ; then
	echo "103.21.244-247.22
103.22.200-203.22
103.31.4-7.22
104.16.0-255.12
104.17.0-255.12
104.18.0-255.12
104.19.0-255.12
104.20.0-255.12
104.21.0-255.12
104.22.0-255.12
104.23.0-255.12
104.24.0-255.12
104.25.0-255.12
104.26.0-255.12
104.27.0-255.12
104.28.0-255.12
104.29.0-255.12
104.29.64.0-255
104.30.0-255.12
104.31.0-255.12
108.162.192-255.18
131.0.72-75.22
141.101.64-127.18
162.158.0-255.15
162.159.0-255.15
172.64.0-255.13
172.65.0-255.13
172.66.0-255.13
172.67.0-255.13
172.68.0-255.13
172.69.0-255.13
172.70.0-255.13
172.71.0-255.13
173.245.48-63.20
188.114.96-111.20
190.93.240-255.20
197.234.240-243.22
198.41.128-255.17
103.184.44.24
103.184.45.24
167.224.32.24
185.16.110.24
192.0.54.24
192.0.63.24
192.200.160.24
194.76.18.24
198.62.62.24
212.183.88.24
216.24.57.24
45.67.215.24
63.141.128.24
185.133.35.24
43.245.41.24
69.84.182.24" > ./testip.txt
else
	echo "使用自定义IP列表/tmp/testip.txt"
	cp -f /tmp/testip.txt ./testip.txt
fi
sed -i '/#/d' ./testip.txt
#> ./nmapip.txt
> ./nmap_start_$(date "+%Y-%m-%d_%H:%M:%S")
#设置线程数
xianchen=50
#########
all_hang=`sed -n '$=' ./testip.txt`
hang=$(($all_hang/$xianchen+1))
echo -e \\n"\e[1;36m testip.txt IP列表文件总行数\e[1;32m $all_hang \e[1;36m，线程数为\e[1;32m $xianchen \e[1;36m，每线程分配处理行数\e[1;32m $hang \e[0m"\\n
[ -z "`split --version`" ] && echo -e "\e[1;33m >>检测到opt需要安装split～\e[0m" && /opt/bin/opkg update && /opt/bin/opkg install coreutils-split
split -l $hang ./testip.txt -d -a 2 ./nmap/nmap_part
file=`find ./nmap | awk 'NR>1{print $0}'`
for nmapfile in $file
do
{
	echo "1～读取nmap IP文件列表：$nmapfile"
	x=$nmapfile
	for ip in $x
	do
	{
		echo "    2～批量nmap ping：$ip"
		nmap -n -sn -iL $ip >> ./nmap_run.txt
	}
	done
}&
done
wait
cat ./nmap_run.txt | sed ":a;N;s/\nHost/ Host/g;ba" |grep -Eo '([0-9]+\.){3}[0-9]+.*latency' |awk '{print $5 " " $1 }' |sed 's@(\|)@@g' | sort -u > ./ip.txt
> ./nmap_ok_$(date "+%Y-%m-%d_%H:%M:%S")
}


#4
get_cf_ipv6 () {
# cloudflare ipv6 
cf="2606:4700"
#cf="2400:cb00"
#cf="2405:8100"
#cf="2405:b500"
#cf="2803:f800"
#cf="2a06:98c0"
#cf="2c0f:f248"

#测试IP数
t=1
tt=65500
#tt=10000

#多线程
pp=100

#bashpath=${0%/*}
#cd $bashpath
echo -e \\n"START：$(timenow)"\\n
> ./get_cf_ipv6_start_$(date "+%Y-%m-%d_%H:%M:%S")
> ipv6_colo.txt
while true
do
progress=$((100*$t/$tt))
p=$(ps -w |grep -v grep| grep -E "curl.*trace" | wc -l)
if [ $p -gt $pp ] ; then
	echo -e "▷$(timenow) $ip 进程数：$p/$pp，休息一秒。处理IP数：$t/$tt，进度：$progress %"
	sleep 1
else
	if [ $t -le $tt ] ; then
		{
		n=$(printf "%x" "$t")
		#测试IP段
		ip="$cf:$n::11"
		colo=$(curl -sL -m 5 ${http_tls}://cp.cloudflare.com/cdn-cgi/trace --resolve cp.cloudflare.com:${http_port}:$ip |awk -F= '/^colo/{print $2}')
		[ -z "$colo" ] && colo="-"
		echo "$t $ip $colo" >> ipv6_colo.txt
		} &
		#echo -e "▶$(timenow) $ip 进程数：$p/$pp，处理IP数：$t/$tt，进度：$progress %"
		[ ! -z "$(ls | grep 'working_*')" ] && rm -rf ./working_*
		> ./working_[$p／$pp]_[$t／$tt]_${progress}_%
		t=$((t+1))
	else
		break
	fi
fi
done
echo -e \\n"$t/$tt已完成，等待进程处理结束，$(date "+%Y-%m-%d_%H:%M:%S")..."
[ ! -z "$(ls | grep 'working_*')" ] && rm -rf ./working_*
> ./working_100%_waiting
wait
cat ipv6_colo.txt | grep -Ev ' -$| $' | sort -k 3,3r -k 1,1n > ipv6.txt
awk '{print $2}' ipv6.txt > pingip.txt6
[ ! -z "$(ls | grep 'working_*')" ] && rm -rf ./working_*
> ./working_OK
echo -e \\n"END：$(timenow)"\\n
> ./get_cf_ipv6_ok_$(date "+%Y-%m-%d_%H:%M:%S")
}


#5
pingip () {
echo "pingip_start_$(date "+%Y-%m-%d_%H:%M:%S")"
> ./pingip_start_$(date "+%Y-%m-%d_%H:%M:%S")
rm ./pingip_run*
if [ ! -s ./pingip.txt ] ; then
	if [ -s $diretc/pingip.txt ] ; then
		echo -e \\n"使用闪存etc里的IP列表$diretc/pingip.txt"
		dir_pingip=$diretc/pingip.txt
	else
		echo -e \\n\\n"！！检测到$dir、$diretc都不存在IP列表文件pingip.txt，结束脚本。"\\n && exit
	fi
else
	dir_pingip=./pingip.txt
fi
#同时处理IP数
pp=150
#总IP数
tt=$(sed -n '$=' $dir_pingip)
echo -e \\n\\n" IP列表文件pingip.txt总行数 $tt ，同时处理IP数 $pp  "\\n
t=1
ping_cishu=20
for ip in $(cat $dir_pingip)
do
{
	while true
	do
		progress=$((100*$t/$tt))
		p=$(ps -w |grep -v grep| grep ping | wc -l)
		#大于进程数则休眠1秒
		if [ $p -gt $pp ] ; then
			echo -e "▷$(timenow) $ip 进程数：$p/$pp，休息一秒。处理IP数：$t/$tt，进度：$progress %"
			sleep 1
		else
			#echo -e "▶$(timenow) $ip 进程数：$p/$pp，处理IP数：$t/$tt，进度：$progress %"
			[ ! -z "$(ls | grep 'working_*')" ] && rm -rf ./working_*
			> ./working_[$p／$pp]_[$t／$tt]_${progress}_%
			start_ping &
			t=$((t+1))
			break
		fi
	done
}
done
echo -e \\n"🕚$(timenow) 等待进程全部运行结束⏳⏳⏳.... "
[ ! -z "$(ls | grep 'working_*')" ] && rm -rf ./working_*
> ./working_100%_waiting
wait
echo -e "✔ $(timenow) 进程已运行完成！按丢包率与延迟排序生成结果文件 ping.txt "
[ ! -z "$(ls | grep 'working_*')" ] && rm -rf ./working_*
> ./working_OK
[ ! -s /opt/bin/sort ] && echo -e " >> opkg安装coreutils版sort..." && /opt/bin/opkg update && /opt/bin/opkg install coreutils-sort
cat ./pingip_run_1.txt | grep -v 'null' | sort -n -t ' ' -k 7,7 -k 11,11 | sed 's/HKG/🇭🇰香港/g;s/MFM/🇲🇴澳门/g;s/KHH/🇹🇼台湾·高雄/g;s/KIX/🇯🇵日本·大阪/g;s/NRT/🇯🇵日本·东京/g;s/SIN/🇸🇬新加坡/g;s/LAS/🇺🇸美国·拉斯维加斯/g;s/LAX/🇺🇸美国·洛杉矶/g;s/DFW/🇺🇸美国·达拉斯/g;s/SJC\|SJC-PIG/🇺🇸美国·圣何塞/g;s/SEA/🇺🇸美国·西雅图/g;s/IAD/🇺🇸美国·华盛顿/g;s/EWR/🇺🇸美国·紐瓦克/g;s/PHX/🇺🇸美国·鳳凰城/g;s/PDX/🇺🇸美国·波特兰/g;s/ATL/🇺🇸美国·亞特蘭大/g;s/JAX/🇺🇸美国·杰克逊维尔/g;s/MSP/🇺🇸美国·明尼阿波利斯圣保罗/g;s/DTW/🇺🇸美国·底特律/g;s/OMA/🇺🇸美国·奥马哈/g;s/YVR/🇨🇦加拿大·溫哥華/g;s/LHR/🇬🇧英国·伦敦/g;s/FRA/🇩🇪德国·法兰克福/g;s/DUS/🇩🇪德国·杜塞尔多夫/g;s/HAM/🇩🇪德国·汉堡/g;s/MRS/🇫🇷法国·马赛普罗旺斯/g;s/CDG/🇫🇷法国·巴黎/g;s/CPH/🇩🇰丹麦·哥本哈根/g;s/AMS/🇳🇱荷兰·阿姆斯特丹/g;s/DME/🇷🇺俄罗斯·莫斯科/g;s/OTP/🇷🇴罗马尼亚·奥托佩尼/g;s/CCU/🇮🇳印度·加爾各答/g;s/HYD/🇮🇳印度·海得拉巴/g;s/DEL/🇮🇳印度·新德里/g;s/BLR/🇮🇳印度·班加羅爾/g;s/CGK/🇮🇩印尼·雅加达/g;s/DXB/🇦🇪阿拉伯·迪拜/g;s/MNL/🇵🇭菲律宾·马尼拉/g;s/ALA/🇰🇿哈薩克斯坦·阿拉木圖/g;s/JDO/🇧🇷巴西·北茹阿泽鲁/g;s/GRU/🇧🇷巴西·圣保罗/g;s/EZE/🇦🇷阿根廷·布宜诺斯艾利斯/g' | sed "1i\\\n######【ping】$(date "+%Y-%m-%d %H:%M:%S") #######\n" > ./ping.txt
cat ./pingip_run_1.txt | grep -v 'null' | awk '{print $1}' > ./pingip.txt_1
#低延迟分开
sed -ri '/香港.* [0-9]{2} ms/s/香港/hk/g' ./ping.txt
#分172开头
sed -ri '/^172..*hk/s/hk/hk172/g' ./ping.txt
sed -ri '/^172..*美国/s/美国/US172/g' ./ping.txt
sed -ri '/^172..*德国/s/德国/DE172/g' ./ping.txt
sed -ri '/^162..*hk/s/hk/hk162/g' ./ping.txt
#cat ./ping.txt | sed -n '/#\|^ *$/d;1,152p' | awk '{print $1}' > ./pingip_top150.txt
#cp -f ./pingip_top150.txt $diretc/pingip_top150.txt
> ./pingip_ok_$(date "+%Y-%m-%d_%H:%M:%S")
echo "pingip_ok_$(date "+%Y-%m-%d_%H:%M:%S")"
}

start_ping () {
#curl请求测试次数
ii=2
i=1
while true
do
if [ $i -le $ii ] ; then
	site=$(curl -sL -m 5 ${http_tls}://cp.cloudflare.com/cdn-cgi/trace --resolve cp.cloudflare.com:${http_port}:$ip |awk -F= '/^colo/{print $2}')
	if [ -z "$site" ] ; then
		echo "$ip：第$i/$ii次获取site地区失败"
		i=$((i+1))
	else
		run_ping=`ping -c $ping_cishu -q $ip | sed ":a;N;s/\n/ /g;ba"`
		loss=`echo $run_ping |grep -Eo 'received.*%' |awk '{print $2 }'|sed 's/%//'`
		avg=`echo $run_ping |grep -Eo 'avg.*ms' |awk -F/ '{print $3 }' |awk -F '.' '{print $1}'`
		echo "$ip - 地区: $site - 丢包: $loss % - 延迟: $avg ms" >> ./pingip_run_1.txt
		break
	fi
else
	echo "$ip - 地区获取失败，跳过。  - - 999null % - - null ms" >> ./pingip_run_0.txt
	break
fi
done
}


#9
all () {
start_all=1
nmap_ && one && again && again && sed -i "1i\######【cloudflare】$(date "+%Y-%m-%d %H:%M:%S") #######\n" ./FINAL_NEW_`sed -n '$=' ./1.txt`.TXT
}


#6
#分国家与CDN IP
get_country_cdnip () {
all_country=$(cat $dir_tmp/ping_loss_$loss.txt | awk '{print $4}'|sed '/-/d'|awk '!a[$0]++')
all_country_num=$(echo $all_country | sed 's/ /\n/g' | wc -l)
[ -z "$all_country" ] && echo "所有国家列表$all_country 为空，跳出循环" && break
for country in $all_country
do
echo -e \\n"\e[1;36m【${c}】國家：[$country] \e[0m "
cdnip=$(cat $dir_tmp/ping_loss_$loss.txt | grep " $country " | head -n "$goodip")
[ -z "$cdnip" ] && echo "国家${c}[$country]满足丢包率$loss与前$goodip的cdnip为空，跳出循环" && break
echo -e "\e[36m  >> 优选[$country]丢包率小于$loss%的前$goodip个CDN IP...\e[0m"
[ -f $dir_tmp/${c}_${filename} ] && rm $dir_tmp/${c}_${filename}
IFS=$'\n'
for ip in $cdnip
do
cdn_ip=$(echo $ip | awk '{print $1}')
cdn_loss=$(echo $ip | awk '{print $7}')
cdn_ms=$(echo $ip | awk '{print $11}' | awk -F. '{print $1}')
echo "ip：$cdn_ip 丢包率：$cdn_loss 延迟：$cdn_ms"
if [ "${type}" = "vmess" ] ; then
	if [ "${network}" = "ws" ] ; then
		if [ "${wss0rtt}" = "1" ] ; then
			if [ "${tls}" = "1" ] ; then
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", uuid: "\'${uuid}\'", alterId: 0, cipher: "\'${cipher}\'", udp: true, xudp: true, tls: true, servername: "\'${server}\'", skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", ws-opts: { path: "\'${path}?ed=2048\'", headers: { Host: "\'${server}\'" }, v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			else
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", uuid: "\'${uuid}\'", alterId: 0, cipher: "\'${cipher}\'", udp: true, xudp: true, tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", ws-opts: { path: "\'${path}?ed=2048\'", headers: { Host: "\'${server}\'" }, v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			fi
		else
			if [ "${tls}" = "1" ] ; then
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", uuid: "\'${uuid}\'", alterId: 0, cipher: "\'${cipher}\'", udp: true, xudp: true, tls: true, servername: "\'${server}\'", skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", ws-opts: { path: "\'${path}\'", headers: { Host: "\'${server}\'" }, v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			else
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", uuid: "\'${uuid}\'", alterId: 0, cipher: "\'${cipher}\'", udp: true, xudp: true, tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", ws-opts: { path: "\'${path}\'", headers: { Host: "\'${server}\'" }, v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			fi
		fi
	elif [ "${network}" = "grpc" ] ; then
		echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", uuid: "\'${uuid}\'", alterId: 0, cipher: "\'${cipher}\'", udp: true, xudp: true, tls: true, servername: "\'${server}\'", skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", grpc-opts: { grpc-service-name: "\'${path}\'" } }" >> $dir_tmp/${c}_${filename}
	else
		echo "✖节点参数<网络类型>network：${network}错误（非ws/grpc），跳出循环。" && break
	fi
elif [ "${type}" = "vless" ] ; then
	if [ "${network}" = "ws" ] ; then
		if [ "${wss0rtt}" = "1" ] ; then
			if [ "${tls}" = "1" ] ; then
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", uuid: "\'${uuid}\'", udp: true, xudp: true, tls: true, servername: "\'${server}\'", skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", ws-opts: { path: "\'${path}?ed=2048\'", headers: { Host: "\'${server}\'" }, v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			else
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", uuid: "\'${uuid}\'", udp: true, xudp: true, tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", ws-opts: { path: "\'${path}?ed=2048\'", headers: { Host: "\'${server}\'" }, v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			fi
		else
			if [ "${tls}" = "1" ] ; then
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", uuid: "\'${uuid}\'", udp: true, xudp: true, tls: true, servername: "\'${server}\'", skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", ws-opts: { path: "\'${path}\'", headers: { Host: "\'${server}\'" }, v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			else
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", uuid: "\'${uuid}\'", udp: true, xudp: true, tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", ws-opts: { path: "\'${path}\'", headers: { Host: "\'${server}\'" }, v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			fi
		fi
	elif [ "${network}" = "grpc" ] ; then
		echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", uuid: "\'${uuid}\'", udp: true, xudp: true, tls: true, servername: "\'${server}\'", skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", grpc-opts: { grpc-service-name: "\'${path}\'" } }" >> $dir_tmp/${c}_${filename}
	else
		echo "✖节点参数<网络类型>network：${network}错误（非ws/grpc），跳出循环。" && break
	fi
elif [ "${type}" = "trojan" ] ; then
	if [ "${network}" = "ws" ] ; then
		if [ "${wss0rtt}" = "1" ] ; then
			echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", password: "\'${uuid}\'", udp: true, tls: true, sni: "\'${server}\'", skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", ws-opts: { path: "\'${path}?ed=2048\'", headers: { Host: "\'${server}\'" }, v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
		else
			echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", password: "\'${uuid}\'", udp: true, tls: true, sni: "\'${server}\'", skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", ws-opts: { path: "\'${path}\'", headers: { Host: "\'${server}\'" }, v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
		fi
	elif [ "${network}" = "grpc" ] ; then
		echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", password: "\'${uuid}\'", udp: true, tls: true, sni: "\'${server}\'", skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", grpc-opts: { grpc-service-name: "\'${path}\'" } }" >> $dir_tmp/${c}_${filename}
	else
		echo "✖节点参数<网络类型>network：${network}错误（非ws/grpc），跳出循环。" && break
	fi
elif [ "${type}" = "ss" ] ; then
	if [ "${network}" = "ws" ] ; then
		if [ "${wss0rtt}" = "1" ] ; then
			if [ "${tls}" = "1" ] ; then
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", password: "\'${password}\'", cipher: "\'${cipher}\'", udp: true, udp-over-tcp: true, tls: true, skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: "\'${server}\'", path: "\'${path}?ed=2048\'", v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			else
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", password: "\'${password}\'", cipher: "\'${cipher}\'", udp: true, udp-over-tcp: true, tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: "\'${server}\'", path: "\'${path}?ed=2048\'", v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			fi
		else
			if [ "${tls}" = "1" ] ; then
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", password: "\'${password}\'", cipher: "\'${cipher}\'", udp: true, udp-over-tcp: true, tls: true, skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: "\'${server}\'", path: "\'${path}\'", v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			else
				echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms${extraname_httpupgrade}${extraname_brutal}\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", password: "\'${password}\'", cipher: "\'${cipher}\'", udp: true, udp-over-tcp: true, tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: "\'${server}\'", path: "\'${path}\'", v2ray-http-upgrade: "${v2rayhttpupgrade}", v2ray-http-upgrade-fast-open: "${v2rayhttpupgrade}" }, smux: { enabled: "${mux_status}", protocol: "\'${mux_type}\'", padding: "${padding}", max-connections: "\'${max_connections}\'", min-streams: "\'${min_streams}\'", max-streams: "\'${max_streams}\'", statistic: "${statistic}", only-tcp: "${only_tcp}", brutal-opts: { enabled: "${tcpbrutal}", up: "\'${brutal_up}\'", down: "\'${brutal_down}\'" } } }" >> $dir_tmp/${c}_${filename}
			fi
		fi
	elif [ "${network}" = "grpc" ] ; then
		echo "- { name: "\'${name}-${country}-${cdn_ip}-${cdn_loss}%-${cdn_ms}ms\'", type: "\'${type}\'", server: "\'${cdn_ip}\'", port: "\'${port}\'", password: "\'${password}\'", cipher: "\'${cipher}\'", udp: true, udp-over-tcp: true, tls: true, skip-cert-verify: "${skiptls}",${fingerprint} tfo: "${tfo}", mptcp: "${mptcp}", ip-version: "\'${ipversion}\'", network: "\'${network}\'", grpc-opts: { grpc-service-name: "\'${path}\'" } }" >> $dir_tmp/${c}_${filename}
		#echo "✖节点参数<网络类型>network：${network}未支持，跳出循环。" && break
	else
		echo "✖节点参数<网络类型>network：${network}错误（非ws/grpc），跳出循环。" && break
	fi
else
	echo "✖节点参数<协议类型>type：${type}错误（非vmess/vless/trojan/ss），跳出循环。" && break
fi
done
sed -i '1i\proxies:' $dir_tmp/${c}_${filename}
sed -i 's/\[//g' $dir_tmp/${c}_${filename}
sed -i 's/\]//g' $dir_tmp/${c}_${filename}
echo -e "\e[1;32m✔【$filename】国家${c}[$country] 处理完成，文件路径：$dir_tmp/${c}_${filename}\e[0m"
c=$((c+1))
done
}
#分文件
get_clash_file (){
dir_etc=$diretc
dir_tmp=$dir/cdnip
if [ ! -d $dir_tmp ] ; then
	mkdir -p $dir_tmp
else
	[ ! -z "$(ls $dir_tmp)" ] && echo "清空$dir_tmp旧文件..." && rm $dir_tmp/*
fi
file_server_list=$(ls $dir_etc | grep -E "^file_server[0-9]+.txt$")
[ -z "$file_server_list" ] && echo "$dir_etc不存在服务器配置文件file_server.txt文件，结束脚本。" && exit
[ ! -s /tmp/cf/ping.txt ] && echo "/tmp/cf/ping.txt文件不存在，结束脚本。" && exit
[ ! -z "$1" ] && goodip=$1
[ -z "$goodip" ] && goodip=4
[ ! -z "$2" ] && loss=$2
[ -z "$loss" ] && loss=20
#用awk提取第三行开始（NR>3），丢包率小于5%（$7<4）且大于等于0%的所有IP列表
awk 'NR>3 && $7<'$loss' && $7>=0{print $0}' /tmp/cf/ping.txt > $dir_tmp/ping_loss_$loss.txt
[ ! -s $dir_tmp/ping_loss_$loss.txt ] && echo "生成ping_loss_$loss.txt文件为空，结束脚本。" && exit
ff=$(ls $dir_etc | grep -E "^file_server[0-9]+.txt$" | wc -l)
f=1
for filename in $file_server_list
do
c=1
echo -e \\n"\e[1;4;36m[$f/$ff] 处理文件：$filename \e[0m "
for a in $(cat $dir_etc/$filename | grep '=' | grep -Ev '^#' | sed '1!G;h;$!d') ; do n=$(echo $a | awk -F= '{print $1}') ; b=$(echo $a | sed "s/${n}=//g") ; eval $n=$b ; done
#name，节点自定义名称
#type，协议类型vless/vmess/trojan
#network，网络类型ws/grpc
#server，服务器域名
#path，WS path或GRPC serviceName
#uuid，VLESS/VMESS uuid或TROJAN password
#cipher，加密方式，仅vmess协议，可选auto/none/zero，默认cipher=zero
[ -z "${cipher}" ] && cipher=zero
#port，端口，默认port=443
[ -z "${port}" ] && port=443
#wss0rtt，是否启用wss0rtt，即加?ed=2048。默认开启
[ -z "${wss0rtt}" ] && wss0rtt=1
#http-upgrade，默认关闭0
if [ "${httpupgrade}" = "1" -o "${httpupgrade}" = "true" ] ; then wss0rtt=0 && v2rayhttpupgrade=true && extraname_httpupgrade="" && httpupgrade="" ; else v2rayhttpupgrade=false && extraname_httpupgrade="" ; fi
#brutal，默认关闭0
if [ "${brutal}" = "1" -o "${brutal}" = "true" ] ; then tcpbrutal=true && extraname_brutal="-brutal" && brutal="" ; else tcpbrutal=false && extraname_brutal="" ; fi
[ -z "${up}" ] && brutal_up=20 || brutal_up=$up && up=""
[ -z "${down}" ] && brutal_down=100 || brutal_down=$down && down=""
#tls，是否启用tls加密，默认开启
[ -z "${tls}" ] && tls=1
#skiptls，是否跳过证书验证，默认关
[ "${skiptls}" = "1" ] && skiptls=true || skiptls=false
#tfo
[ "${tfo}" = "1" ] && tfo=true || tfo=false
#mptcp
[ "${mptcp}" = "1" ] && mptcp=true || mptcp=false
#ip-version
if [ "${ipversion}" = "4" -o "${ipversion}" = "ipv4" ] ; then
	ipversion="ipv4-prefer"
elif [ "${ipversion}" = "6" -o "${ipversion}" = "ipv6" ] ; then
	ipversion="ipv6-prefer"
else
	ipversion=dual
fi
#fingerprint，tls浏览器指纹，默认none
[ ! -z "${fingerprint}" ] && fingerprint=" client-fingerprint: ${fingerprint}," || fingerprint=""
#mux，多路复用，默认关
if [ "${mux}" = "smux" -o "${mux}" = "yamux" -o "${mux}" = "h2mux" ] ; then
mux_status=true
mux_type=$mux
mux=""
else
mux_status=false
mux_type=smux
fi
[ -z "${padding}" ] && padding=true
[ -z "${max_connections}" ] && max_connections=0
[ -z "${min_streams}" ] && min_streams=0
[ -z "${max_streams}" ] && max_streams=8
[ -z "${statistic}" ] && statistic=true
[ -z "${only_tcp}" ] && only_tcp=false
##
[ -z "${name}" -o -z "${type}" -o -z "${network}" -o -z "${server}" -o -z "${path}" -o -z "${uuid}" ] && echo -e "$filename文件缺少其中参数↓\\n name：${name} \\n type：${type} \\n network：${network} \\n server：${server} \\n path：${path} \\n uuid：${uuid} \\n →跳出循环。" && break
sleep_time=1
if [ "$f" -gt "1" ] ; then
#sleep $sleep_time 
get_country_cdnip >/dev/null 2>&1 &
else
get_country_cdnip
fi
f=$((f+1))
done
echo ">>等待处理文件..."
wait
echo -e \\n"\e[1;32m✓总[$ff]个文件[$all_country_num]个country处理完成，$(ls $dir_tmp |grep file_server|wc -l)/$((ff*all_country_num))\e[0m"\\n
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
		> $dirconf/settings.txt
	elif [ "$num" = "1" ] ; then
		vi $dirconf/settings.txt
	else
		echo -e \\n"\e[1;37m✖输入非0、1，退出脚本 \e[0m"\\n
	fi
else
	echo -e \\n"\e[1;37m✖输入非数字，退出脚本 \e[0m"\\n
fi
}


#c
restore_clash_file () {
s=$1
[ -z "$s" ] && s=1
dir_clash=/etc/storage/pdcn/clash
all_file_txt=$(ls $dir_clash | grep -E "^file[0-9]+.txt$")
for file_txt in $all_file_txt
do
n=$(echo $file_txt | sed 's/^file//;s/.txt$//')
restore_clash_file_cc $n $s
done
}

#cc
restore_clash_file_cc () {
#n=1 恢复文件1，n=http 恢复订阅
#s=3 恢复第三个服务器
#replace_file=11 替换的文件
n=$1
s=$2
replace_file=$3
if [ "$n" = "http" ] ; then
	type=http
	group="订阅$s"
else
	type=file
	group="文件$n"
fi
[ -z "$s" -o -z "$n" ] && echo "\e[1;31m✖ [$group] 未指定恢复文件与服务器\e[0m" && exit
dir_clash=/etc/storage/pdcn/clash
dir_etc=$diretc
dir_tmp=$dir/cdnip
server=file_server${n}.txt
if [ "$type" = "file" ] ; then
	if [ -s $dir_tmp/${s}_$server ] ; then
		if [ -z "$replace_file" ] ; then
			echo -e \\n"\e[1;33m>> [$group] 复制文件$dir_tmp/${s}_$server 到 $dir_clash/file${n}.txt\e[0m"
		else
			group="文件$replace_file"
			n=$replace_file
			echo -e \\n"\e[1;33m>> [$group] 复制文件$dir_tmp/${s}_$server 到 $dir_clash/file${n}.txt\e[0m"
		fi
		cp -f $dir_tmp/${s}_$server $dir_clash/file${n}.txt
		[ ! -f $dir_clash/file${n}.txt ] && force_update=0 || force_update=1
	else
		force_update=0
	fi
elif [ "$type" = "http" ] ; then
	force_update=1
else
	force_update=0
fi
if [ "$force_update" = "1" ] ; then
	if [ "$force_speedtest" = "1" -a "$type" = "file" ] ; then
		[ ! -f $dir_tmp/speedtest_server.txt ] && > $dir_tmp/speedtest_server.txt
		if [ -z "$(cat $dir_tmp/speedtest_server.txt | grep -E "^$s$")" ] ; then
			echo "$s" >> $dir_tmp/speedtest_server.txt
			get_server_speed $s
			cp -f $dir_tmp/${s}_$server $dir_clash/file${n}.txt
		fi
	fi
	encode=$(curl -sv -G --data-urlencode "$group" -X GET "http://127.0.0.1:8000" 2>&1 |awk '/GET/{print $3}'|sed 's@/?@@')
	#curl -sv -X PUT "http://127.0.0.1:8000/providers/proxies/$encode" -H "Authorization: Bearer 123a456" 2>&1
	status=$(curl -s -w "%{http_code}" -X PUT "http://127.0.0.1:8000/providers/proxies/$encode" -H "Authorization: Bearer 123a456")
	if [ "$status" = "204" ] ; then
		[ "$type" = "file" ] && echo -e "\e[1;32m✔ [$group] 热更新成功。本地文件[$s]：$dir_clash/file${n}.txt\e[0m"
		[ "$type" = "http" ] && echo -e "\e[1;32m✔ [$group] 在线热更新成功！\e[0m"
	else
		[ "$type" = "file" ] && echo -e "\e[1;31m✖ [$group] 热更新失败，返回状态[$status]。本地文件[$s]：$dir_clash/file${n}.txt\e[0m"
		[ "$type" = "http" ] && echo -e "\e[1;31m✖ [$group] 在线热更新失败，返回状态[$status]。\e[0m"
	fi
else
	if [ "$type" = "file" ] ; then
		if [ -s $dir_clash/file${n}.txt ] ; then
			[ ! -s $dir_tmp/${s}_$server ] && echo -e \\n"\e[1;31m✖  [$group] $dir_tmp/${s}_$server 文件不存在，取消复制文件\e[0m"
		else
			echo -e \\n"\e[1;31m✖  [$group] $dir_clash/file${n}.txt 文件不存在，取消热更新文件\e[0m"
		fi
	fi
	[ "$type" = "http" ] && echo -e \\n"\e[1;31m✖  [$group] 取消在线热更新\e[0m"
fi
}

#ccc
restore_clash_file_ccc () {
dir_clash=/etc/storage/pdcn/clash
all_file_txt=$(ls $dir_clash | grep -E "^file[0-9]+.txt$")
for file_txt in $all_file_txt
do
s=$1
n=$(echo $file_txt | sed 's/^file//;s/.txt$//')
if [ -s $diretc/file_server${n}.txt ] ; then
	all_colo=$(cat $diretc/file_server${n}.txt | awk -F= '/^colo=/{print $2}' | sed 's/,/\n/g')
	if [ ! -z "${all_colo}" ] ; then
		for colo in ${all_colo}
		do
			s=$(cat $dir/cdnip/ping_loss*.txt | awk '{print $4}' | sed '/-/d' | awk '!a[$0]++' | awk "/$colo/{print NR}" | head -n 1)
			[ ! -z "$s" ] && break || continue
		done
	fi
fi
[ -z "$s" ] && s=1
restore_clash_file_cc $n $s
done
}


test_cf_speedtest () {
ip=$1
[ -z "$ip" ] && read -p "请输入测试IP:" ip
[ -z "$(echo $ip|grep -E '([0-9]+\.){3}[0-9]+|.*:.*:.*')" ] && echo "$ip  输入非IP地址，结束脚本。" && exit
#echo -e \\n"\e[36m  >> 测试IP：$ip...\e[0m"
{
colo=$(curl -sL -m 5 ${http_tls}://cp.cloudflare.com/cdn-cgi/trace --resolve cp.cloudflare.com:${http_port}:$ip |awk -F= '/^colo/{print $2}')
if [ ! -z "$colo" ] ; then
speed=$(curl -sL -o /dev/null $url -m 10 --resolve $url_domain:$url_port:$ip -w "%{speed_download}")
speed_format=$(echo $speed |sed ':a;s/\B[0-9]\{3\}\>/,&/;ta')
echo -e "IP：\e[1;37m$ip\e[0m  地区：\e[1;37m$colo\e[0m  下载速度：\e[1;37m $speed_format  \e[0m"
else
colo="获取失败"
speed_format="跳过测速❎"
echo -e "IP：\e[1;37m$ip\e[0m  地区：\e[1;31m$colo\e[0m  下载速度：$speed_format"
fi
}
}

#a
get_server_speed () {
num=$1
[ -z "$num" ] && read -n 1 -p "请选择测速服务器数字:" num
[ -z "$(echo $num|grep -E '^[0-9]+$')" ] && echo "输入非数字，结束脚本。" && exit
[ -z "$server_num" ] && server_num=$(ls /tmp/cf/cdnip/*_file_server*.txt | head -n 1 | grep -Eo "file_server[0-9]+.txt" | sed 's/file_server//g;s/.txt//g')
if [ -s /tmp/cf/cdnip/${num}_file_server${server_num}.txt ] ; then
name=$(cat /tmp/cf/cdnip/${num}_file_server${server_num}.txt | grep name)
cf_country=$(cat /tmp/cf/cdnip/${num}_file_server${server_num}.txt | grep -Eo 'name.*%-' | awk -F '-' 'NR==1{print $(NF-3)}')
IFS=$'\n'
echo -e \\n"\e[1;33m【${num}】正在测试文件 ${num}_file_server${server_num}.txt ...[${cf_country}]...\e[0m"
echo -e "\e[36m  >> 测速服务器：[$url_domain:$url_port]...\e[0m"
for a in $name
do
server_name=$(echo $a | awk -F \' '/name/{print $2}' | grep -Eo '([0-9]+\.){3}[0-9]+.*|-[0-9A-Za-z]*:.*%-.*ms')
server_ip=$(echo $a | grep -Eo "server.*port" | awk -F \' '{print $2}')
test_cf_speedtest $server_ip
wait
[ -z "$speed_format" ] && speed_format="无"
dir_file=$(ls /tmp/cf/cdnip/${num}_file_server*.txt)
for f in $dir_file
do
sed -i "s/${server_name}/&-${speed_format}/g" $f
done
done
echo -e "✔ 文件 ${num}_file_server${server_num}.txt 测试结束。"\\n
else
echo -e "✖ 文件 [/tmp/cf/cdnip/${num}_file_server${server_num}.txt] 不存在，跳过测速。"\\n
fi
}

#aa
get_server_speed_all () {
echo ">>获取节点 $(date "+%Y-%m-%d %H:%M:%S") ... "
get_clash_file $1 $2
#要处理文件列表
echo ">>测速节点 $(date "+%Y-%m-%d %H:%M:%S") ..."
server_num=$(ls /tmp/cf/cdnip/*_file_server*.txt | head -n 1 | grep -Eo "file_server[0-9]+.txt" | sed 's/file_server//g;s/.txt//g')
all_file=$(ls /tmp/cf/cdnip/*_file_server${server_num}.txt|grep -Eo '[0-9]+_file_server'|awk -F '_' '{print $1}')
for n in $all_file
do
get_server_speed $n
done
echo -e \\n"\e[1;36m✔ 所有文件测速结束。 $(date "+%Y-%m-%d %H:%M:%S") \e[0m"\\n
rm -f *.tgz
tar czf $(nvram get computer_name)_cdnip_aa_$(date "+%Y-%m-%d_%H%M").tgz cdnip ping.txt cf.sh_aa_log.txt cf.sh_e_log.txt 2>/dev/null
check_up
}

#b
get_server_speed_restore () {
echo ">>获取节点 $(date "+%Y-%m-%d %H:%M:%S") ... "
get_clash_file
echo ">>测速节点 $(date "+%Y-%m-%d %H:%M:%S") ..."
get_server_speed $1
echo ">>还原节点 $(date "+%Y-%m-%d %H:%M:%S") ..."
#restore_clash_file $1
restore_clash_file_ccc $1
#打包
rm -f cdnip_*tgz
tar czf cdnip_b_$1_$(date "+%Y-%m-%d_%H%M").tgz
}

#f
get_server_speed_and_restore () {
echo ">>获取节点 $(date "+%Y-%m-%d %H:%M:%S") ... "
get_clash_file $1 $2
echo ">>测速节点+还原节点 $(date "+%Y-%m-%d %H:%M:%S") ..."
force_speedtest=1
restore_clash_file_ccc
rm -f *.tgz
tar czf $(nvram get computer_name)_cdnip_f_$(date "+%Y-%m-%d_%H%M").tgz cdnip ping.txt cf.sh_f_log.txt cf.sh_ff_log.txt 2>/dev/null
check_up
}

upload () {
up_server=$1
up_port=$2
up_user=$3
up_passwd=$4
up_file=$5
[ -z "$up_server" -o -z "$up_port" -o -z "$up_user" -o -z "$up_passwd" -o -z "$up_file" ] && echo "✖ 错误，up_server：[$up_server]、up_port：[$up_port]、up_user：[$up_user]、up_passwd：[$up_passwd]、up_file：[$up_file]，其一为空，结束脚本" && exit
[ -z "$(ls $up_file 2>/dev/null)" ] && echo "✖ 错误 up_file： [$up_file] 文件不存在，结束脚本" && exit
token=$(curl -s -X POST --data '{"username":"'$up_user'", "password":"'$up_passwd'"}' https://$up_server:$up_port/api/login)
[ -z "$token" ] && echo "✖ 认证账号生成token为空，结束脚本" && exit
up_status=$(curl -s -X POST --header "X-Auth: $token" -F "file=@$up_file" https://$up_server:$up_port/api/resources/$up_file?override=true)
if [ "$up_status" = "200 OK" ] ; then
echo -e \\n"✔ 【$up_file】文件上传成功！[$up_status]"\\n
else
echo -e \\n"✖ 【$up_file】文件上传失败！[$up_status]"\\n
fi
}
check_up () {
if [ "$upload" = "1" ] ; then
	if [ ! -z "$upaccount" ] ; then
		up_server=$(echo $upaccount  | awk -F ',' '{print $1}')
		up_port=$(echo $upaccount | awk -F ',' '{print $2}')
		up_user=$(echo $upaccount | awk -F ',' '{print $3}')
		up_passwd=$(echo $upaccount | awk -F ',' '{print $4}')
		up_file=$upfile
		upload $up_server $up_port $up_user $up_passwd $up_file
	else
		echo -e \\n"✖ upaccount为空，跳过上传"\\n
	fi
else
	echo "upload=$upload"
fi
}

stop () {
run_num=$(ps -w | grep -v grep | grep -E 'cf.sh|curl|ping|nmap' | wc -l )
echo -e \\n"\e[1;36m▶强制结束所有任务[$run_num]\e[0m"\\n
ps -w | grep -v grep | grep -E 'cf.sh|curl|ping|nmap' | awk '{print $1}' | xargs kill -9
}

toilet_font () {
echo "
┌─────────┐
│░█▀▀░█▀▀░│
│░█░░░█▀▀░│
│░▀▀▀░▀░░░│
└─────────┘
"
}

case $1 in
1)
	one &
	;;
2)
	again &
	;;
3)
	nmap_ &
	;;
4)
	get_cf_ipv6 2>&1 | tee cf.sh_get_cf_ipv6_log.txt &
	;;
5)
	pingip > cf.sh_pingip_log.txt 2>&1 &
	;;
6)
	get_clash_file $2 $3
	;;
7)
	resettings
	;;
8)
	echo "none"
	;;
9)
	all &
	;;
0)
	stop
	;;
a)
	get_server_speed $2
	;;
aa)
	get_server_speed_all $2 $3 2>&1 | tee cf.sh_aa_log.txt &
	;;
#b)
	#get_server_speed_restore $2 2>&1 | tee cf.sh_b_log.txt &
	#;;
c)
	restore_clash_file $2 2>&1 | tee cf.sh_c_log.txt &
	;;
cc)
	restore_clash_file_cc $2 $3 $4 2>&1 | tee cf.sh_cc_log.txt &
	;;
ccc)
	restore_clash_file_ccc $2 2>&1 | tee cf.sh_ccc_log.txt &
	;;
#d)
	#echo "pingip→get→speed→restore"
	#pingip > cf.sh_pingip_log.txt 2>&1 && get_server_speed_restore $2 2>&1 | tee cf.sh_d_log.txt &
	#;;
e)
	echo "pingip→get→speed all"
	pingip > cf.sh_pingip_log.txt 2>&1 && get_server_speed_all $2 $3 2>&1 | tee cf.sh_e_log.txt &
	;;
f)
	echo "get→speed and restore"
	get_server_speed_and_restore $2 $3 2>&1 | tee cf.sh_f_log.txt &
	;;
ff)
	echo "pingip→get→speed and restore"
	pingip > cf.sh_pingip_log.txt 2>&1 && get_server_speed_and_restore $2 $3 2>&1 | tee cf.sh_ff_log.txt &
	;;
upload)
	if [ "$2" = "1" ] ; then
		[ ! -z "$3" ] && upfile=$3
		check_up
	else
		upload $2 $3 $4 $5 $6
	fi
	;;
*)
	toilet_font
	echo -e "\e[1;33m脚本管理：\e[0m\e[37m『 \e[0m\e[1;37m$sh_ver\e[0m\e[37m 』\e[0m"\\n
	echo -e "\e[1;32m【1】\e[1;36mone  ：初次查cloudflare IP 地区 \e[0m"
	echo -e "\e[1;32m【2】\e[1;36magain ：重复筛选查cloudflare IP 地区 \e[0m"
	echo -e "\e[1;32m【3】\e[1;36mnmap  ：nmap批量扫cloudflare存活 IP\e[0m "
	echo -e "\e[1;32m【4】\e[1;36mget_cf_ipv6：扫描cf ipv6 IP\e[0m "
	echo -e "\e[1;32m【5】\e[1;36mpingip  ：ping100次 pingip.txt 中的所有IP\e[0m "
	echo -e "\e[1;32m【6】\e[1;36mget_clash_file：生成clash优选CDN IP文件 \e[0m "
	echo -e "\e[1;32m【7】\e[1;36mresettings：重置初始化配置 \e[0m "
	#echo -e "\e[1;32m【8】\e[1;36mpingIP + 生成clash优选IP文件 \e[0m "
	echo -e "\e[1;32m【9】\e[1;36mall：一键执行全部流程，nmap→one→again→again \e[0m "
	echo -e "\e[1;32m【0】\e[1;36mstop \e[0m "\\n
	read -n 1 -p "请输入数字:" num
	if [ "$num" = "1" ] ; then
		nohup sh $bashpath/cf.sh 1 > /tmp/cf/one.log.txt 2>&1 &
	elif [ "$num" = "2" ] ; then
		nohup sh $bashpath/cf.sh 2 > /tmp/cf/again.log.txt 2>&1 &
	elif [ "$num" = "3" ] ; then
		nohup sh $bashpath/cf.sh 3 > /tmp/cf/nmap.log.txt 2>&1 &
	elif [ "$num" = "4" ] ; then
		get_cf_ipv6 2>&1 | tee cf.sh_get_cf_ipv6_log.txt &
	elif [ "$num" = "5" ] ; then
		pingip > cf.sh_pingip_log.txt 2>&1 &
	elif [ "$num" = "6" ] ; then
		get_clash_file
	elif [ "$num" = "7" ] ; then
		resettings
	elif [ "$num" = "8" ] ; then
		echo "none"
	elif [ "$num" = "9" ] ; then
		nohup sh $bashpath/cf.sh 9 > /tmp/cf/all.log.txt 2>&1 &
	elif [ "$num" = "0" ] ; then
		stop
	else
		echo -e \\n"\e[1;31m输入错误。\e[0m "\\n
	fi
	;;
esac
