#!/bin/bash

RED='\033[0;31m'
NOCOLOR='\033[0m'

. /etc/os-release

if ! command -v sudo &>/dev/null; then
    echo "Error: sudo command not found. Please make sure that you run the installation command with sudo bin/bash .."
    exit 1
fi

sudo wget -qO- https://deb.dmz.ator.dev/anon.asc | sudo tee /etc/apt/trusted.gpg.d/anon.asc

sudo echo "deb [signed-by=/etc/apt/trusted.gpg.d/anon.asc] https://deb.dmz.ator.dev anon-live-$VERSION_CODENAME main" | sudo tee /etc/apt/sources.list.d/anon.list

sudo apt-get update --yes

sudo apt-get install anon --yes

if [ $? -ne 0 ]; then
    echo -e "${RED}\nFailed to install the Anon package. Quitting installation. Ensure $PRETTY_NAME $VERSION_CODENAME is supported.\n${NOCOLOR}"
    exit 1
fi

sudo mv /etc/anon/anonrc /etc/anon/anonrc.bak

read -p "Enter your desired nickname for the Anon Relay (1-19 characters, only [a-zA-Z0-9] and no spaces): " NICKNAME
while ! [[ "$NICKNAME" =~ ^[a-zA-Z0-9]{1,19}$ ]]; do
    echo "Error: Invalid nickname format. Please enter 1-19 characters, only [a-zA-Z0-9] and no spaces."
    read -p "Enter your desired nickname for the Anon Relay (1-19 characters, only [a-zA-Z0-9] and no spaces): " NICKNAME
done

read -p "Enter your contact information for the Anon Relay: " CONTACT_INFO

read -p "Do you want to link your Ethereum wallet address now? (yes/no): " HAS_ETH_WALLET
if [[ "$HAS_ETH_WALLET" =~ ^[Yy][Ee][Ss]$ ]]; then
    while true; do
        read -p "Enter your Ethereum wallet address: " ETH_WALLET
        if [[ "$ETH_WALLET" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
            CONTACT_INFO="$CONTACT_INFO @anon: $ETH_WALLET"
            break
        else
            echo "Error: Invalid Ethereum wallet address format. Must start with '0x' followed by 40 hexadecimal characters."
        fi
    done
fi

read -p "Enter comma-separated fingerprints for your relay's family (leave empty to skip): " MY_FAMILY

while [[ -n "$MY_FAMILY" && ! "$MY_FAMILY" =~ ^([A-Z0-9]+,)*[A-Z0-9]+$ ]]; do
    echo "Error: Invalid MyFamily format. Please enter comma-separated fingerprints with only capital letters."
    read -p "Enter comma-separated fingerprints for your relay's family (leave empty to skip): " MY_FAMILY
done

read -p "Enter BandwidthRate in Mbit (leave empty to skip): " BANDWIDTH_RATE
read -p "Enter BandwidthBurst in Mbit (leave empty to skip): " BANDWIDTH_BURST

while true; do
        read -rp "Enter ORPOrt [Default: 9001]: " OR_PORT
        OR_PORT="${OR_PORT:-9001}"  # Set a default value if no input is provided
        if [[ $OR_PORT =~ ^[0-9]+$ ]]; then
                break  # Break out of the loop if input consists only of numbers
        else
                echo "Error: Invalid ORPort format. Must contain only numbers." >&2
        fi
done

read -p "If your Anon Relay does not use IPv6, you can disable it. Do you want to disable IPv6? (yes/no): " DISABLE_IPV6
while ! [[ "$DISABLE_IPV6" =~ ^(yes|no)$ ]]; do
    echo "Error: Invalid choice. Please enter 'yes' or 'no'."
    read -p "If your Anon Relay does not use IPv6, you can disable it. Do you want to disable IPv6? (yes/no): " DISABLE_IPV6
done

# Writing the configuration file
cat <<EOF | sudo tee /etc/anon/anonrc >/dev/null
Log notice file /var/log/anon/notices.log
ORPort $OR_PORT $( [[ "$DISABLE_IPV6" == "yes" ]] && echo "IPv4Only")
$( [[ "$DISABLE_IPV6" == "yes" ]] && echo "AddressDisableIPv6")
ControlPort 9051
SocksPort 0
ExitRelay 0
IPv6Exit 0
ExitPolicy reject *:*
ExitPolicy reject6 *:*

$( [[ -n "$BANDWIDTH_RATE" ]] && echo "BandwidthRate $BANDWIDTH_RATE Mbit" )
$( [[ -n "$BANDWIDTH_BURST" ]] && echo "BandwidthBurst $BANDWIDTH_BURST Mbit" )
Nickname $NICKNAME
ContactInfo $CONTACT_INFO
EOF

if [[ -n "$MY_FAMILY" ]]; then
    echo "MyFamily $MY_FAMILY" | sudo tee -a /etc/anon/anonrc >/dev/null
fi

sudo systemctl restart anon.service

echo "Anon installation completed successfully."
