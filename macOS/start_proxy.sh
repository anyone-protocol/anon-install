#!/bin/bash

if [[ "$(sw_vers --productName)" != "macOS" ]];then
  echo "This script is for macOS"
  exit 1
fi

if [[ ! -f anon-live-macos-$(uname -p)64.zip ]];then
  wget -q https://github.com/anyone-protocol/ator-protocol/releases/download/v0.4.9.6/anon-live-macos-$(uname -p)64.zip
fi

unzip -o  anon-live-macos-$(uname -p)64.zip anon > /dev/null 2>&1

kill $(pgrep anon) > /dev/null 2>&1

cat << EOF > anonrc
SocksPort 127.0.0.1:9050
SocksPolicy accept 127.0.0.1
SocksPolicy reject *
HTTPTunnelPort 9058
EOF

./anon -f anonrc &

sleep 1

networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 9050
networksetup -setsecurewebproxy "Wi-Fi" 127.0.0.1 9058
networksetup -setwebproxy "Wi-Fi" 127.0.0.1 9050

networksetup -setsocksfirewallproxystate "Wi-Fi" on
networksetup -setsecurewebproxystate "Wi-Fi" on
networksetup -setwebproxystate "Wi-Fi" on

sleep 1

ExitIP="$(curl -s --socks5 127.0.0.1:9050 https://check.en.anyone.tech/api/ip -s | jq .IP | cut -d'"' -f2)"
IsAnon="$(curl -s --socks5 127.0.0.1:9050 https://check.en.anyone.tech/api/ip -s | jq .IsAnon)"
ExitCountry="$(whois $ExitIP | grep -m1 country | awk '{print $2}')"
echo -e "\nExit IP: $ExitIP\nExit Country: $ExitCountry\nIs Anon: $IsAnon\n"

function handle_sigint() {
  networksetup -setsocksfirewallproxystate "Wi-Fi" off
  networksetup -setsecurewebproxystate "Wi-Fi" off
  networksetup -setsecurewebproxystate "Wi-Fi" off
  networksetup -setwebproxystate "Wi-Fi" off
  rm anon-live-macos-$(uname -p)64.zip
  rm anon
  rm anonrc
  exit 0
}

trap handle_sigint INT

while true; do
  echo "Press Cmd+C to quit"
  sleep 18000
done
