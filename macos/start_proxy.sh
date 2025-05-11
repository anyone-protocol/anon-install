#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE_ANON='\033[0;36m'
NOCOLOR='\033[0m'

if [[ "$(sw_vers --productName)" == "macOS" ]];then

	if [[ ! -f anon-live-macos-$(uname -p)64.zip ]];then
		curl -m 30 -fsSLO https://github.com/anyone-protocol/ator-protocol/releases/latest/download/anon-live-macos-$(uname -p)64.zip
	fi

	function handle_sig() {
		networksetup -setsocksfirewallproxystate "Wi-Fi" off
		
		kill $(pgrep anon) > /dev/null 2>&1		
		rm anon-live-macos-$(uname -p)64.zip anon anonrc
		
		echo -e "\n${BLUE_ANON}======================================================${NOCOLOR}"
		echo -e "${RED}                 ANON Proxy terminated                       ${NOCOLOR}"
		echo -e "${BLUE_ANON}======================================================${NOCOLOR}\n"		
		exit 0
	}
    
	trap handle_sig INT TERM HUP QUIT
	
	echo -e "\n${BLUE_ANON}======================================================${NOCOLOR}"
	echo -e "${GREEN}        Starting ANON Proxy, bootstrapping...               ${NOCOLOR}"
	echo -e "${BLUE_ANON}======================================================${NOCOLOR}\n"
	
	unzip -o anon-live-macos-$(uname -p)64.zip anon > /dev/null 2>&1	
	kill $(pgrep anon) > /dev/null 2>&1	
	echo -e "SocksPort 127.0.0.1:9055\nSocksPolicy accept 127.0.0.1\nSocksPolicy reject *\nHTTPTunnelPort auto" > anonrc	
	./anon -f anonrc --agree-to-terms | grep "Bootstrapped" &	
	sleep 1	
	networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 9055
	networksetup -setsocksfirewallproxystate "Wi-Fi" on	
	sleep 1
	
	CheckAnon=$(curl -s --socks5 127.0.0.1:9055 https://check.en.anyone.tech/api/ip)
	ExitIP="$(echo $CheckAnon | cut -d'"' -f6)"
	IsAnon="$(echo $CheckAnon | cut -d':' -f2 | cut -d',' -f1)"
	ExitCountry="$(curl --socks4 127.0.0.1:9055 -s https://ipinfo.io | grep country | cut -d'"' -f4)"
	
	echo -e "\n${BLUE_ANON}======================================================${NOCOLOR}\n"
	echo -e "Exit IP: $ExitIP"
	echo "Exit Country: $ExitCountry"
	echo "Is Anon: $IsAnon"	
	echo -e "\n${BLUE_ANON}======================================================${NOCOLOR}"
	echo -e "${CYAN}                  ANON Proxy activated                    ${NOCOLOR}"
	echo -e "${BLUE_ANON}======================================================${NOCOLOR}\n"
    
	while true; do
		echo -e "${RED}Press Cmd+C to terminate proxy${NOCOLOR}"
		sleep 1800
	done

else
	echo "This script is for macOS"
	exit 1
fi
