#!/bin/bash

if [[ "$(sw_vers --productName)" == "macOS" ]];then


    if [[ ! -f anon-live-macos-$(uname -p)64.zip ]];then
      curl -m 5 -o anon.zip -fsSLO https://github.com/anyone-protocol/ator-protocol/releases/download/v0.4.9.6/anon-live-macos-$(uname -p)64.zip
    fi

    function handle_sigint() {
      networksetup -setsocksfirewallproxystate "Wi-Fi" off
      rm anon.zip
      rm anon
      rm anonrc
      exit 0
    }
    
    trap handle_sigint INT
    
    unzip anon.zip anon > /dev/null 2>&1
    
    kill $(pgrep anon) > /dev/null 2>&1
    
    echo -e "SocksPort 127.0.0.1:9050\nSocksPolicy accept 127.0.0.1\nSocksPolicy reject *\nHTTPTunnelPort 9058" > anonrc
    
    ./anon -f anonrc --agree-to-terms &
    
    sleep 1
    
    networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 9050
    networksetup -setsocksfirewallproxystate "Wi-Fi" on
    
    sleep 1
    
    CheckAnon=$(curl -s --socks5 127.0.0.1:9050 https://check.en.anyone.tech/api/ip)
	ExitIP="$(echo $CheckAnon | cut -d'"' -f6)"
	IsAnon="$(echo $CheckAnon | cut -d':' -f2 | cut -d',' -f1)"
	ExitCountry="$(curl --socks4 127.0.0.1:9050 -s https://ipinfo.io | grep country | cut -d'"' -f4)"
    echo -e "\nExit IP: $ExitIP\nExit Country: $ExitCountry\nIs Anon: $IsAnon"
    
    while true; do
      echo -e "\nPress Cmd+C to quit proxy"
      sleep 120
    done

else
  echo "This script is for macOS"
  exit 1
fi
