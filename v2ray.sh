#!/bin/bash

red='\e[91m'
green='\e[92m'
yellow='\e[93m'
magenta='\e[95m'
cyan='\e[96m'
none='\e[0m'

# Root
[[ $(id -u) != 0 ]] && echo -e " 哎呀……请使用 ${red}root ${none}用户运行 ${yellow}~(^_^) ${none}" && exit 1

_version="v2.36"

cmd="apt-get"

sys_bit=$(uname -m)

if [[ $sys_bit == "i386" || $sys_bit == "i686" ]]; then
	v2ray_bit="32"
elif [[ $sys_bit == "x86_64" ]]; then
	v2ray_bit="64"
else
	echo -e " 哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}" && exit 1
fi

# 笨笨的检测方法
if [[ -f /usr/bin/apt-get ]] || [[ -f /usr/bin/yum && -f /bin/systemctl ]]; then

	if [[ -f /usr/bin/yum ]]; then

		cmd="yum"

	fi
	if [[ -f /bin/systemctl ]]; then
		systemd=true
	fi

else

	echo -e " 哈哈……这个 ${red}辣鸡脚本${none} 不支持你的系统。 ${yellow}(-_-) ${none}" && exit 1

fi

backup="/etc/v2ray/233blog_v2ray_backup.conf"

if [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f $backup && -d /etc/v2ray/233boy/v2ray ]]; then

	. $backup
	v2ray_ver=$(/usr/bin/v2ray/v2ray -version | head -n 1 | cut -d " " -f2)
	if [[ ! $username ]]; then
		. /etc/v2ray/233boy/v2ray/tools/support_socks.sh
	fi

elif [[ -f /usr/bin/v2ray/v2ray && -f /etc/v2ray/config.json ]] && [[ -f /etc/v2ray/233blog_v2ray_backup.txt && -d /etc/v2ray/233boy/v2ray ]]; then

	. /etc/v2ray/233boy/v2ray/tools/v1xx_to_v2xx.sh

else
	echo -e " 哎呀哎呀…… ${red}出错咯...请重新安装V2Ray${none} ${yellow}~(^_^) ${none}" && exit 1
fi

if [[ $caddy_status ]]; then
	caddy_installed=true
fi
if [[ $shadowsocks_status ]]; then
	shadowsocks=true
fi
if [[ $blocked_ad_status ]]; then
	is_blocked_ad=true
fi
if [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]]; then
	dynamicPort=true
	port_range="${v2ray_dynamicPort_start}-${v2ray_dynamicPort_end}"
fi
if [[ $path_status ]]; then
	is_path=true
fi

uuid=$(cat /proc/sys/kernel/random/uuid)
old_id="23332333-2333-2333-2333-233boy233boy"
v2ray_server_config="/etc/v2ray/config.json"
v2ray_client_config="/etc/v2ray/233blog_v2ray_config.json"
v2ray_pid=$(ps ux | grep "/usr/bin/v2ray/v2ray" | grep -v grep | awk '{print $2}')
caddy_pid=$(pgrep "caddy")
_v2ray_sh="/usr/local/sbin/v2ray"

if [[ ! -f $_v2ray_sh ]]; then
	mv -f /usr/local/bin/v2ray $_v2ray_sh
	chmod +x $_v2ray_sh
	echo -e "\n $yellow 警告: 请重新登录 SSH 以避免出现 v2ray 命令未找到的情况。$none  \n" && exit 1
fi

if [ $v2ray_pid ]; then
	v2ray_status="$green正在运行$none"
else
	v2ray_status="$red未在运行$none"
fi
if [[ $v2ray_transport == "4" && $caddy_installed ]] && [[ $caddy_pid ]]; then
	caddy_run_status="$green正在运行$none"
else
	caddy_run_status="$red未在运行$none"
fi

transport=(
	TCP
	TCP_HTTP
	WebSocket
	"WebSocket + TLS"
	mKCP
	mKCP_utp
	mKCP_srtp
	mKCP_wechat-video
	TCP_dynamicPort
	TCP_HTTP_dynamicPort
	WebSocket_dynamicPort
	mKCP_dynamicPort
	mKCP_utp_dynamicPort
	mKCP_srtp_dynamicPort
	mKCP_wechat-video_dynamicPort
	HTTP/2
	Socks5
)

ciphers=(
	aes-128-cfb
	aes-256-cfb
	chacha20
	chacha20-ietf
	aes-128-gcm
	aes-256-gcm
	chacha20-ietf-poly1305
)

get_transport_args() {
	header="none"
	if [[ $is_path ]]; then
		_path="/$path"
	else
		_path="/"
	fi
	case $v2ray_transport in
	1 | 9)
		net="tcp"
		;;
	2 | 10)
		net="tcp"
		header="http"
		host="www.baidu.com"
		;;
	3 | 4 | 11)
		net="ws"
		;;
	5 | 12)
		net="kcp"
		;;
	6 | 13)
		net="kcp"
		header="utp"
		;;
	7 | 14)
		net="kcp"
		header="srtp"
		;;
	8 | 15)
		net="kcp"
		header="wechat-video"
		;;
	16)
		net="h2"
		;;
	esac
}
create_vmess_URL_config() {

	[[ -z $net ]] && get_transport_args

	if [[ $v2ray_transport == "4" || $v2ray_transport == 16 ]]; then
		cat >/etc/v2ray/vmess_qr.json <<-EOF
		{
			"v": "2",
			"ps": "233blog_v2ray_${domain}",
			"add": "${domain}",
			"port": "443",
			"id": "${v2ray_id}",
			"aid": "${alterId}",
			"net": "${net}",
			"type": "none",
			"host": "${domain}",
			"path": "$_path",
			"tls": "tls"
		}
		EOF
	else
		[[ -z $ip ]] && get_ip
		cat >/etc/v2ray/vmess_qr.json <<-EOF
		{
			"v": "2",
			"ps": "233blog_v2ray_${ip}",
			"add": "${ip}",
			"port": "${v2ray_port}",
			"id": "${v2ray_id}",
			"aid": "${alterId}",
			"net": "${net}",
			"type": "${header}",
			"host": "${host}",
			"path": "",
			"tls": ""
		}
		EOF
	fi
}
view_v2ray_config_info() {

	[[ $v2ray_transport != 17 ]] && get_transport_args
	[[ -z $ip ]] && get_ip
	echo
	echo
	echo "---------- V2Ray 配置信息 -------------"
	if [[ $v2ray_transport == "4" || $v2ray_transport == 16 ]]; then
		if [[ ! $caddy_installed ]]; then
			echo
			echo -e " $red警告！$none$yellow请自行配置 TLS...教程: https://233blog.com/post/19/$none"
		fi
		echo
		echo -e "$yellow 地址 (Address) = $cyan${domain}$none"
		echo
		echo -e "$yellow 端口 (Port) = ${cyan}443${none}"
		echo
		echo -e "$yellow 用户ID (User ID / UUID) = $cyan${v2ray_id}$none"
		echo
		echo -e "$yellow 额外ID (Alter Id) = ${cyan}${alterId}${none}"
		echo
		echo -e "$yellow 传输协议 (Network) = ${cyan}${net}$none"
		echo
		echo -e "$yellow 伪装类型 (header type) = ${cyan}${header}$none"
		echo
		echo -e "$yellow 伪装域名 (host) = ${cyan}${domain}$none"
		echo
		echo -e "$yellow 路径 (path) = ${cyan}${_path}$none"
		echo
		echo -e "$yellow TLS (Enable TLS) = ${cyan}打开$none"
		echo
		if [[ $is_blocked_ad ]]; then
			echo " 备注: 广告拦截已开启.."
			echo
		fi
	elif [[ $v2ray_transport == 17 ]]; then
		echo
		echo -e "$yellow 主机 (Hostname) = $cyan${ip}$none"
		echo
		echo -e "$yellow 端口 (Port) = $cyan$v2ray_port$none"
		echo
		echo -e "$yellow 用户名 (Username) = $cyan${username}$none"
		echo
		echo -e "$yellow 密码 (Password) = $cyan${userpass}$none"
		echo
		echo -e "$yellow Telegram 代理配置链接 = ${cyan}tg://socks?server=${ip}&port=${v2ray_port}&user=${username}&pass=${userpass}$none"
		echo
		echo " 这是 Socks5 协议相关的配置啦.... 不用在乎一些 V2Ray 客户端 怎么没有这些东东配置的"
		echo
	else
		echo
		echo -e "$yellow 地址 (Address) = $cyan${ip}$none"
		echo
		echo -e "$yellow 端口 (Port) = $cyan$v2ray_port$none"
		echo
		echo -e "$yellow 用户ID (User ID / UUID) = $cyan${v2ray_id}$none"
		echo
		echo -e "$yellow 额外ID (Alter Id) = ${cyan}${alterId}${none}"
		echo
		echo -e "$yellow 传输协议 (Network) = ${cyan}${net}$none"
		echo
		echo -e "$yellow 伪装类型 (header type) = ${cyan}${header}$none"
		echo
	fi
	if [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]] && [[ $is_blocked_ad ]]; then
		echo " 备注: 动态端口已启用...广告拦截已开启..."
		echo
	elif [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]]; then
		echo " 备注: 动态端口已启用..."
		echo
	elif [[ $is_blocked_ad ]]; then
		echo " 备注: 广告拦截已开启.."
		echo
	fi
	echo "---------- END -------------"
	echo
	echo "V2Ray 客户端使用教程: https://233blog.com/post/20/"
	echo
}
get_shadowsocks_config() {
	if [[ $shadowsocks ]]; then

		while :; do
			echo
			echo -e "$yellow 1. $none查看 Shadowsocks 配置信息"
			echo
			echo -e "$yellow 2. $none生成二维码链接"
			echo
			read -p "$(echo -e "请选择 [${magenta}1-2$none]:")" _opt
			if [[ -z $_opt ]]; then
				error
			else
				case $_opt in
				1)
					view_shadowsocks_config_info
					break
					;;
				2)
					get_shadowsocks_config_qr_link
					break
					;;
				*)
					error
					;;
				esac
			fi

		done
	else
		shadowsocks_config
	fi
}
view_shadowsocks_config_info() {
	if [[ $shadowsocks ]]; then
		get_ip
		local ss="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64 -w 0)#233blog_ss_${ip}"
		echo
		echo
		echo "---------- Shadowsocks 配置信息 -------------"
		echo
		echo -e "$yellow 服务器地址 = $cyan${ip}$none"
		echo
		echo -e "$yellow 服务器端口 = $cyan$ssport$none"
		echo
		echo -e "$yellow 密码 = $cyan$sspass$none"
		echo
		echo -e "$yellow 加密协议 = $cyan${ssciphers}$none"
		echo
		echo -e "$yellow SS 链接 = ${cyan}$ss$none"
		echo
		echo -e " 备注:$red Shadowsocks Win 4.0.6 $none客户端可能无法识别该 SS 链接"
		echo
	else
		shadowsocks_config
	fi
}
get_shadowsocks_config_qr_link() {
	if [[ $shadowsocks ]]; then
		echo
		echo -e "$green 正在生成链接.... 稍等片刻即可....$none"
		echo
		get_ip
		local ss="ss://$(echo -n "${ssciphers}:${sspass}@${ip}:${ssport}" | base64 -w 0)#233blog_ss_${ip}"
		echo "${ss}" >/tmp/233blog_shadowsocks.txt
		cat /tmp/233blog_shadowsocks.txt | qrencode -s 50 -o /tmp/233blog_shadowsocks.png

		local random=$(echo $RANDOM-$RANDOM-$RANDOM | base64 -w 0)
		local link=$(curl -s --upload-file /tmp/233blog_shadowsocks.png "https://transfer.sh/${random}_233blog_shadowsocks.png")
		if [[ $link ]]; then
			echo
			echo "---------- Shadowsocks 二维码链接 -------------"
			echo
			echo -e "$yellow 链接 = $cyan$link$none"
			echo
			echo -e " 温馨提示...$red Shadowsocks Win 4.0.6 $none客户端可能无法识别该二维码"
			echo
			echo "备注...链接将在 14 天后失效"
			echo
			echo "提醒...请不要把链接分享出去...除非你有特别的理由...."
			echo
		else
			echo
			echo -e "$red 哎呀呀呀...出错咯...请重试$none"
			echo
		fi
		rm -rf /tmp/233blog_shadowsocks.png
		rm -rf /tmp/233blog_shadowsocks.txt
	else
		shadowsocks_config
	fi

}

get_shadowsocks_config_qr_ask() {
	echo
	while :; do
		echo -e "是否需要生成$yellow Shadowsocks 配置信息 $none二维码链接 [${magenta}Y/N$none]"
		read -p "$(echo -e "默认 [${magenta}N$none]:")" y_n
		[ -z $y_n ] && y_n="n"
		if [[ $y_n == [Yy] ]]; then
			get_shadowsocks_config_qr_link
			break
		elif [[ $y_n == [Nn] ]]; then
			break
		else
			error
		fi
	done

}
change_shadowsocks_config() {
	if [[ $shadowsocks ]]; then

		while :; do
			echo
			echo -e "$yellow 1. $none修改 Shadowsocks 端口"
			echo
			echo -e "$yellow 2. $none修改 Shadowsocks 密码"
			echo
			echo -e "$yellow 3. $none修改 Shadowsocks 加密协议"
			echo
			echo -e "$yellow 4. $none关闭 Shadowsocks"
			echo
			read -p "$(echo -e "请选择 [${magenta}1-4$none]:")" _opt
			if [[ -z $_opt ]]; then
				error
			else
				case $_opt in
				1)
					change_shadowsocks_port
					break
					;;
				2)
					change_shadowsocks_password
					break
					;;
				3)
					change_shadowsocks_ciphers
					break
					;;
				4)
					disable_shadowsocks
					break
					;;
				*)
					error
					;;
				esac
			fi

		done
	else

		shadowsocks_config
	fi
}
shadowsocks_config() {
	echo
	echo
	echo -e " $red大佬...你没有配置 Shadowsocks $none...不过现在想要配置的话也是可以的 ^_^"
	echo
	echo

	while :; do
		echo -e "是否配置 ${yellow}Shadowsocks${none} [${magenta}Y/N$none]"
		read -p "$(echo -e "(默认 [${cyan}N$none]):") " install_shadowsocks
		[[ -z "$install_shadowsocks" ]] && install_shadowsocks="n"
		if [[ "$install_shadowsocks" == [Yy] ]]; then
			echo
			shadowsocks=true
			shadowsocks_port_config
			shadowsocks_password_config
			shadowsocks_ciphers_config
			pause
			open_port $new_ssport
			backup_config +ss
			ssport=$new_ssport
			sspass=$new_sspass
			ssciphers=$new_ssciphers
			config
			clear
			view_shadowsocks_config_info
			get_shadowsocks_config_qr_ask
			break
		elif [[ "$install_shadowsocks" == [Nn] ]]; then
			echo
			echo -e " $green已取消配置 Shadowsocks ....$none"
			echo
			break
		else
			error
		fi

	done
}
shadowsocks_port_config() {
	local random=$(shuf -i20001-65535 -n1)
	while :; do
		echo -e "请输入 "$yellow"Shadowsocks"$none" 端口 ["$magenta"1-65535"$none"]，不能和 "$yellow"V2ray"$none" 端口相同"
		read -p "$(echo -e "(默认端口: ${cyan}${random}$none):") " new_ssport
		[ -z "$new_ssport" ] && new_ssport=$random
		case $new_ssport in
		$v2ray_port)
			echo
			echo -e " 不能和$cyan V2Ray 端口 $none一毛一样...."
			echo
			echo -e " 当前 V2Ray 端口：${cyan}$v2ray_port${none}"
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $v2ray_transport == "4" || $v2ray_transport == "16" ]]; then
				local tls=ture
			fi
			if [[ $tls && $new_ssport == "80" ]] || [[ $tls && $new_ssport == "443" ]]; then
				echo
				echo -e "由于你当前已使用了 "$green"WebSocket + TLS $none或$green HTTP/2"$none" 传输协议."
				echo
				echo -e "所以不能选择 "$magenta"80"$none" 或 "$magenta"443"$none" 端口"
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start == $new_ssport || $v2ray_dynamicPort_end == $new_ssport ]]; then
				local multi_port="${v2ray_dynamicPort_start} - ${v2ray_dynamicPort_end}"
				echo
				echo -e " 抱歉...此端口和$yellow V2Ray 动态端口 $none冲突...当前 V2Ray 动态端口范围为: $cyan$multi_port$none"
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start -lt $new_ssport && $new_ssport -le $v2ray_dynamicPort_end ]]; then
				local multi_port="${v2ray_dynamicPort_start} - ${v2ray_dynamicPort_end}"
				echo
				echo -e " 抱歉...此端口和$yellow V2Ray 动态端口 $none冲突...当前 V2Ray 动态端口范围为: $cyan$multi_port$none"
				error
			else
				echo
				echo
				echo -e "$yellow Shadowsocks 端口 = $cyan$new_ssport$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi
			;;
		*)
			error
			;;
		esac

	done

}

shadowsocks_password_config() {

	while :; do
		echo -e "请输入 "$yellow"Shadowsocks"$none" 密码"
		read -p "$(echo -e "(默认密码: ${cyan}233blog.com$none)"): " new_sspass
		[ -z "$new_sspass" ] && new_sspass="233blog.com"
		case $new_sspass in
		*[/$]*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以密码不能包含$red / $none或$red $ $none这两个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow Shadowsocks 密码 = $cyan$new_sspass$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac

	done

}

shadowsocks_ciphers_config() {

	while :; do
		echo -e "请选择 "$yellow"Shadowsocks"$none" 加密协议 [${magenta}1-7$none]"
		for ((i = 1; i <= ${#ciphers[*]}; i++)); do
			ciphers_show="${ciphers[$i - 1]}"
			echo
			echo -e "$yellow $i. $none${ciphers_show}"
		done
		echo
		read -p "$(echo -e "(默认加密协议: ${cyan}${ciphers[6]}$none)"):" ssciphers_opt
		[ -z "$ssciphers_opt" ] && ssciphers_opt=7
		case $ssciphers_opt in
		[1-7])
			new_ssciphers=${ciphers[$ssciphers_opt - 1]}
			echo
			echo
			echo -e "$yellow Shadowsocks 加密协议 = $cyan${new_ssciphers}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac

	done
}

change_shadowsocks_port() {
	echo
	while :; do
		echo -e "请输入 "$yellow"Shadowsocks"$none" 端口 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(当前端口: ${cyan}$ssport$none):") " new_ssport
		[ -z "$new_ssport" ] && error && continue
		case $new_ssport in
		$ssport)
			echo
			echo " 跟当前端口一毛一样....修改个鸡鸡哦"
			error
			;;
		$v2ray_port)
			echo
			echo -e " 不能和$cyan V2Ray 端口 $none一毛一样...."
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $v2ray_transport == "4" || $v2ray_transport == "16" ]]; then
				local tls=ture
			fi
			if [[ $tls && $new_ssport == "80" ]] || [[ $tls && $new_ssport == "443" ]]; then
				echo
				echo -e "由于你当前已使用了 "$green"WebSocket + TLS $none或$green HTTP/2"$none" 传输协议."
				echo
				echo -e "所以不能选择 "$magenta"80"$none" 或 "$magenta"443"$none" 端口"
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start == $new_ssport || $v2ray_dynamicPort_end == $new_ssport ]]; then
				local multi_port="${v2ray_dynamicPort_start} - ${v2ray_dynamicPort_end}"
				echo
				echo -e " 抱歉...此端口和$yellow V2Ray 动态端口 $none冲突...当前 V2Ray 动态端口范围为: $cyan$multi_port$none"
				error
			elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start -lt $new_ssport && $new_ssport -le $v2ray_dynamicPort_end ]]; then
				local multi_port="${v2ray_dynamicPort_start} - ${v2ray_dynamicPort_end}"
				echo
				echo -e " 抱歉...此端口和$yellow V2Ray 动态端口 $none冲突...当前 V2Ray 动态端口范围为: $cyan$multi_port$none"
				error
			else
				echo
				echo
				echo -e "$yellow Shadowsocks 端口 = $cyan$new_ssport$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				# sed -i "45s/=$ssport/=$new_ssport/" $backup
				backup_config ssport
				del_port $ssport
				open_port $new_ssport
				ssport=$new_ssport
				config
				clear
				view_shadowsocks_config_info
				get_shadowsocks_config_qr_ask
				break
			fi
			;;
		*)
			error
			;;
		esac

	done
}
change_shadowsocks_password() {
	echo
	while :; do
		echo -e "请输入 "$yellow"Shadowsocks"$none" 密码"
		read -p "$(echo -e "(当前密码：${cyan}$sspass$none)"): " new_sspass
		[ -z "$new_sspass" ] && error && continue
		case $new_sspass in
		$sspass)
			echo
			echo " 跟当前密码一毛一样....修改个鸡鸡哦"
			error
			;;
		*[/$]*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以密码不能包含$red / $none或$red $ $none这两个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow Shadowsocks 密码 = $cyan$new_sspass$none"
			echo "----------------------------------------------------------------"
			echo
			pause
			# sed -i "48s/=$sspass/=$new_sspass/" $backup
			backup_config sspass
			sspass=$new_sspass
			config
			clear
			view_shadowsocks_config_info
			get_shadowsocks_config_qr_ask
			break
			;;
		esac

	done

}

change_shadowsocks_ciphers() {
	echo
	while :; do
		echo -e "请选择 "$yellow"Shadowsocks"$none" 加密协议 [${magenta}1-${#ciphers[*]}$none]"
		for ((i = 1; i <= ${#ciphers[*]}; i++)); do
			ciphers_show="${ciphers[$i - 1]}"
			echo
			echo -e "$yellow $i. $none${ciphers_show}"
		done
		echo
		read -p "$(echo -e "(当前加密协议: ${cyan}${ssciphers}$none)"):" ssciphers_opt
		[ -z "$ssciphers_opt" ] && error && continue
		case $ssciphers_opt in
		[1-7])
			new_ssciphers=${ciphers[$ssciphers_opt - 1]}
			if [[ $new_ssciphers == $ssciphers ]]; then
				echo
				echo " 跟当前加密协议一毛一样....修改个鸡鸡哦"
				error && continue
			fi
			echo
			echo
			echo -e "$yellow Shadowsocks 加密协议 = $cyan${new_ssciphers}$none"
			echo "----------------------------------------------------------------"
			echo
			pause
			# sed -i "51s/=$ssciphers/=$new_ssciphers/" $backup
			backup_config ssciphers
			ssciphers=$new_ssciphers
			config
			clear
			view_shadowsocks_config_info
			get_shadowsocks_config_qr_ask
			break
			;;
		*)
			error
			;;
		esac

	done

}
disable_shadowsocks() {
	echo

	while :; do
		echo -e "是否关闭 ${yellow}Shadowsocks${none} [${magenta}Y/N$none]"
		read -p "$(echo -e "(默认 [${cyan}N$none]):") " y_n
		[[ -z "$y_n" ]] && y_n="n"
		if [[ "$y_n" == [Yy] ]]; then
			echo
			echo
			echo -e "$yellow 关闭 Shadowsocks = $cyan是$none"
			echo "----------------------------------------------------------------"
			echo
			pause
			# sed -i "31s/true/false/" $backup
			backup_config -ss
			del_port $ssport
			shadowsocks=''
			config
			# clear
			echo
			echo
			echo
			echo -e "$green Shadowsocks 已关闭...不过你也可以随时重新启用 Shadowsocks ...只要你喜欢$none"
			echo
			break
		elif [[ "$y_n" == [Nn] ]]; then
			echo
			echo -e " $green已取消关闭 Shadowsocks ....$none"
			echo
			break
		else
			error
		fi

	done
}
change_v2ray_config() {
	local _menu=(
		"修改 V2Ray 端口"
		"修改 V2Ray 传输协议"
		"修改 V2Ray 动态端口 (如果可以)"
		"修改 用户ID ( UUID )"
		"修改 TLS 域名 (如果可以)"
		"修改 分流的路径 (如果可以)"
		"修改 伪装的网址 (如果可以)"
		"关闭 网站伪装 和 路径分流 (如果可以)"
		"开启 / 关闭 广告拦截"
		"修改 Socks5 用户名 (如果可以)"
		"修改 Socks5 密码 (如果可以)"
	)
	while :; do
		for ((i = 1; i <= ${#_menu[*]}; i++)); do
			if [[ "$i" -le 9 ]]; then
				echo
				echo -e "$yellow  $i. $none${_menu[$i - 1]}"
			else
				echo
				echo -e "$yellow $i. $none${_menu[$i - 1]}"
			fi
		done
		echo
		read -p "$(echo -e "请选择 [${magenta}1-${#_menu[*]}$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				change_v2ray_port
				break
				;;
			2)
				change_v2ray_transport
				break
				;;
			3)
				change_v2ray_dynamicport
				break
				;;
			4)
				change_v2ray_id
				break
				;;
			5)
				change_domain
				break
				;;
			6)
				change_path_config
				break
				;;
			7)
				change_proxy_site_config
				break
				;;
			8)
				disable_path
				break
				;;
			9)
				blocked_hosts
				break
				;;
			10)
				change_socks_user_config
				break
				;;
			11)
				change_socks_pass_config
				break
				;;
			[aA][Ii][aA][Ii] | [Dd][Dd])
				socks_check
				custom_uuid
				break
				;;
			[Dd] | [Aa][Ii] | 233 | 233[Bb][Ll][Oo][Gg] | 233[Bb][Ll][Oo][Gg].[Cc][Oo][Mm] | 233[Bb][Oo][Yy] | [Aa][Ll][Tt][Ee][Rr][Ii][Dd])
				change_v2ray_alterId
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
change_v2ray_port() {
	if [[ $v2ray_transport == 4 ]]; then
		echo
		echo -e " 由于你目前使用的是$yellow WebSocket + TLS $none传输协议...所以修不修改 V2Ray 端口没有什么不一样的"
		echo
		echo " 如果你想要使用其他端口...可以先修改 V2Ray 的传输协议..之后再修改 V2Ray 端口"
		echo
		change_v2ray_transport_ask
	elif [[ $v2ray_transport == 16 ]]; then
		echo
		echo -e " 由于你目前使用的是$yellow HTTP/2 $none传输协议...所以修不修改 V2Ray 端口没有什么不一样的"
		echo
		echo " 如果你想要使用其他端口...可以先修改 V2Ray 的传输协议..之后再修改 V2Ray 端口"
		echo
		change_v2ray_transport_ask
	else
		echo
		while :; do
			echo -e "请输入 "$yellow"V2Ray"$none" 端口 ["$magenta"1-65535"$none"]"
			read -p "$(echo -e "(当前端口: ${cyan}${v2ray_port}$none):")" v2ray_port_opt
			[[ -z $v2ray_port_opt ]] && error && continue
			case $v2ray_port_opt in
			$v2ray_port)
				echo
				echo " 哎呀...跟当前端口一毛一样呀...修改个鸡鸡哦"
				error
				;;
			[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
				if [[ $shadowsocks ]] && [[ $v2ray_port_opt == $ssport ]]; then
					echo
					echo -e " ...不能跟$cyan Shadowsocks 端口 $none一毛一样..."
					error
				elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start == $v2ray_port_opt || $v2ray_dynamicPort_end == $v2ray_port_opt ]]; then
					local multi_port="${v2ray_dynamicPort_start} - ${v2ray_dynamicPort_end}"
					echo
					echo -e " 抱歉..此端口和$yellow V2Ray 动态端口 $none冲突...当前 V2Ray 动态端口范围为: $cyan$multi_port$none"
					error

				elif [[ $dynamicPort ]] && [[ $v2ray_dynamicPort_start -lt $v2ray_port_opt && $v2ray_port_opt -le $v2ray_dynamicPort_end ]]; then
					local multi_port="${v2ray_dynamicPort_start} - ${v2ray_dynamicPort_end}"
					echo
					echo -e " 抱歉...此端口和$yellow V2Ray 动态端口 $none冲突...当前 V2Ray 动态端口范围为: $cyan$multi_port$none"
					error
				else
					echo
					echo
					echo -e "$yellow V2Ray 端口 = $cyan$v2ray_port_opt$none"
					echo "----------------------------------------------------------------"
					echo
					pause
					# sed -i "19s/$v2ray_port/$v2ray_port_opt/" $backup
					backup_config v2ray_port
					del_port $v2ray_port
					open_port $v2ray_port_opt
					v2ray_port=$v2ray_port_opt
					config
					clear
					view_v2ray_config_info
					download_v2ray_config_ask
					break
				fi
				;;
			*)
				error
				;;
			esac

		done
	fi

}
download_v2ray_config_ask() {
	echo
	while :; do
		echo -e "是否需要 下载 V2Ray 配置 / 生成配置信息链接 / 生成二维码链接 [${magenta}Y/N$none]"
		read -p "$(echo -e "默认 [${cyan}N$none]:")" y_n
		[ -z $y_n ] && y_n="n"
		if [[ $y_n == [Yy] ]]; then
			download_v2ray_config
			break
		elif [[ $y_n == [Nn] ]]; then
			break
		else
			error
		fi
	done

}
change_v2ray_transport_ask() {
	echo
	while :; do
		echo -e "是否需要修改$yellow V2Ray $none传输协议 [${magenta}Y/N$none]"
		read -p "$(echo -e "默认 [${cyan}N$none]:")" y_n
		[ -z $y_n ] && break
		if [[ $y_n == [Yy] ]]; then
			change_v2ray_transport
			break
		elif [[ $y_n == [Nn] ]]; then
			break
		else
			error
		fi
	done
}
change_v2ray_transport() {
	echo
	while :; do
		echo -e "请选择 "$yellow"V2Ray"$none" 传输协议 [${magenta}1-${#transport[*]}$none]"
		echo
		for ((i = 1; i <= ${#transport[*]}; i++)); do
			Stream="${transport[$i - 1]}"
			if [[ "$i" -le 9 ]]; then
				# echo
				echo -e "$yellow  $i. $none${Stream}"
			else
				# echo
				echo -e "$yellow $i. $none${Stream}"
			fi
		done
		echo
		echo "备注1: 含有 [dynamicPort] 的即启用动态端口.."
		echo "备注2: [utp | srtp | wechat-video] 分别为 伪装成 [BT下载 | 视频通话 | 微信视频通话]"
		echo
		read -p "$(echo -e "(当前传输协议: ${cyan}${transport[$v2ray_transport - 1]}$none)"):" v2ray_transport_opt
		if [ -z "$v2ray_transport_opt" ]; then
			error
		else
			case $v2ray_transport_opt in
			$v2ray_transport)
				echo
				echo " 哎呀...跟当前传输协议一毛一样呀...修改个鸡鸡哦"
				error
				;;
			4 | 16)
				if [[ $v2ray_port == "80" || $v2ray_port == "443" ]]; then
					echo
					echo -e " 抱歉...如果你想要使用${cyan} ${transport[$v2ray_transport_opt - 1]} $none传输协议.. ${red}V2Ray 端口不能为 80 或者 443 ...$none"
					echo
					echo -e " 当前 V2Ray 端口: ${cyan}$v2ray_port$none"
					error
				elif [[ $shadowsocks ]] && [[ $ssport == "80" || $ssport == "443" ]]; then
					echo
					echo -e " 抱歉...如果你想要使用${cyan} ${transport[$v2ray_transport_opt - 1]} $none传输协议.. ${red}Shadowsocks 端口不能为 80 或者 443 ...$none"
					echo
					echo -e " 当前 Shadowsocks 端口: ${cyan}$ssport$none"
					error
				else
					echo
					echo
					echo -e "$yellow V2Ray 传输协议 = $cyan${transport[$v2ray_transport_opt - 1]}$none"
					echo "----------------------------------------------------------------"
					echo
					break
				fi
				;;
			[1-9] | 1[0-7])
				echo
				echo
				echo -e "$yellow V2Ray 传输协议 = $cyan${transport[$v2ray_transport_opt - 1]}$none"
				echo "----------------------------------------------------------------"
				echo
				break
				;;
			*)
				error
				;;
			esac
		fi

	done
	pause

	if [[ $v2ray_transport_opt == 4 || $v2ray_transport_opt == 16 ]]; then
		tls_config
	elif [[ $v2ray_transport_opt -ge 9 && $v2ray_transport_opt -le 15 ]]; then
		v2ray_dynamic_port_start
		v2ray_dynamic_port_end
		pause
		old_transport
		open_port "multiport"
		backup_config v2ray_transport v2ray_dynamicPort_start v2ray_dynamicPort_end
		port_range="${v2ray_dynamic_port_start_input}-${v2ray_dynamic_port_end_input}"
		v2ray_transport=$v2ray_transport_opt
		config
		clear
		view_v2ray_config_info
		download_v2ray_config_ask
	elif [[ $v2ray_transport_opt == 17 ]]; then
		socks_user_config
		socks_pass_config
		pause
		old_transport
		backup_config v2ray_transport username userpass
		v2ray_transport=$v2ray_transport_opt
		username=$new_username
		userpass=$new_userpass
		config
		clear
		view_v2ray_config_info
		download_v2ray_config_ask
	else
		old_transport
		backup_config v2ray_transport
		v2ray_transport=$v2ray_transport_opt
		config
		clear
		view_v2ray_config_info
		download_v2ray_config_ask
	fi

}
old_transport() {
	if [[ $v2ray_transport == 4 || $v2ray_transport == 16 ]]; then
		del_port "80"
		del_port "443"
		if [[ $caddy_installed && $caddy_pid ]]; then
			do_service stop caddy
			if [[ $systemd ]]; then
				systemctl disable caddy >/dev/null 2>&1
			else
				update-rc.d -f caddy remove >/dev/null 2>&1
			fi
		elif [[ $caddy_installed ]]; then
			if [[ $systemd ]]; then
				systemctl disable caddy >/dev/null 2>&1
			else
				update-rc.d -f caddy remove >/dev/null 2>&1
			fi
		fi
		if [[ $is_path ]]; then
			backup_config -path
		fi
	elif [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]]; then
		del_port "multiport"
	fi
}

socks_user_config() {
	echo
	while :; do
		read -p "$(echo -e "请输入$yellow用户名$none...(默认用户名: ${cyan}233blog$none)"): " new_username
		[ -z "$new_username" ] && new_username="233blog"
		case $new_username in
		*[/$]* | *\&*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以用户名不能包含$red / $none或$red $ $none或$red & $none这三个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow 用户名 = $cyan$new_username$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac
	done

}
socks_pass_config() {
	echo
	while :; do
		read -p "$(echo -e "请输入$yellow密码$none...(默认密码: ${cyan}233blog.com$none)"): " new_userpass
		[ -z "$new_userpass" ] && new_userpass="233blog.com"
		case $new_userpass in
		*[/$]* | *\&*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以密码不能包含$red / $none或$red $ $none或$red & $none这三个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow 密码 = $cyan$new_userpass$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac
	done
}

tls_config() {
	while :; do
		echo
		echo
		echo
		echo -e "请输入一个 $magenta正确的域名$none，一定一定一定要正确，不！能！出！错！"
		read -p "(例如：233blog.com): " new_domain
		[ -z "$new_domain" ] && error && continue
		echo
		echo
		echo -e "$yellow 你的域名 = $cyan$new_domain$none"
		echo "----------------------------------------------------------------"
		break
	done
	get_ip
	echo
	echo
	echo -e "$yellow 请将 $magenta$new_domain$none $yellow解析到: $cyan$ip$none"
	echo
	echo -e "$yellow 请将 $magenta$new_domain$none $yellow解析到: $cyan$ip$none"
	echo
	echo -e "$yellow 请将 $magenta$new_domain$none $yellow解析到: $cyan$ip$none"
	echo "----------------------------------------------------------------"
	echo

	while :; do

		read -p "$(echo -e "(是否已经正确解析: [${magenta}Y$none]):") " record
		if [[ -z "$record" ]]; then
			error
		else
			if [[ "$record" == [Yy] ]]; then
				echo
				echo
				echo -e "$yellow 域名解析 = ${cyan}我确定已经有解析了$none"
				echo "----------------------------------------------------------------"
				echo
				break
			else
				error
			fi
		fi

	done

	if [[ $caddy_installed ]]; then
		path_config_ask
		pause
		domain_check
		backup_config v2ray_transport domain
		if [[ $new_path ]]; then
			backup_config +path
			path=$new_path
			proxy_site=$new_proxy_site
			is_path=true
		fi

		if [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]]; then
			del_port "multiport"
		fi
		domain=$new_domain

		open_port "80"
		open_port "443"
		if [[ $systemd ]]; then
			systemctl enable caddy >/dev/null 2>&1
		else
			update-rc.d -f caddy defaults >/dev/null 2>&1
		fi
		v2ray_transport=$v2ray_transport_opt
		caddy_config
		config
		clear
		view_v2ray_config_info
		download_v2ray_config_ask
	else
		if [[ $v2ray_transport_opt == 16 ]]; then
			path_config_ask
			pause
			domain_check
			backup_config v2ray_transport domain caddy
			if [[ $new_path ]]; then
				backup_config +path
				path=$new_path
				proxy_site=$new_proxy_site
				is_path=true
			fi
			if [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]]; then
				del_port "multiport"
			fi
			domain=$new_domain
			install_caddy
			open_port "80"
			open_port "443"
			v2ray_transport=$v2ray_transport_opt
			caddy_config
			config
			caddy_installed=true
			clear
			view_v2ray_config_info
			download_v2ray_config_ask
		else
			auto_tls_config
		fi
	fi

}
auto_tls_config() {
	echo -e "

		安装 Caddy 来实现 自动配置 TLS
		
		如果你已经安装 Nginx 或 Caddy

		$yellow并且..自己能搞定配置 TLS$none

		那么就不需要 打开自动配置 TLS
		"
	echo "----------------------------------------------------------------"
	echo

	while :; do

		read -p "$(echo -e "(是否自动配置 TLS: [${magenta}Y/N$none]):") " auto_install_caddy
		if [[ -z "$auto_install_caddy" ]]; then
			error
		else
			if [[ "$auto_install_caddy" == [Yy] ]]; then
				echo
				echo
				echo -e "$yellow 自动配置 TLS = $cyan打开$none"
				echo "----------------------------------------------------------------"
				echo
				path_config_ask
				pause
				domain_check
				backup_config v2ray_transport domain caddy
				if [[ $new_path ]]; then
					backup_config +path
					path=$new_path
					proxy_site=$new_proxy_site
					is_path=true
				fi
				if [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]]; then
					del_port "multiport"
				fi
				domain=$new_domain
				install_caddy
				open_port "80"
				open_port "443"
				v2ray_transport=$v2ray_transport_opt
				caddy_config
				config
				caddy_installed=true
				clear
				view_v2ray_config_info
				download_v2ray_config_ask
				break
			elif [[ "$auto_install_caddy" == [Nn] ]]; then
				echo
				echo
				echo -e "$yellow 自动配置 TLS = $cyan关闭$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				domain_check
				backup_config v2ray_transport domain
				if [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]]; then
					del_port "multiport"
				fi
				domain=$new_domain
				open_port "80"
				open_port "443"
				v2ray_transport=$v2ray_transport_opt
				config
				clear
				view_v2ray_config_info
				download_v2ray_config_ask
				break
			else
				error
			fi
		fi

	done
}

path_config_ask() {
	echo
	while :; do
		echo -e "是否开启 网站伪装 和 路径分流 [${magenta}Y/N$none]"
		read -p "$(echo -e "(默认: [${cyan}N$none]):")" path_ask
		[[ -z $path_ask ]] && path_ask="n"

		case $path_ask in
		Y | y)
			path_config
			break
			;;
		N | n)
			echo
			echo
			echo -e "$yellow 网站伪装 和 路径分流 = $cyan不想配置$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		*)
			error
			;;
		esac
	done
}
path_config() {
	echo
	while :; do
		echo -e "请输入想要 ${magenta}用来分流的路径$none , 例如 /233blog , 那么只需要输入 233blog 即可"
		read -p "$(echo -e "(默认: [${cyan}233blog$none]):")" new_path
		[[ -z $new_path ]] && new_path="233blog"

		case $new_path in
		*[/$]*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以分流的路径不能包含$red / $none或$red $ $none这两个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow 分流的路径 = ${cyan}/${new_path}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac
	done
	proxy_site_config
}
proxy_site_config() {
	echo
	while :; do
		echo -e "请输入 ${magenta}一个正确的$none ${cyan}网址$none 用来作为 ${cyan}网站的伪装$none , 例如 https://liyafly.com"
		echo -e "举例...假设你当前的域名是$green $domain $none, 伪装的网址的是 https://liyafly.com"
		echo -e "然后打开你的域名时候...显示出来的内容就是来自 https://liyafly.com 的内容"
		echo -e "其实就是一个反代...明白就好..."
		echo -e "如果不能伪装成功...可以使用 v2ray config 修改伪装的网址"
		read -p "$(echo -e "(默认: [${cyan}https://liyafly.com$none]):")" new_proxy_site
		[[ -z $new_proxy_site ]] && new_proxy_site="https://liyafly.com"

		case $new_proxy_site in
		*[#$]*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以伪装的网址不能包含$red # $none或$red $ $none这两个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow 伪装的网址 = ${cyan}${new_proxy_site}$none"
			echo "----------------------------------------------------------------"
			echo
			break
			;;
		esac
	done
}

install_caddy() {
	if [[ $cmd == "yum" ]]; then
		[[ $(pgrep "httpd") ]] && systemctl stop httpd
		[[ $(command -v httpd) ]] && yum remove httpd -y
	else
		[[ $(pgrep "apache2") ]] && service apache2 stop
		[[ $(command -v apache2) ]] && apt-get remove apache2* -y
	fi
	local caddy_tmp="/tmp/install_caddy/"
	local caddy_tmp_file="/tmp/install_caddy/caddy.tar.gz"
	if [[ $sys_bit == "i386" || $sys_bit == "i686" ]]; then
		local caddy_download_link="https://caddyserver.com/download/linux/386?license=personal"
	elif [[ $sys_bit == "x86_64" ]]; then
		local caddy_download_link="https://caddyserver.com/download/linux/amd64?license=personal"
	else
		echo -e "$red 自动安装 Caddy 失败！不支持你的系统。$none" && exit 1
	fi

	mkdir -p $caddy_tmp

	if ! wget --no-check-certificate -O "$caddy_tmp_file" $caddy_download_link; then
		echo -e "$red 下载 Caddy 失败！$none" && exit 1
	fi

	tar zxf $caddy_tmp_file -C $caddy_tmp
	cp -f ${caddy_tmp}caddy /usr/local/bin/

	if [[ ! -f /usr/local/bin/caddy ]]; then
		echo -e "$red 安装 Caddy 出错！" && exit 1
	fi

	setcap CAP_NET_BIND_SERVICE=+eip /usr/local/bin/caddy

	if [[ $systemd ]]; then
		cp -f ${caddy_tmp}init/linux-systemd/caddy.service /lib/systemd/system/
		# sed -i "s/www-data/root/g" /lib/systemd/system/caddy.service
		systemctl enable caddy
	else
		cp -f ${caddy_tmp}init/linux-sysvinit/caddy /etc/init.d/caddy
		# sed -i "s/www-data/root/g" /etc/init.d/caddy
		chmod +x /etc/init.d/caddy
		update-rc.d -f caddy defaults
	fi

	mkdir -p /etc/ssl/caddy

	if [ -z "$(grep www-data /etc/passwd)" ]; then
		useradd -M -s /usr/sbin/nologin www-data
	fi
	chown -R www-data.www-data /etc/ssl/caddy

	mkdir -p /etc/caddy/
	rm -rf $caddy_tmp

}
caddy_config() {
	local email=$(shuf -i1-10000000000 -n1)
	case $v2ray_transport in
	4)
		if [[ $is_path ]]; then
			cat >/etc/caddy/Caddyfile <<-EOF
$domain {
    tls ${email}@gmail.com
    gzip
	timeouts none
    proxy / $proxy_site {
        without /${path}
    }
    proxy /${path} 127.0.0.1:${v2ray_port} {
        without /${path}
        websocket
    }
}
		EOF
		else
			cat >/etc/caddy/Caddyfile <<-EOF
$domain {
    tls ${email}@gmail.com
	timeouts none
	proxy / 127.0.0.1:${v2ray_port} {
		websocket
	}
}
		EOF
		fi
		;;
	16)
		if [[ $is_path ]]; then
			cat >/etc/caddy/Caddyfile <<-EOF
$domain {
    tls ${email}@gmail.com
    gzip
	timeouts none
    proxy / $proxy_site {
        without /${path}
    }
    proxy /${path} https://127.0.0.1:${v2ray_port} {
        header_upstream Host {host}
		header_upstream X-Forwarded-Proto {scheme}
		insecure_skip_verify
    }
}
		EOF
		else
			cat >/etc/caddy/Caddyfile <<-EOF
$domain {
    tls ${email}@gmail.com
	timeouts none
	proxy / https://127.0.0.1:${v2ray_port} {
        header_upstream Host {host}
		header_upstream X-Forwarded-Proto {scheme}
		insecure_skip_verify
	}
}
		EOF
		fi
		;;

	esac
	# systemctl restart caddy
	do_service restart caddy
}
v2ray_dynamic_port_start() {
	echo
	echo
	while :; do
		echo -e "请输入 "$yellow"V2Ray 动态端口开始 "$none"范围 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(默认开始端口: ${cyan}10000$none):")" v2ray_dynamic_port_start_input
		[ -z $v2ray_dynamic_port_start_input ] && v2ray_dynamic_port_start_input=10000
		case $v2ray_dynamic_port_start_input in
		$v2ray_port)
			echo
			echo " 不能和 V2Ray 端口一毛一样...."
			echo
			echo -e " 当前 V2Ray 端口：${cyan}$v2ray_port${none}"
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $shadowsocks ]] && [[ $v2ray_dynamic_port_start_input == $ssport ]]; then
				echo
				echo " 不能和 Shadowsocks 端口一毛一样...."
				echo
				echo -e " 当前 Shadowsocks 端口：${cyan}$ssport${none}"
				error
			else
				echo
				echo
				echo -e "$yellow V2Ray 动态端口开始 = $cyan$v2ray_dynamic_port_start_input$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi

			;;
		*)
			error
			;;
		esac

	done

	if [[ $v2ray_dynamic_port_start_input -lt $v2ray_port ]]; then
		lt_v2ray_port=true
	fi
	if [[ $shadowsocks ]] && [[ $v2ray_dynamic_port_start_input -lt $ssport ]]; then
		lt_ssport=true
	fi

}

v2ray_dynamic_port_end() {
	echo
	while :; do
		echo -e "请输入 "$yellow"V2Ray 动态端口结束 "$none"范围 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(默认结束端口: ${cyan}20000$none):")" v2ray_dynamic_port_end_input
		[ -z $v2ray_dynamic_port_end_input ] && v2ray_dynamic_port_end_input=20000
		case $v2ray_dynamic_port_end_input in
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])

			if [[ $v2ray_dynamic_port_end_input -le $v2ray_dynamic_port_start_input ]]; then
				echo
				echo " 不能小于或等于 V2Ray 动态端口开始范围"
				echo
				echo -e " 当前 V2Ray 动态端口开始：${cyan}$v2ray_dynamic_port_start_input${none}"
				error
			elif [ $lt_v2ray_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $v2ray_port ]]; then
				echo
				echo " V2Ray 动态端口结束范围 不能包括 V2Ray 端口..."
				echo
				echo -e " 当前 V2Ray 端口: ${cyan}$v2ray_port$none"
				error
			elif [ $lt_ssport ] && [[ ${v2ray_dynamic_port_end_input} -ge $ssport ]]; then
				echo
				echo " V2Ray 动态端口结束范围 不能包括 Shadowsocks 端口..."
				echo
				echo -e " 当前 Shadowsocks 端口: ${cyan}$ssport$none"
				error
			else
				echo
				echo
				echo -e "$yellow V2Ray 动态端口结束 = $cyan$v2ray_dynamic_port_end_input$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi
			;;
		*)
			error
			;;
		esac

	done

}
change_v2ray_dynamicport() {
	if [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]]; then
		change_v2ray_dynamic_port_start
		change_v2ray_dynamic_port_end
		pause
		del_port "multiport"
		open_port "multiport"
		backup_config v2ray_dynamicPort_start v2ray_dynamicPort_end
		port_range="${v2ray_dynamic_port_start_input}-${v2ray_dynamic_port_end_input}"
		config
		# clear
		echo
		echo -e "$green 动态端口修改成功啦...你不需要修改 V2Ray 客户端配置...保持原有的配置即可...$none"
		echo
	else
		echo
		echo -e "$red ...当前传输协议木有启用动态端口...$none"
		echo
		while :; do
			echo -e "是否需要修改传输协议 [${magenta}Y/N$none]"
			read -p "$(echo -e "默认 [${cyan}N$none]:")" y_n
			if [[ -z $y_n ]]; then
				echo
				echo -e "$green 已取消修改传输协议...$none"
				echo
				break
			else
				if [[ $y_n == [Yy] ]]; then
					change_v2ray_transport
					break
				elif [[ $y_n == [Nn] ]]; then
					echo
					echo -e "$green 已取消修改传输协议...$none"
					echo
					break
				else
					error
				fi
			fi
		done

	fi
}
change_v2ray_dynamic_port_start() {
	echo
	echo
	while :; do
		echo -e "请输入 "$yellow"V2Ray 动态端口开始 "$none"范围 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(当前动态开始端口: ${cyan}$v2ray_dynamicPort_start$none):")" v2ray_dynamic_port_start_input
		[ -z $v2ray_dynamic_port_start_input ] && error && continue
		case $v2ray_dynamic_port_start_input in
		$v2ray_port)
			echo
			echo " 不能和 V2Ray 端口一毛一样...."
			echo
			echo -e " 当前 V2Ray 端口：${cyan}$v2ray_port${none}"
			error
			;;
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			if [[ $shadowsocks ]] && [[ $v2ray_dynamic_port_start_input == $ssport ]]; then
				echo
				echo " 不能和 Shadowsocks 端口一毛一样...."
				echo
				echo -e " 当前 Shadowsocks 端口：${cyan}$ssport${none}"
				error
			else
				echo
				echo
				echo -e "$yellow V2Ray 动态端口开始 = $cyan$v2ray_dynamic_port_start_input$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi

			;;
		*)
			error
			;;
		esac

	done

	if [[ $v2ray_dynamic_port_start_input -lt $v2ray_port ]]; then
		lt_v2ray_port=true
	fi
	if [[ $shadowsocks ]] && [[ $v2ray_dynamic_port_start_input -lt $ssport ]]; then
		lt_ssport=true
	fi

}

change_v2ray_dynamic_port_end() {
	echo
	while :; do
		echo -e "请输入 "$yellow"V2Ray 动态端口结束 "$none"范围 ["$magenta"1-65535"$none"]"
		read -p "$(echo -e "(当前动态结束端口: ${cyan}$v2ray_dynamicPort_end$none):")" v2ray_dynamic_port_end_input
		[ -z $v2ray_dynamic_port_end_input ] && error && continue
		case $v2ray_dynamic_port_end_input in
		[1-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])

			if [[ $v2ray_dynamic_port_end_input -le $v2ray_dynamic_port_start_input ]]; then
				echo
				echo " 不能小于或等于 V2Ray 动态端口开始范围"
				echo
				echo -e " 当前 V2Ray 动态端口开始：${cyan}$v2ray_dynamic_port_start_input${none}"
				error
			elif [ $lt_v2ray_port ] && [[ ${v2ray_dynamic_port_end_input} -ge $v2ray_port ]]; then
				echo
				echo " V2Ray 动态端口结束范围 不能包括 V2Ray 端口..."
				echo
				echo -e " 当前 V2Ray 端口: ${cyan}$v2ray_port$none"
				error
			elif [ $lt_ssport ] && [[ ${v2ray_dynamic_port_end_input} -ge $ssport ]]; then
				echo
				echo " V2Ray 动态端口结束范围 不能包括 Shadowsocks 端口..."
				echo
				echo -e " 当前 Shadowsocks 端口: ${cyan}$ssport$none"
				error
			else
				echo
				echo
				echo -e "$yellow V2Ray 动态端口结束 = $cyan$v2ray_dynamic_port_end_input$none"
				echo "----------------------------------------------------------------"
				echo
				break
			fi
			;;
		*)
			error
			;;
		esac

	done

}
change_v2ray_id() {
	echo
	while :; do
		echo -e "是否确定要修改用户ID [${magenta}Y/N$none]"
		read -p "$(echo -e "默认 [${cyan}N$none]:")" y_n
		if [[ -z $y_n ]]; then
			echo
			echo -e "$green 已取消修改用户ID...$none"
			echo
			break
		else
			if [[ $y_n == [Yy] ]]; then
				echo
				echo
				echo -e "$yellow 修改用户ID = $cyan确定$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				# sed -i "21s/$v2ray_id/$uuid/;" $backup
				backup_config uuid
				v2ray_id=$uuid
				config
				clear
				view_v2ray_config_info
				download_v2ray_config_ask
				break
			elif [[ $y_n == [Nn] ]]; then
				echo
				echo -e "$green 已取消修改用户ID...$none"
				echo
				break
			else
				error
			fi
		fi
	done
}
change_domain() {
	if [[ $v2ray_transport == 4 || $v2ray_transport == 16 ]] && [[ $caddy_installed ]]; then
		while :; do
			echo
			echo -e "请输入一个 $magenta正确的域名$none，一定一定一定要正确，不！能！出！错！"
			read -p "$(echo -e "(当前域名: ${cyan}$domain$none):") " new_domain
			[ -z "$new_domain" ] && error && continue
			if [[ $new_domain == $domain ]]; then
				echo
				echo -e " 跟当前域名一毛一样啊...修改个鸡鸡哦"
				echo
				error && continue
			fi
			echo
			echo
			echo -e "$yellow 你的域名 = $cyan$new_domain$none"
			echo "----------------------------------------------------------------"
			break
		done
		get_ip
		echo
		echo
		echo -e "$yellow 请将 $magenta$new_domain$none $yellow解析到: $cyan$ip$none"
		echo
		echo -e "$yellow 请将 $magenta$new_domain$none $yellow解析到: $cyan$ip$none"
		echo
		echo -e "$yellow 请将 $magenta$new_domain$none $yellow解析到: $cyan$ip$none"
		echo "----------------------------------------------------------------"
		echo

		while :; do

			read -p "$(echo -e "(是否已经正确解析: [${magenta}Y$none]):") " record
			if [[ -z "$record" ]]; then
				error
			else
				if [[ "$record" == [Yy] ]]; then
					echo
					echo
					echo -e "$yellow 域名解析 = ${cyan}我确定已经有解析了$none"
					echo "----------------------------------------------------------------"
					echo
					pause
					domain_check
					# sed -i "27s/$domain/$new_domain/" $backup
					backup_config domain
					domain=$new_domain
					caddy_config
					config
					clear
					view_v2ray_config_info
					download_v2ray_config_ask
					break
				else
					error
				fi
			fi

		done
	else
		echo
		echo -e "$red 抱歉...不支持修改...$none"
		echo
		echo -e " 备注..修改 TLS 域名仅支持传输协议为 ${yellow}WebSocket + TLS$none 或 ${yellow}HTTP/2$none 并且$yellow 自动配置 TLS = 打开$none"
		echo
		echo -e " 当前传输协议为: ${cyan}${transport[$v2ray_transport - 1]}${none}"
		echo
		if [[ $caddy_installed ]]; then
			echo -e " 自动配置 TLS = ${cyan}打开$none"
		else
			echo -e " 自动配置 TLS = $red关闭$none"
		fi
		echo
	fi
}
change_path_config() {
	if [[ $v2ray_transport == 4 || $v2ray_transport == 16 ]] && [[ $caddy_installed && $is_path ]]; then
		echo
		while :; do
			echo -e "请输入想要 ${magenta}用来分流的路径$none , 例如 /233blog , 那么只需要输入 233blog 即可"
			read -p "$(echo -e "(当前分流的路径: [${cyan}/${path}$none]):")" new_path
			[[ -z $new_path ]] && error && continue

			case $new_path in
			$path)
				echo
				echo -e " 大佬...跟 当前分流的路径 一毛一样啊...修改个鸡鸡哦 "
				echo
				error
				;;
			*[/$]*)
				echo
				echo -e " 由于这个脚本太辣鸡了..所以分流的路径不能包含$red / $none或$red $ $none这两个符号.... "
				echo
				error
				;;
			*)
				echo
				echo
				echo -e "$yellow 分流的路径 = ${cyan}/${new_path}$none"
				echo "----------------------------------------------------------------"
				echo
				break
				;;
			esac
		done
		pause
		backup_config path
		path=$new_path
		caddy_config
		config
		clear
		view_v2ray_config_info
		download_v2ray_config_ask
	elif [[ $v2ray_transport == 4 || $v2ray_transport == 16 ]] && [[ $caddy_installed ]]; then
		path_config_ask
		if [[ $new_path ]]; then
			backup_config +path
			path=$new_path
			proxy_site=$new_proxy_site
			is_path=true
			caddy_config
			config
			clear
			view_v2ray_config_info
			download_v2ray_config_ask
		else
			echo
			echo
			echo " 给大佬点赞....好果断的放弃配置 网站伪装 和 路径分流"
			echo
			echo
		fi
	else
		echo
		echo -e "$red 抱歉...不支持修改...$none"
		echo
		echo -e " 备注..修改 分流的路径 仅支持传输协议为 ${yellow}WebSocket + TLS$none 或 ${yellow}HTTP/2$none 并且$yellow 自动配置 TLS = 打开$none"
		echo
		echo -e " 当前传输协议为: ${cyan}${transport[$v2ray_transport - 1]}${none}"
		echo
		if [[ $caddy_installed ]]; then
			echo -e " 自动配置 TLS = ${cyan}打开$none"
		else
			echo -e " 自动配置 TLS = $red关闭$none"
		fi
		echo
		change_v2ray_transport_ask
	fi

}
change_proxy_site_config() {
	if [[ $v2ray_transport == 4 || $v2ray_transport == 16 ]] && [[ $caddy_installed && $is_path ]]; then
		echo
		while :; do
			echo -e "请输入 ${magenta}一个正确的$none ${cyan}网址$none 用来作为 ${cyan}网站的伪装$none , 例如 https://liyafly.com"
			echo -e "举例...你当前的域名是$green $domain $none, 伪装的网址的是 https://liyafly.com"
			echo -e "然后打开你的域名时候...显示出来的内容就是来自 https://liyafly.com 的内容"
			echo -e "其实就是一个反代...明白就好..."
			echo -e "如果不能伪装成功...可以使用 v2ray config 修改伪装的网址"
			read -p "$(echo -e "(当前伪装的网址: [${cyan}${proxy_site}$none]):")" new_proxy_site
			[[ -z $new_proxy_site ]] && error && continue

			case $new_proxy_site in
			*[#$]*)
				echo
				echo -e " 由于这个脚本太辣鸡了..所以伪装的网址不能包含$red # $none或$red $ $none这两个符号.... "
				echo
				error
				;;
			*)
				echo
				echo
				echo -e "$yellow 伪装的网址 = ${cyan}${new_proxy_site}$none"
				echo "----------------------------------------------------------------"
				echo
				break
				;;
			esac
		done
		pause
		backup_config proxy_site
		proxy_site=$new_proxy_site
		caddy_config
		echo
		echo
		echo " 哎哟...好像是修改成功了..."
		echo
		echo -e " 赶紧打开你的域名 ${cyan}https://${domain}$none 检查一下看看"
		echo
		echo
	elif [[ $v2ray_transport == 4 || $v2ray_transport == 16 ]] && [[ $caddy_installed ]]; then
		path_config_ask
		if [[ $new_path ]]; then
			backup_config +path
			path=$new_path
			proxy_site=$new_proxy_site
			is_path=true
			caddy_config
			config
			clear
			view_v2ray_config_info
			download_v2ray_config_ask
		else
			echo
			echo
			echo " 给大佬点赞....好果断的放弃配置 网站伪装 和 路径分流"
			echo
			echo
		fi
	else
		echo
		echo -e "$red 抱歉...不支持修改...$none"
		echo
		echo -e " 备注..修改 伪装的网址 仅支持传输协议为 ${yellow}WebSocket + TLS$none 或 ${yellow}HTTP/2$none 并且$yellow 自动配置 TLS = 打开$none"
		echo
		echo -e " 当前传输协议为: ${cyan}${transport[$v2ray_transport - 1]}${none}"
		echo
		if [[ $caddy_installed ]]; then
			echo -e " 自动配置 TLS = ${cyan}打开$none"
		else
			echo -e " 自动配置 TLS = $red关闭$none"
		fi
		echo
		change_v2ray_transport_ask
	fi

}
domain_check() {
	# test_domain=$(dig $new_domain +short)
	test_domain=$(ping $new_domain -c 1 | grep -oE -m1 "([0-9]{1,3}\.){3}[0-9]{1,3}")
	if [[ $test_domain != $ip ]]; then
		echo
		echo -e "$red 检测域名解析错误....$none"
		echo
		echo -e " 你的域名: $yellow$new_domain$none 未解析到: $cyan$ip$none"
		echo
		echo -e " 你的域名当前解析到: $cyan$test_domain$none"
		echo
		echo "备注...如果你的域名是使用 Cloudflare 解析的话..在 Status 那里点一下那图标..让它变灰"
		echo
		exit 1
	fi
}
disable_path() {
	if [[ $v2ray_transport == 4 || $v2ray_transport == 16 ]] && [[ $caddy_installed && $is_path ]]; then
		echo

		while :; do
			echo -e "是否关闭 ${yellow}网站伪装 和 路径分流${none} [${magenta}Y/N$none]"
			read -p "$(echo -e "(默认 [${cyan}N$none]):") " y_n
			[[ -z "$y_n" ]] && y_n="n"
			if [[ "$y_n" == [Yy] ]]; then
				echo
				echo
				echo -e "$yellow 关闭 网站伪装 和 路径分流 = $cyan是$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				backup_config -path
				is_path=''
				caddy_config
				config
				clear
				view_v2ray_config_info
				download_v2ray_config_ask
				break
			elif [[ "$y_n" == [Nn] ]]; then
				echo
				echo -e " $green已取消关闭 网站伪装 和 路径分流 ....$none"
				echo
				break
			else
				error
			fi

		done
	else
		echo
		echo -e "$red 抱歉...不支持修改...$none"
		echo
		echo -e " 当前传输协议为: ${cyan}${transport[$v2ray_transport - 1]}${none}"
		echo
		if [[ $caddy_installed ]]; then
			echo -e " 自动配置 TLS = ${cyan}打开$none"
		else
			echo -e " 自动配置 TLS = $red关闭$none"
		fi
		echo
		if [[ $is_path ]]; then
			echo -e " 路径分流 = ${cyan}打开$none"
		else
			echo -e " 路径分流 = $red关闭$none"
		fi
		echo
		echo -e " 必须为 WebSocket + TLS 或 HTTP/2 传输协议, 自动配置 TLS = ${cyan}打开$none, 路径分流 = ${cyan}打开$none, 才能修改"
		echo

	fi
}
blocked_hosts() {
	if [[ $is_blocked_ad ]]; then
		local _info="$green已开启$none"
	else
		local _info="$red已关闭$none"
	fi
	_opt=''
	while :; do
		echo
		echo -e "$yellow 1. $none开启 广告拦截"
		echo
		echo -e "$yellow 2. $none关闭 广告拦截"
		echo
		echo "备注: 广告拦截是基于 域名 拦截的..所以也许会造成浏览网页的时候出现部分元素留白..或者其他问题"
		echo
		echo "反馈问题或请求拦截更多域名: https://github.com/233boy/v2ray/issues"
		echo
		echo -e "当前广告拦截状态: $_info"
		echo
		read -p "$(echo -e "请选择 [${magenta}1-2$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				if [[ $is_blocked_ad ]]; then
					echo
					echo -e " 大胸弟...难不成你没有看到 (当前广告拦截状态: $_info) 这个帅帅的提示么.....还开启个鸡鸡哦"
					echo
				else
					echo
					echo
					echo -e "$yellow 广告拦截 = $cyan开启$none"
					echo "----------------------------------------------------------------"
					echo
					pause
					# sed -i "39s/false/true/" $backup
					backup_config +ad
					is_blocked_ad=true
					config
					echo
					echo
					echo -e "$green 广告拦截已开启...如果出现异常..那就关闭它咯$none"
					echo
				fi
				break
				;;
			2)
				if [[ $is_blocked_ad ]]; then
					echo
					echo
					echo -e "$yellow 广告拦截 = $cyan关闭$none"
					echo "----------------------------------------------------------------"
					echo
					pause
					# sed -i "39s/true/false/" $backup
					backup_config -ad
					is_blocked_ad=''
					config
					echo
					echo
					echo -e "$red 广告拦截已关闭...不过你也可以随时重新开启 ...只要你喜欢$none"
					echo
				else
					echo
					echo -e " 大胸弟...难不成你没有看到 (当前广告拦截状态: $_info) 这个帅帅的提示么.....还关闭个鸡鸡哦"
					echo
				fi
				break
				;;
			*)
				error
				;;
			esac
		fi
	done

}
change_v2ray_alterId() {
	echo
	while :; do
		echo -e "请输入 ${yellow}alterId${none} 的数值 [${magenta}0-65535$none]"
		read -p "$(echo -e "(当前数值是: ${cyan}$alterId$none):") " new_alterId
		[[ -z $new_alterId ]] && error && continue
		case $new_alterId in
		$alterId)
			echo
			echo -e " 大佬...跟 当前 alterId 一毛一样啊...修改个鸡鸡哦 "
			echo
			error
			;;
		[0-9] | [1-9][0-9] | [1-9][0-9][0-9] | [1-9][0-9][0-9][0-9] | [1-5][0-9][0-9][0-9][0-9] | 6[0-4][0-9][0-9][0-9] | 65[0-4][0-9][0-9] | 655[0-3][0-5])
			echo
			echo
			echo -e "$yellow alterId = $cyan$new_alterId$none"
			echo "----------------------------------------------------------------"
			echo
			pause
			backup_config alterId
			alterId=$new_alterId
			config
			clear
			view_v2ray_config_info
			download_v2ray_config_ask
			break
			;;
		*)
			error
			;;
		esac
	done
}
change_socks_user_config() {
	if [[ $v2ray_transport == 17 ]]; then
		echo
		while :; do
			read -p "$(echo -e "请输入$yellow用户名$none...(当前用户名: ${cyan}$username$none)"): " new_username
			[ -z "$new_username" ] && error && continue
			case $new_username in
			$username)
				echo
				echo -e " 大佬...跟 当前用户名 一毛一样啊...修改个鸡鸡哦 "
				echo
				error
				;;
			*[/$]* | *\&*)
				echo
				echo -e " 由于这个脚本太辣鸡了..所以用户名不能包含$red / $none或$red $ $none或$red & $none这三个符号.... "
				echo
				error
				;;
			*)
				echo
				echo
				echo -e "$yellow 用户名 = $cyan$new_username$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				backup_config username
				username=$new_username
				config
				clear
				view_v2ray_config_info
				download_v2ray_config_ask
				break
				;;
			esac
		done
	else
		echo
		echo -e "$red 哎呀....不支持修改呢...$none"
		echo
		echo -e " 必须使用..${cyan} Socks5 $none传输协议才能修改哦"
		echo
		echo -e " 当前传输协议为: ${cyan}${transport[$v2ray_transport - 1]}${none}"
		echo
	fi
}
change_socks_pass_config() {
	if [[ $v2ray_transport == 17 ]]; then
		echo
		while :; do
			read -p "$(echo -e "请输入$yellow密码$none...(当前密码: ${cyan}$userpass$none)"): " new_userpass
			[ -z "$new_userpass" ] && error && continue
			case $new_userpass in
			$userpass)
				echo
				echo -e " 大佬...跟 当前密码 一毛一样啊...修改个鸡鸡哦 "
				echo
				error
				;;
			*[/$]* | *\&*)
				echo
				echo -e " 由于这个脚本太辣鸡了..所以密码不能包含$red / $none或$red $ $none或$red & $none这三个符号.... "
				echo
				error
				;;
			*)
				echo
				echo
				echo -e "$yellow 密码 = $cyan$new_userpass$none"
				echo "----------------------------------------------------------------"
				echo
				pause
				backup_config userpass
				userpass=$new_userpass
				config
				clear
				view_v2ray_config_info
				download_v2ray_config_ask
				break
				;;
			esac
		done
	else
		echo
		echo -e "$red 哎呀....不支持修改呢...$none"
		echo
		echo -e " 必须使用..${cyan} Socks5 $none传输协议才能修改哦"
		echo
		echo -e " 当前传输协议为: ${cyan}${transport[$v2ray_transport - 1]}${none}"
		echo
	fi
}
socks_check() {
	if [[ $v2ray_transport == 17 ]]; then
		echo
		echo -e " 哎呀...由于你当前使用 Socks5 传输协议...是无法执行此功能的哦.."
		echo
		echo -e " 如果你想要查看 Socks5 配置信息的话...请使用$cyan v2ray info $none"
		echo
		exit 1
	fi
}
custom_uuid() {
	echo
	while :; do
		echo -e "请输入$yello自定义的 UUID$none...(${cyan}UUID 格式一定要对!!!$none)"
		read -p "$(echo -e "(当前 UUID: ${cyan}${v2ray_id}$none)"): " myuuid
		[ -z "$myuuid" ] && error && continue
		case $myuuid in
		$v2ray_id)
			echo
			echo -e " 大佬...跟 当前 UUID 一毛一样啊...修改个鸡鸡哦 "
			echo
			error
			;;
		*[/$]* | *\&*)
			echo
			echo -e " 由于这个脚本太辣鸡了..所以 UUID 不能包含$red / $none或$red $ $none或$red & $none这三个符号.... "
			echo
			error
			;;
		*)
			echo
			echo
			echo -e "$yellow UUID = $cyan$myuuid$none"
			echo
			echo -e " 如果 UUID 格式不正确.. V2Ray 会跪...使用$cyan v2ray reuuid$none 复活"
			echo "----------------------------------------------------------------"
			echo
			pause
			uuid=$myuuid
			backup_config uuid
			v2ray_id=$uuid
			config
			clear
			view_v2ray_config_info
			download_v2ray_config_ask
			break
			;;
		esac
	done
}
v2ray_service() {
	while :; do
		echo
		echo -e "$yellow 1. $none启动 V2Ray"
		echo
		echo -e "$yellow 2. $none停止 V2Ray"
		echo
		echo -e "$yellow 3. $none重启 V2Ray"
		echo
		echo -e "$yellow 4. $none查看访问日志"
		echo
		echo -e "$yellow 5. $none查看错误日志"
		echo
		read -p "$(echo -e "请选择 [${magenta}1-5$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				start_v2ray
				break
				;;
			2)
				stop_v2ray
				break
				;;
			3)
				restart_v2ray
				break
				;;
			4)
				view_v2ray_log
				break
				;;
			5)
				view_v2ray_error_log
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
start_v2ray() {
	if [[ $v2ray_pid ]]; then
		echo
		echo -e "${green} V2Ray 正在运行...无需再启动$none"
		echo
	else

		# systemctl start v2ray
		service v2ray start >/dev/null 2>&1
		local is_v2ray_pid=$(ps ux | grep "/usr/bin/v2ray/v2ray" | grep -v grep | awk '{print $2}')
		if [[ $is_v2ray_pid ]]; then
			echo
			echo -e "${green} V2Ray 已启动$none"
			echo
		else
			echo
			echo -e "${red} V2Ray 启动失败！$none"
			echo
		fi

	fi
}
stop_v2ray() {
	if [[ $v2ray_pid ]]; then
		# systemctl stop v2ray
		service v2ray stop >/dev/null 2>&1
		echo
		echo -e "${green} V2Ray 已停止$none"
		echo
	else
		echo
		echo -e "${red} V2Ray 没有在运行$none"
		echo
	fi
}
restart_v2ray() {
	# systemctl restart v2ray
	service v2ray restart >/dev/null 2>&1
	local is_v2ray_pid=$(ps ux | grep "/usr/bin/v2ray/v2ray" | grep -v grep | awk '{print $2}')
	if [[ $is_v2ray_pid ]]; then
		echo
		echo -e "${green} V2Ray 重启完成 $none"
		echo
	else
		echo
		echo -e "${red} V2Ray 重启失败！$none"
		echo
	fi
}
view_v2ray_log() {
	echo
	echo -e "$green 按 Ctrl + C 即可退出...$none"
	echo
	tail -f /var/log/v2ray/access.log
}
view_v2ray_error_log() {
	echo
	echo -e "$green 按 Ctrl + C 即可退出...$none"
	echo
	tail -f /var/log/v2ray/error.log
}
download_v2ray_config() {
	while :; do
		echo
		echo -e "$yellow 1. $none直接下载 V2Ray 客户端配置文件(仅支持 Xshell)"
		echo
		echo -e "$yellow 2. $none生成 V2Ray 客户端配置文件下载链接"
		echo
		echo -e "$yellow 3. $none生成 V2Ray 配置信息链接"
		echo
		echo -e "$yellow 4. $none生成 V2Ray 配置二维码链接"
		echo
		read -p "$(echo -e "请选择 [${magenta}1-4$none]:")" other_opt
		if [[ -z $other_opt ]]; then
			error
		else
			case $other_opt in
			1)
				get_v2ray_config
				break
				;;
			2)
				get_v2ray_config_link
				break
				;;
			3)
				get_v2ray_config_info_link
				break
				;;
			4)
				get_v2ray_config_qr_link
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
get_v2ray_config() {
	config
	echo
	echo " 如果你当前使用的 SSH 客户端不是 Xshell 的话...下载 V2Ray 客户端配置文件将会出现卡死情况"
	echo
	while :; do
		read -p "$(echo -e "不要BB...哥就是在使用 Xshell [${magenta}Y$none]:")" is_xshell
		if [[ -z $is_xshell ]]; then
			error
		else
			if [[ $is_xshell == [yY] ]]; then
				echo
				echo "开始下载....请选择 V2Ray 客户端配置文件保存位置"
				echo
				# sz /etc/v2ray/233blog_v2ray.zip
				local tmpfile="/tmp/233blog_v2ray_config_$RANDOM.json"
				cp -f $v2ray_client_config $tmpfile
				sz $tmpfile
				echo
				echo
				echo -e "$green 下载完成咯...$none"
				echo
				# echo -e "$yellow 解压密码 = ${cyan}233blog.com$none"
				# echo
				echo -e "$yellow SOCKS 监听端口 = ${cyan}2333${none}"
				echo
				echo -e "${yellow} HTTP 监听端口 = ${cyan}6666$none"
				echo
				echo "V2Ray 客户端使用教程: https://233blog.com/post/20/"
				echo
				break
			else
				error
			fi
		fi
	done
	[[ -f $tmpfile ]] && rm -rf $tmpfile

}
get_v2ray_config_link() {
	echo
	echo -e "$green 正在生成链接.... 稍等片刻即可....$none"
	echo
	local random=$(echo $RANDOM-$RANDOM-$RANDOM | base64 -w 0)
	local link=$(curl -s --upload-file $v2ray_client_config "https://transfer.sh/${random}_233blog_v2ray.json")
	if [[ $link ]]; then
		echo
		echo "---------- V2Ray 客户端配置文件链接 -------------"
		echo
		echo -e "$yellow 链接 = $cyan$link$none"
		echo
		echo -e "$yellow SOCKS 监听端口 = ${cyan}2333${none}"
		echo
		echo -e "${yellow} HTTP 监听端口 = ${cyan}6666$none"
		echo
		echo " V2Ray 客户端使用教程: https://233blog.com/post/20/"
		echo
		echo "备注...链接将在 14 天后失效"
		echo
		echo "提醒...请不要把链接分享出去...除非你有特别的理由...."
		echo
	else
		echo
		echo -e "$red 哎呀呀呀...出错咯...请重试$none"
		echo
	fi
}
create_v2ray_config_text() {

	get_transport_args

	echo
	echo
	echo "---------- V2Ray 配置信息 -------------"
	if [[ $v2ray_transport == "4" || $v2ray_transport == 16 ]]; then
		if [[ ! $caddy_installed ]]; then
			echo
			echo " 警告！请自行配置 TLS...教程: https://233blog.com/post/19/"
		fi
		echo
		echo "地址 (Address) = ${domain}"
		echo
		echo "端口 (Port) = 443"
		echo
		echo "用户ID (User ID / UUID) = ${v2ray_id}"
		echo
		echo "额外ID (Alter Id) = ${alterId}"
		echo
		echo "传输协议 (Network) = ${net}"
		echo
		echo "伪装类型 (header type) = ${header}"
		echo
		echo "伪装域名 (host) = ${domain}"
		echo
		echo "路径 (path) = ${_path}"
		echo
		echo "TLS (Enable TLS) = 打开"
		echo
		if [[ $is_blocked_ad ]]; then
			echo " 备注: 广告拦截已开启.."
			echo
		fi
	else
		[[ -z $ip ]] && get_ip
		echo
		echo "地址 (Address) = ${ip}"
		echo
		echo "端口 (Port) = $v2ray_port"
		echo
		echo "用户ID (User ID / UUID) = ${v2ray_id}"
		echo
		echo "额外ID (Alter Id) = ${alterId}"
		echo
		echo "传输协议 (Network) = ${net}"
		echo
		echo "伪装类型 (header type) = ${header}"
		echo
	fi
	if [[ $v2ray_transport -ge 9 || $v2ray_transport -le 15 ]] && [[ $is_blocked_ad ]]; then
		echo "备注: 动态端口已启用...广告拦截已开启..."
		echo
	elif [[ $v2ray_transport -ge 9 || $v2ray_transport -le 15 ]]; then
		echo "备注: 动态端口已启用..."
		echo
	elif [[ $is_blocked_ad ]]; then
		echo "备注: 广告拦截已开启.."
		echo
	fi
	echo "---------- END -------------"
	echo
	echo "V2Ray 客户端使用教程: https://233blog.com/post/20/"
	echo
}
get_v2ray_config_info_link() {
	socks_check
	echo
	echo -e "$green 正在生成链接.... 稍等片刻即可....$none"
	echo
	create_v2ray_config_text >/tmp/233blog_v2ray.txt
	local random=$(echo $RANDOM-$RANDOM-$RANDOM | base64 -w 0)
	local link=$(curl -s --upload-file /tmp/233blog_v2ray.txt "https://transfer.sh/${random}_233blog_v2ray.txt")
	if [[ $link ]]; then
		echo
		echo "---------- V2Ray 配置信息链接-------------"
		echo
		echo -e "$yellow 链接 = $cyan$link$none"
		echo
		echo -e " V2Ray 客户端使用教程: https://233blog.com/post/20/"
		echo
		echo "备注...链接将在 14 天后失效..."
		echo
		echo "提醒...请不要把链接分享出去...除非你有特别的理由...."
		echo
	else
		echo
		echo -e "$red 哎呀呀呀...出错咯...请重试$none"
		echo
	fi
	rm -rf /tmp/233blog_v2ray.txt
}
get_v2ray_config_qr_link() {

	socks_check
	create_vmess_URL_config

	echo
	echo -e "$green 正在生成链接.... 稍等片刻即可....$none"
	echo
	local vmess="vmess://$(cat /etc/v2ray/vmess_qr.json | tr -d '\n' | base64 -w 0)"
	echo $vmess | tr -d '\n' >/etc/v2ray/vmess.txt
	cat /etc/v2ray/vmess.txt | qrencode -s 50 -o /tmp/233blog_v2ray.png
	local random=$(echo $RANDOM-$RANDOM-$RANDOM | base64 -w 0)
	local link=$(curl -s --upload-file /tmp/233blog_v2ray.png "https://transfer.sh/${random}_233blog_v2ray.png")
	if [[ $link ]]; then
		echo
		echo "---------- V2Ray 二维码链接 -------------"
		echo
		echo -e "$yellow 适用于 V2RayNG v0.4.1+ / Kitsunebi = $cyan$link$none"
		echo
		echo
		echo " V2Ray 客户端使用教程: https://233blog.com/post/20/"
		echo
		echo "备注...链接将在 14 天后失效"
		echo
		echo "提醒...请不要把链接分享出去...除非你有特别的理由...."
		echo
	else
		echo
		echo -e "$red 哎呀呀呀...出错咯...$none"
		echo
		echo -e "请尝试使用${cyan} v2ray qr ${none}重新生成"
		echo
	fi
	rm -rf /tmp/233blog_v2ray.png
	# rm -rf /etc/v2ray/vmess_qr.json
	# rm -rf /etc/v2ray/vmess.txt
}
get_v2ray_vmess_URL_link() {
	socks_check
	create_vmess_URL_config
	local vmess="vmess://$(cat /etc/v2ray/vmess_qr.json | base64 -w 0)"
	echo
	echo "---------- V2Ray vmess URL / V2RayNG v0.4.1+ / V2RayN v2.1+ / 仅适合部分客户端 -------------"
	echo
	echo -e ${cyan}$vmess${none}
	echo
	rm -rf /etc/v2ray/vmess_qr.json
}
other() {
	while :; do
		echo
		echo -e "$yellow 1. $none安装 BBR"
		echo
		echo -e "$yellow 2. $none安装 LotServer(锐速)"
		echo
		echo -e "$yellow 3. $none卸载 LotServer(锐速)"
		echo
		read -p "$(echo -e "请选择 [${magenta}1-3$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				install_bbr
				break
				;;
			2)
				install_lotserver
				break
				;;
			3)
				uninstall_lotserver
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
install_bbr() {
	local test1=$(sed -n '/net.ipv4.tcp_congestion_control/p' /etc/sysctl.conf)
	local test2=$(sed -n '/net.core.default_qdisc/p' /etc/sysctl.conf)
	if [[ $(uname -r | cut -b 1) -eq 4 ]]; then
		case $(uname -r | cut -b 3-4) in
		9. | [1-9][0-9])
			if [[ $test1 == "net.ipv4.tcp_congestion_control = bbr" && $test2 == "net.core.default_qdisc = fq" ]]; then
				local is_bbr=true
			else
				local try_enable_bbr=true
			fi
			;;
		esac
	fi
	if [[ $is_bbr ]]; then
		echo
		echo -e "$green BBR 已经启用啦...无需再安装$none"
		echo
	elif [[ $try_enable_bbr ]]; then
		sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
		sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
		echo "net.ipv4.tcp_congestion_control = bbr" >>/etc/sysctl.conf
		echo "net.core.default_qdisc = fq" >>/etc/sysctl.conf
		sysctl -p >/dev/null 2>&1
		echo
		echo -e "$green ..由于你的小鸡鸡的内核支持开启 BBR ...已经为你启用 BBR 优化....$none"
		echo
	else
		# https://teddysun.com/489.html
		bash <(curl -s -L https://github.com/teddysun/across/raw/master/bbr.sh)
	fi
}
install_lotserver() {
	# https://moeclub.org/2017/03/08/14/
	wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh"
	bash /tmp/appex.sh 'install'
	rm -rf /tmp/appex.sh
}
uninstall_lotserver() {
	# https://moeclub.org/2017/03/08/14/
	wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh"
	bash /tmp/appex.sh 'uninstall'
	rm -rf /tmp/appex.sh
}

open_port() {
	if [[ $1 != "multiport" ]]; then
		# if [[ $cmd == "apt-get" ]]; then
		iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		iptables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		ip6tables -I INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT

		# iptables-save >/etc/iptables.rules.v4
		# ip6tables-save >/etc/iptables.rules.v6
		# else
		# 	firewall-cmd --permanent --zone=public --add-port=$1/tcp
		# 	firewall-cmd --permanent --zone=public --add-port=$1/udp
		# 	firewall-cmd --reload
		# fi
	else
		# if [[ $cmd == "apt-get" ]]; then
		local multiport="${v2ray_dynamic_port_start_input}:${v2ray_dynamic_port_end_input}"
		iptables -I INPUT -p tcp --match multiport --dports $multiport -j ACCEPT
		iptables -I INPUT -p udp --match multiport --dports $multiport -j ACCEPT
		ip6tables -I INPUT -p tcp --match multiport --dports $multiport -j ACCEPT
		ip6tables -I INPUT -p udp --match multiport --dports $multiport -j ACCEPT

		# iptables-save >/etc/iptables.rules.v4
		# ip6tables-save >/etc/iptables.rules.v6
		# else
		# 	local multi_port="${v2ray_dynamic_port_start_input}-${v2ray_dynamic_port_end_input}"
		# 	firewall-cmd --permanent --zone=public --add-port=$multi_port/tcp
		# 	firewall-cmd --permanent --zone=public --add-port=$multi_port/udp
		# 	firewall-cmd --reload
		# fi
	fi
	if [[ $cmd == "apt-get" ]]; then
		iptables-save >/etc/iptables.rules.v4
		ip6tables-save >/etc/iptables.rules.v6
	else
		service iptables save >/dev/null 2>&1
		service ip6tables save >/dev/null 2>&1
	fi

}
del_port() {
	if [[ $1 != "multiport" ]]; then
		# if [[ $cmd == "apt-get" ]]; then
		iptables -D INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		iptables -D INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m tcp -p tcp --dport $1 -j ACCEPT
		ip6tables -D INPUT -m state --state NEW -m udp -p udp --dport $1 -j ACCEPT
		# else
		# 	firewall-cmd --permanent --zone=public --remove-port=$1/tcp
		# 	firewall-cmd --permanent --zone=public --remove-port=$1/udp
		# fi
	else
		# if [[ $cmd == "apt-get" ]]; then
		local ports="${v2ray_dynamicPort_start}:${v2ray_dynamicPort_end}"
		iptables -D INPUT -p tcp --match multiport --dports $ports -j ACCEPT
		iptables -D INPUT -p udp --match multiport --dports $ports -j ACCEPT
		ip6tables -D INPUT -p tcp --match multiport --dports $ports -j ACCEPT
		ip6tables -D INPUT -p udp --match multiport --dports $ports -j ACCEPT
		# else
		# 	local ports="${v2ray_dynamicPort_start}-${v2ray_dynamicPort_end}"
		# 	firewall-cmd --permanent --zone=public --remove-port=$ports/tcp
		# 	firewall-cmd --permanent --zone=public --remove-port=$ports/udp
		# fi
	fi
	if [[ $cmd == "apt-get" ]]; then
		iptables-save >/etc/iptables.rules.v4
		ip6tables-save >/etc/iptables.rules.v6
	else
		service iptables save >/dev/null 2>&1
		service ip6tables save >/dev/null 2>&1
	fi
}
update() {
	while :; do
		echo
		echo -e "$yellow 1. $none更新 V2Ray 主程序"
		echo
		echo -e "$yellow 2. $none更新 V2Ray 管理脚本"
		echo
		read -p "$(echo -e "请选择 [${magenta}1-2$none]:")" _opt
		if [[ -z $_opt ]]; then
			error
		else
			case $_opt in
			1)
				update_v2ray
				break
				;;
			2)
				update_v2ray.sh
				exit
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
update_v2ray() {
	[ -d /tmp/v2ray ] && rm -rf /tmp/v2ray
	mkdir -p /tmp/v2ray

	v2ray_tmp_file="/tmp/v2ray/v2ray.zip"
	v2ray_latest_ver="$(curl -s "https://api.github.com/repos/v2ray/v2ray-core/releases/latest?r=$RANDOM" | grep 'tag_name' | cut -d\" -f4)"
	if [[ $v2ray_ver != $v2ray_latest_ver ]]; then
		echo
		echo -e " $green 咦...发现新版本耶....正在拼命更新.......$none"
		echo
		v2ray_download_link="https://github.com/v2ray/v2ray-core/releases/download/$v2ray_latest_ver/v2ray-linux-${v2ray_bit}.zip"

		if ! wget --no-check-certificate -O "$v2ray_tmp_file" $v2ray_download_link; then
			echo -e "
			$red 下载 V2Ray 文件失败啦..可能是你的小鸡鸡的网络太辣鸡了...重新尝试更新也许能解决$none
			" && exit 1
		fi

		unzip $v2ray_tmp_file -d "/tmp/v2ray/"
		mkdir -p /usr/bin/v2ray
		cp -f "/tmp/v2ray/v2ray-${v2ray_latest_ver}-linux-${v2ray_bit}/v2ray" "/usr/bin/v2ray/v2ray"
		chmod +x "/usr/bin/v2ray/v2ray"
		cp -f "/tmp/v2ray/v2ray-${v2ray_latest_ver}-linux-${v2ray_bit}/v2ctl" "/usr/bin/v2ray/v2ctl"
		chmod +x "/usr/bin/v2ray/v2ctl"
		# systemctl restart v2ray
		# service v2ray restart >/dev/null 2>&1
		do_service restart v2ray
		echo
		echo -e " $green 更新成功啦...当前 V2Ray 版本: ${cyan}$v2ray_latest_ver$none"
		echo
		echo -e " $yellow 温馨提示: 为了避免出现莫名其妙的问题...所以客户端 V2Ray 版本最好也是: ${cyan}$v2ray_latest_ver$none"
		echo
		rm -rf /tmp/v2ray
	else
		echo
		echo -e " $green 木有发现新版本....$none"
		echo
	fi
}
update_v2ray.sh() {
	local latest_version=$(curl -s -L "https://raw.githubusercontent.com/233boy/v2ray/master/v2ray.sh?r=$RANDOM" | grep '_version' -m1 | cut -d\" -f2)
	if [[ $latest_version == $_version ]]; then
		echo
		echo -e "$green 木有发现新版本 $none"
		echo
	else
		echo
		echo -e " $green 咦...发现新版本耶....正在拼命更新.......$none"
		echo
		cd /etc/v2ray/233boy/v2ray
		git pull
		cp -f /etc/v2ray/233boy/v2ray/v2ray.sh $_v2ray_sh
		chmod +x $_v2ray_sh
		echo
		echo -e "$green 更新成功啦...当前 V2Ray 管理脚本 版本: ${cyan}$latest_version$none"
		echo
	fi

}
uninstall_v2ray() {
	while :; do
		echo
		read -p "$(echo -e "是否卸载 ${yellow}V2Ray$none [${magenta}Y/N$none]:")" uninstall_v2ray_ask
		if [[ -z $uninstall_v2ray_ask ]]; then
			error
		else
			case $uninstall_v2ray_ask in
			Y | y)
				is_uninstall_v2ray=true
				echo
				echo -e "$yellow 卸载 V2Ray = ${cyan}是${none}"
				echo
				break
				;;
			N | n)
				echo
				echo -e "$red 卸载已取消...$none"
				echo
				break
				;;
			*)
				error
				;;
			esac
		fi
	done

	if [[ $caddy_installed ]] && [[ -f /usr/local/bin/caddy && -f /etc/caddy/Caddyfile ]]; then
		while :; do
			echo
			read -p "$(echo -e "是否卸载 ${yellow}Caddy$none [${magenta}Y/N$none]:")" uninstall_caddy_ask
			if [[ -z $uninstall_caddy_ask ]]; then
				error
			else
				case $uninstall_caddy_ask in
				Y | y)
					is_uninstall_caddy=true
					echo
					echo -e "$yellow 卸载 Caddy = ${cyan}是${none}"
					echo
					break
					;;
				N | n)
					echo
					echo -e "$yellow 卸载 Caddy = ${cyan}否${none}"
					echo
					break
					;;
				*)
					error
					;;
				esac
			fi
		done
	fi

	if [[ $is_uninstall_v2ray && $is_uninstall_caddy ]]; then
		pause
		echo

		if [[ $shadowsocks ]]; then
			del_port $ssport
		fi

		if [[ $v2ray_transport == "4" || $v2ray_transport == 16 ]]; then
			del_port "80"
			del_port "443"
			del_port $v2ray_port
		elif [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]]; then
			del_port $v2ray_port
			del_port "multiport"
		else
			del_port $v2ray_port
		fi

		[ $cmd == "apt-get" ] && rm -rf /etc/network/if-pre-up.d/iptables

		# [ $v2ray_pid ] && systemctl stop v2ray
		[ $v2ray_pid ] && do_service stop v2ray

		rm -rf /usr/bin/v2ray
		rm -rf $_v2ray_sh
		rm -rf /etc/v2ray
		rm -rf /var/log/v2ray

		# [ $caddy_pid ] && systemctl stop caddy
		[ $caddy_pid ] && do_service stop caddy

		rm -rf /usr/local/bin/caddy
		rm -rf /etc/caddy
		rm -rf /etc/ssl/caddy

		if [[ $systemd ]]; then
			systemctl disable v2ray >/dev/null 2>&1
			rm -rf /lib/systemd/system/v2ray.service
			systemctl disable caddy >/dev/null 2>&1
			rm -rf /lib/systemd/system/caddy.service
		else
			update-rc.d -f caddy remove >/dev/null 2>&1
			update-rc.d -f v2ray remove >/dev/null 2>&1
			rm -rf /etc/init.d/caddy
			rm -rf /etc/init.d/v2ray
		fi
		# clear
		echo
		echo -e "$green V2Ray 卸载完成啦 ....$none"
		echo
		echo "如果你觉得这个脚本有哪些地方不够好的话...请告诉我"
		echo
		echo "反馈问题: https://github.com/233boy/v2ray/issues"
		echo

	elif [[ $is_uninstall_v2ray ]]; then
		pause
		echo

		if [[ $shadowsocks ]]; then
			del_port $ssport
		fi

		if [[ $v2ray_transport == "4" || $v2ray_transport == 16 ]]; then
			del_port "80"
			del_port "443"
			del_port $v2ray_port
		elif [[ $v2ray_transport -ge 9 && $v2ray_transport -le 15 ]]; then
			del_port $v2ray_port
			del_port "multiport"
		else
			del_port $v2ray_port
		fi

		[ $cmd == "apt-get" ] && rm -rf /etc/network/if-pre-up.d/iptables

		# [ $v2ray_pid ] && systemctl stop v2ray
		[ $v2ray_pid ] && do_service stop v2ray

		rm -rf /usr/bin/v2ray
		rm -rf $_v2ray_sh
		rm -rf /etc/v2ray
		rm -rf /var/log/v2ray
		if [[ $systemd ]]; then
			systemctl disable v2ray >/dev/null 2>&1
			rm -rf /lib/systemd/system/v2ray.service
		else
			update-rc.d -f v2ray remove >/dev/null 2>&1
			rm -rf /etc/init.d/v2ray
		fi
		# clear
		echo
		echo -e "$green V2Ray 卸载完成啦 ....$none"
		echo
		echo "如果你觉得这个脚本有哪些地方不够好的话...请告诉我"
		echo
		echo "反馈问题: https://github.com/233boy/v2ray/issues"
		echo
	fi
}
config() {
	if [[ $shadowsocks ]]; then
		if [[ $is_blocked_ad ]]; then
			case $v2ray_transport in
			1)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/tcp_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			2)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/http_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			3)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			4)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws_tls.json"
				;;
			5 | 6 | 7 | 8)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/kcp_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			9)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/tcp_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			10)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/http_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			11)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			12 | 13 | 14 | 15)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/kcp_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			16)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/h2_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/h2.json"
				;;
			17)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/socks_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/socks.json"
				;;
			esac
		else
			case $v2ray_transport in
			1)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/tcp_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			2)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/http_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			3)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			4)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws_tls.json"
				;;
			5 | 6 | 7 | 8)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/kcp_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			9)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/tcp_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			10)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/http_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			11)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			12 | 13 | 14 | 15)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/kcp_ss_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			16)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/h2_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/h2.json"
				;;
			17)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/socks_ss.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/socks.json"
				;;
			esac
		fi
	else
		if [[ $is_blocked_ad ]]; then
			case $v2ray_transport in
			1)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/tcp.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			2)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/http.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			3)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			4)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws_tls.json"
				;;
			5 | 6 | 7 | 8)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/kcp.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			9)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/erver/tcp_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			10)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/http_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			11)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/ws_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			12 | 13 | 14 | 15)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/kcp_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			16)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/h2.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/h2.json"
				;;
			17)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/blocked_hosts/server/socks.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/socks.json"
				;;
			esac
		else
			case $v2ray_transport in
			1)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/tcp.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			2)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/http.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			3)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			4)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws_tls.json"
				;;
			5 | 6 | 7 | 8)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/kcp.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			9)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/tcp_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/tcp.json"
				;;
			10)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/http_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/http.json"
				;;
			11)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/ws_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/ws.json"
				;;
			12 | 13 | 14 | 15)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/kcp_dynamic.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/kcp.json"
				;;
			16)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/h2.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/h2.json"
				;;
			17)
				v2ray_server_config_file="/etc/v2ray/233boy/v2ray/config/server/socks.json"
				v2ray_client_config_file="/etc/v2ray/233boy/v2ray/config/client/socks.json"
				;;
			esac
		fi

	fi

	cp -f $v2ray_server_config_file $v2ray_server_config
	cp -f $v2ray_client_config_file $v2ray_client_config

	if [[ $shadowsocks ]]; then
		case $v2ray_transport in
		1)
			sed -i "28s/6666/$ssport/; 30s/chacha20-ietf/$ssciphers/; 31s/233blog.com/$sspass/" $v2ray_server_config
			;;
		2)
			sed -i "64s/6666/$ssport/; 66s/chacha20-ietf/$ssciphers/; 67s/233blog.com/$sspass/" $v2ray_server_config
			;;
		3 | 4)
			sed -i "31s/6666/$ssport/; 33s/chacha20-ietf/$ssciphers/; 34s/233blog.com/$sspass/" $v2ray_server_config
			;;
		5 | 6 | 7 | 8)
			sed -i "43s/6666/$ssport/; 45s/chacha20-ietf/$ssciphers/; 46s/233blog.com/$sspass/" $v2ray_server_config
			;;
		9)
			sed -i "31s/6666/$ssport/; 33s/chacha20-ietf/$ssciphers/; 34s/233blog.com/$sspass/; 42s/10000-20000/$port_range/" $v2ray_server_config
			;;
		10)
			sed -i "67s/6666/$ssport/; 69s/chacha20-ietf/$ssciphers/; 70s/233blog.com/$sspass/; 78s/10000-20000/$port_range/" $v2ray_server_config
			;;
		1[1-5])
			sed -i "34s/6666/$ssport/; 36s/chacha20-ietf/$ssciphers/; 37s/233blog.com/$sspass/; 45s/10000-20000/$port_range/" $v2ray_server_config
			;;
		16)
			sed -i "46s/6666/$ssport/; 48s/chacha20-ietf/$ssciphers/; 49s/233blog.com/$sspass/" $v2ray_server_config
			;;
		17)
			sed -i "30s/6666/$ssport/; 32s/chacha20-ietf/$ssciphers/; 33s/233blog.com/$sspass/" $v2ray_server_config
			;;
		esac

		case $v2ray_transport in
		6)
			sed -i "31s/none/utp/" $v2ray_server_config
			sed -i "44s/none/utp/" $v2ray_client_config
			;;
		7)
			sed -i "31s/none/srtp/" $v2ray_server_config
			sed -i "44s/none/srtp/" $v2ray_client_config
			;;
		8)
			sed -i "31s/none/wechat-video/" $v2ray_server_config
			sed -i "44s/none/wechat-video/" $v2ray_client_config
			;;
		13)
			sed -i "74s/none/utp/" $v2ray_server_config
			sed -i "44s/none/utp/" $v2ray_client_config
			;;
		14)
			sed -i "74s/none/srtp/" $v2ray_server_config
			sed -i "44s/none/srtp/" $v2ray_client_config
			;;
		15)
			sed -i "74s/none/wechat-video/" $v2ray_server_config
			sed -i "44s/none/wechat-video/" $v2ray_client_config
			;;
		esac

	else
		case $v2ray_transport in
		9)
			sed -i "31s/10000-20000/$port_range/" $v2ray_server_config
			;;
		10)
			sed -i "67s/10000-20000/$port_range/" $v2ray_server_config
			;;
		1[1-5])
			sed -i "34s/10000-20000/$port_range/" $v2ray_server_config
			;;
		esac

		case $v2ray_transport in
		6)
			sed -i "31s/none/utp/" $v2ray_server_config
			sed -i "44s/none/utp/" $v2ray_client_config
			;;
		7)
			sed -i "31s/none/srtp/" $v2ray_server_config
			sed -i "44s/none/srtp/" $v2ray_client_config
			;;
		8)
			sed -i "31s/none/wechat-video/" $v2ray_server_config
			sed -i "44s/none/wechat-video/" $v2ray_client_config
			;;
		13)
			sed -i "63s/none/utp/" $v2ray_server_config
			sed -i "44s/none/utp/" $v2ray_client_config
			;;
		14)
			sed -i "63s/none/srtp/" $v2ray_server_config
			sed -i "44s/none/srtp/" $v2ray_client_config
			;;
		15)
			sed -i "63s/none/wechat-video/" $v2ray_server_config
			sed -i "44s/none/wechat-video/" $v2ray_client_config
			;;
		esac

	fi

	if [[ $v2ray_transport == 17 ]]; then
		sed -i "8s/2333/$v2ray_port/; 14s/233blog/$username/; 15s/233blog.com/$userpass/" $v2ray_server_config
	else
		sed -i "8s/2333/$v2ray_port/; 14s/$old_id/$v2ray_id/; 16s/233/$alterId/" $v2ray_server_config
	fi
	if [[ $v2ray_transport -eq 16 ]]; then
		sed -i "24s/233blog.com/$domain/" $v2ray_server_config
		if [[ $is_path ]]; then
			sed -i "26s/233blog/$path/" $v2ray_server_config
		else
			sed -i "26s/233blog//" $v2ray_server_config
		fi
	fi

	[[ -z $ip ]] && get_ip
	if [[ $v2ray_transport -eq 4 || $v2ray_transport -eq 16 ]]; then
		sed -i "s/233blog.com/$domain/; 22s/2333/443/; 25s/$old_id/$v2ray_id/; 26s/233/$alterId/" $v2ray_client_config
		if [[ $is_path ]]; then
			sed -i "40s/233blog/$path/" $v2ray_client_config
		else
			sed -i "40s/233blog//" $v2ray_client_config
		fi
	elif [[ $v2ray_transport == 17 ]]; then
		sed -i "21s/233blog.com/$ip/; 22s/2333/$v2ray_port/; 25s/233blog/$username/; 26s/233blog.com/$userpass/" $v2ray_client_config
	else
		sed -i "s/233blog.com/$ip/; 22s/2333/$v2ray_port/; 25s/$old_id/$v2ray_id/; 26s/233/$alterId/" $v2ray_client_config
	fi

	# zip -q -r -j --password "233blog.com" /etc/v2ray/233blog_v2ray.zip $v2ray_client_config

	if [[ $v2ray_port == "80" ]]; then
		if [[ $cmd == "yum" ]]; then
			[[ $(pgrep "httpd") ]] && systemctl stop httpd >/dev/null 2>&1
			[[ $(command -v httpd) ]] && yum remove httpd -y >/dev/null 2>&1
		else
			[[ $(pgrep "apache2") ]] && service apache2 stop >/dev/null 2>&1
			[[ $(command -v apache2) ]] && apt-get remove apache2* -y >/dev/null 2>&1
		fi
	fi
	do_service restart v2ray
}
backup_config() {
	for keys in $*; do
		case $keys in
		v2ray_transport)
			sed -i "18s/=$v2ray_transport/=$v2ray_transport_opt/" $backup
			;;
		v2ray_port)
			sed -i "21s/=$v2ray_port/=$v2ray_port_opt/" $backup
			;;
		uuid)
			sed -i "24s/=$v2ray_id/=$uuid/" $backup
			;;
		alterId)
			sed -i "27s/=$alterId/=$new_alterId/" $backup
			;;
		v2ray_dynamicPort_start)
			sed -i "30s/=$v2ray_dynamicPort_start/=$v2ray_dynamic_port_start_input/" $backup
			;;
		v2ray_dynamicPort_end)
			sed -i "33s/=$v2ray_dynamicPort_end/=$v2ray_dynamic_port_end_input/" $backup
			;;
		domain)
			sed -i "36s/=$domain/=$new_domain/" $backup
			;;
		caddy)
			sed -i "39s/=/=true/" $backup
			;;
		+ss)
			sed -i "42s/=/=true/; 45s/=$ssport/=$new_ssport/; 48s/=$sspass/=$new_sspass/; 51s/=$ssciphers/=$new_ssciphers/" $backup
			;;
		-ss)
			sed -i "42s/=true/=/" $backup
			;;
		ssport)
			sed -i "45s/=$ssport/=$new_ssport/" $backup
			;;
		sspass)
			sed -i "48s/=$sspass/=$new_sspass/" $backup
			;;
		ssciphers)
			sed -i "51s/=$ssciphers/=$new_ssciphers/" $backup
			;;
		+ad)
			sed -i "54s/=/=true/" $backup
			;;
		-ad)
			sed -i "54s/=true/=/" $backup
			;;
		+path)
			sed -i "57s/=/=true/; 60s/=$path/=$new_path/; 63s#=$proxy_site#=$new_proxy_site#" $backup
			;;
		-path)
			sed -i "57s/=true/=/" $backup
			;;
		path)
			sed -i "60s/=$path/=$new_path/" $backup
			;;
		proxy_site)
			sed -i "63s#=$proxy_site#=$new_proxy_site#" $backup
			;;
		username)
			sed -i "66s/=$username/=$new_username/" $backup
			;;
		userpass)
			sed -i "69s/=$userpass/=$new_userpass/" $backup
			;;
		esac
	done

}
_boom_() {
	echo
	echo -e "$green ........... V2Ray 配置链接集合 by 233blog.com  ..........$none"
	echo

	create_v2ray_config_text >/tmp/233blog_v2ray.txt

	create_vmess_URL_config

	local vmess="vmess://$(cat /etc/v2ray/vmess_qr.json | base64 -w 0)"
	echo $vmess >/etc/v2ray/vmess.txt
	cat /etc/v2ray/vmess.txt | qrencode -s 50 -o /tmp/233blog_v2ray.png

	local random1=$(echo $RANDOM-$RANDOM-$RANDOM | base64 -w 0)
	local random2=$(echo $RANDOM-$RANDOM-$RANDOM | base64 -w 0)
	local random3=$(echo $RANDOM-$RANDOM-$RANDOM | base64 -w 0)
	local link1=$(curl -s --upload-file $v2ray_client_config "https://transfer.sh/${random1}_233blog_v2ray.json")
	local link2=$(curl -s --upload-file /tmp/233blog_v2ray.txt "https://transfer.sh/${random2}_233blog_v2ray.txt")
	local link3=$(curl -s --upload-file /tmp/233blog_v2ray.png "https://transfer.sh/${random3}_233blog_v2ray.png")

	if [[ $link1 ]] && [[ $link2 && $link3 ]]; then
		echo -e "$yellow 客户端配置文件链接: $cyan$link1$none"
		echo
		echo -e "$yellow 配置信息链接: $cyan$link2$none"
		echo
		echo -e "$yellow V2RayNG v0.4.1+ / Kitsunebi 二维码链接: $cyan$link3$none"
		echo
		echo "V2Ray 客户端使用教程: https://233blog.com/post/20/"
		echo
	else
		echo
		echo -e "$red 哎呀..发生了一点意外的情况.....请重试....$none"
		echo
	fi
	rm -rf /tmp/233blog_v2ray.txt
	rm -rf /etc/v2ray/vmess_qr.json
	rm -rf /etc/v2ray/vmess.txt
	rm -rf /tmp/233blog_v2ray.png

}

get_ip() {
	ip=$(curl -s ipinfo.io/ip)
}

error() {

	echo -e "\n$red 输入错误！$none\n"

}

pause() {

	read -rsp "$(echo -e "按$green Enter 回车键 $none继续....或按$red Ctrl + C $none取消.")" -d $'\n'
	echo
}
do_service() {
	if [[ $systemd ]]; then
		systemctl $1 $2
	else
		service $2 $1
	fi
}
_help() {
	echo
	echo "........... V2Ray 管理脚本帮助信息 by 233blog.com .........."
	echo -e "
	${green}v2ray menu $none管理 V2Ray (同等于直接输入 v2ray)

	${green}v2ray info $none查看 V2Ray 配置信息

	${green}v2ray config $none修改 V2Ray 配置

	${green}v2ray link $none生成 V2Ray 客户端配置文件链接

	${green}v2ray textlink $none生成 V2Ray 配置信息链接

	${green}v2ray qr $none生成 V2Ray 配置二维码链接

	${green}v2ray ss $none修改 Shadowsocks 配置

	${green}v2ray ssinfo $none查看 Shadowsocks 配置信息

	${green}v2ray ssqr $none生成 Shadowsocks 配置二维码链接

	${green}v2ray status $none查看 V2Ray 运行状态

	${green}v2ray start $none启动 V2Ray

	${green}v2ray stop $none停止 V2Ray

	${green}v2ray restart $none重启 V2Ray

	${green}v2ray log $none查看 V2Ray 运行日志

	${green}v2ray update $none更新 V2Ray

	${green}v2ray update.sh $none更新 V2Ray 管理脚本

	${green}v2ray uninstall $none卸载 V2Ray
"
}
menu() {
	clear
	while :; do
		echo
		echo "........... V2Ray 管理脚本 $_version by 233blog.com .........."
		echo
		echo -e "## V2Ray 版本: $cyan$v2ray_ver$none  /  V2Ray 状态: $v2ray_status ##"
		echo
		echo "帮助说明: https://233blog.com/post/16/"
		echo
		echo "反馈问题: https://github.com/233boy/v2ray/issues"
		echo
		echo "TG 群组: https://t.me/blog233"
		echo
		echo "捐赠脚本作者: https://233blog.com/donate/"
		echo
		echo "捐助 V2Ray: https://www.v2ray.com/chapter_00/02_donate.html"
		echo
		echo -e "$yellow 1. $none查看 V2Ray 配置"
		echo
		echo -e "$yellow 2. $none修改 V2Ray 配置"
		echo
		echo -e "$yellow 3. $none下载 V2Ray 配置 / 生成配置信息链接 / 生成二维码链接"
		echo
		echo -e "$yellow 4. $none查看 Shadowsocks 配置 / 生成二维码链接"
		echo
		echo -e "$yellow 5. $none修改 Shadowsocks 配置"
		echo
		echo -e "$yellow 6. $none启动 / 停止 / 重启 / 查看日志"
		echo
		echo -e "$yellow 7. $none更新 V2Ray / 更新 V2Ray 管理脚本"
		echo
		echo -e "$yellow 8. $none卸载 V2Ray"
		echo
		echo -e "$yellow 9. $none其他"
		echo
		echo -e "温馨提示...如果你不想执行选项...按$yellow Ctrl + C $none即可退出"
		echo
		read -p "$(echo -e "请选择菜单 [${magenta}1-9$none]:")" choose
		if [[ -z $choose ]]; then
			exit 1
		else
			case $choose in
			1)
				view_v2ray_config_info
				break
				;;
			2)
				change_v2ray_config
				break
				;;
			3)
				download_v2ray_config
				break
				;;
			4)
				get_shadowsocks_config
				break
				;;
			5)
				change_shadowsocks_config
				break
				;;
			6)
				v2ray_service
				break
				;;
			7)
				update
				break
				;;
			8)
				uninstall_v2ray
				break
				;;
			9)
				other
				break
				;;
			*)
				error
				;;
			esac
		fi
	done
}
args=$1
[ -z $1 ] && args="menu"
case $args in
menu)
	menu
	;;
i | info)
	view_v2ray_config_info
	;;
c | config)
	change_v2ray_config
	;;
l | link)
	get_v2ray_config_link
	;;
L | infolink)
	get_v2ray_config_info_link
	;;
q | qr)
	get_v2ray_config_qr_link
	;;
s | ss)
	change_shadowsocks_config
	;;
S | ssinfo)
	view_shadowsocks_config_info
	;;
Q | ssqr)
	get_shadowsocks_config_qr_link
	;;
status)
	echo
	if [[ $v2ray_transport == "4" && $caddy_installed ]]; then
		echo -e " V2Ray 状态: $v2ray_status  /  Caddy 状态: $caddy_run_status"
	else
		echo -e " V2Ray 状态: $v2ray_status"
	fi
	echo
	;;
start)
	start_v2ray
	;;
stop)
	stop_v2ray
	;;
restart)
	[[ $v2ray_transport == "4" && $caddy_installed ]] && do_service restart caddy
	restart_v2ray
	;;
reload)
	config
	[[ $v2ray_transport == "4" && $caddy_installed ]] && caddy_config
	clear
	view_v2ray_config_info
	download_v2ray_config_ask
	;;
log)
	view_v2ray_log
	;;
url | URL)
	get_v2ray_vmess_URL_link
	;;
u | update)
	update_v2ray
	;;
U | update.sh)
	update_v2ray.sh
	exit
	;;
un | uninstall)
	uninstall_v2ray
	;;
reinstall)
	uninstall_v2ray
	if [[ $is_uninstall_v2ray ]]; then
		cd
		cd - >/dev/null 2>&1
		bash <(curl -s -L https://233blog.com/v2ray.sh)
	fi
	;;
233 | 2333 | 233boy | 233blog | 233blog.com)
	socks_check
	_boom_
	;;
[aA][Ii] | [Dd])
	socks_check
	change_v2ray_alterId
	;;
[aA][Ii][aA][Ii] | [Dd][Dd])
	socks_check
	custom_uuid
	;;
reuuid)
	socks_check
	backup_config uuid
	v2ray_id=$uuid
	config
	clear
	view_v2ray_config_info
	download_v2ray_config_ask
	;;
v | version)
	echo
	echo -e " 当前 V2Ray 版本: ${green}$v2ray_ver$none  /  当前 V2Ray 管理脚本版本: ${cyan}$_version$none"
	echo
	;;
bbr)
	other
	;;
help | *)
	_help
	;;
esac
