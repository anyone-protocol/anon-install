#!/bin/bash

if [[ "$(sw_vers --productName)" == "macOS" ]];then


    if [[ ! -f anon-live-macos-$(uname -p)64.zip ]];then
      curl -o anon.zip -fsSLO https://github.com/anyone-protocol/ator-protocol/releases/download/v0.4.9.6/anon-live-macos-$(uname -p)64.zip
    fi
    
    unzip anon.zip anon > /dev/null 2>&1
    
    kill $(pgrep anon) > /dev/null 2>&1
    
    echo -e "SocksPort 127.0.0.1:9050\nSocksPolicy accept 127.0.0.1\nSocksPolicy reject *\nHTTPTunnelPort auto" > anonrc
    
    ./anon -f anonrc &
    
    sleep 1
    
    networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 9050
#    networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 9058
#    networksetup -setwebproxy "Wi-Fi" 127.0.0.1 9058
    
    networksetup -setsocksfirewallproxystate "Wi-Fi" on
#    networksetup -setsecurewebproxystate "Wi-Fi" on
#    networksetup -setwebproxystate "Wi-Fi" on
    
    sleep 1
    
	ExitIP="$(curl -s --socks5 127.0.0.1:9050 https://check.en.anyone.tech/api/ip -s | cut -d'"' -f6)"
	IsAnon="$(curl -s --socks5 127.0.0.1:9050 https://check.en.anyone.tech/api/ip -s | cut -d':' -f2 | cut -d',' -f1)"
	ExitCountry="$(curl --socks4 127.0.0.1:9050 -s https://ipinfo.io | grep country | cut -d'"' -f4)"
    echo -e "\nExit IP: $ExitIP\nExit Country: $ExitCountry\nIs Anon: $IsAnon\n"
    
    function handle_sigint() {
      networksetup -setsocksfirewallproxystate "Wi-Fi" off
 #     networksetup -setsecurewebproxystate "Wi-Fi" off
 #     networksetup -setwebproxystate "Wi-Fi" off
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
  echo "This script is for macOS"
  exit 1
fi
