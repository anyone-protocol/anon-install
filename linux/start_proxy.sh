#!/bin/bash

if [[ "$(uname)" == "Linux" ]];then


	if [[ ! -f anon-live-linux-$(dpkg --print-architecture).zip ]];then
		curl -o anon.zip -fsSLO https://github.com/anyone-protocol/ator-protocol/releases/download/v0.4.9.6/anon-live-linux-$(dpkg --print-architecture).zip
	fi

	unzip -o anon.zip anon > /dev/null 2>&1

	kill $(pgrep anon) > /dev/null 2>&1

	echo -e "SocksPort 127.0.0.1:9050\nSocksPolicy accept 127.0.0.1\nSocksPolicy reject *\nHTTPTunnelPort 127.0.0.1:9058" > anonrc

	./anon -f anonrc &

	sleep 1

	gsettings set org.gnome.system.proxy mode "manual"
	gsettings set org.gnome.system.proxy.http host "127.0.0.1"
	gsettings set org.gnome.system.proxy.http port 9058
	gsettings set org.gnome.system.proxy.https host "127.0.0.1"
	gsettings set org.gnome.system.proxy.https port 9058
	gsettings set org.gnome.system.proxy.socks host "127.0.0.1"
	gsettings set org.gnome.system.proxy.socks port 9050

	sleep 1

	ExitIP="$(curl -s --socks5 127.0.0.1:9050 https://check.en.anyone.tech/api/ip -s | cut -d'"' -f6)"
	IsAnon="$(curl -s --socks5 127.0.0.1:9050 https://check.en.anyone.tech/api/ip -s | cut -d':' -f2 | cut -d',' -f1)"
	ExitCountry="$(curl --socks4 127.0.0.1:9050 -s https://ipinfo.io | grep country | cut -d'"' -f4)"
	echo -e "\nExit IP: $ExitIP\nExit Country: $ExitCountry\nIs Anon: $IsAnon\n"

	function handle_sigint() {
		gsettings set org.gnome.system.proxy mode "auto"
		gsettings reset org.gnome.system.proxy.http host
		gsettings reset org.gnome.system.proxy.http port
		gsettings reset org.gnome.system.proxy.https host
		gsettings reset org.gnome.system.proxy.https port
		gsettings reset org.gnome.system.proxy.socks host
		gsettings reset org.gnome.system.proxy.socks port
		rm anon.zip
		rm anon
		rm anonrc
		exit 0
	}

	trap handle_sigint INT

	while true; do
		echo "Press Cmd+C to quit proxy"
		sleep 600
	done

else
	echo "This script is for Linux"
	exit 1
fi
