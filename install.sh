#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BLUE_ANON='\033[38;2;2;128;175m'
NOCOLOR='\033[0m'

. /etc/os-release

if ! command -v sudo &>/dev/null; then
    echo -e "${RED}\nError: sudo command not found. Please make sure that you run the installation command with sudo.${NOCOLOR}"
    exit 1
fi

echo -e "${BLUE_ANON}==================================================${NOCOLOR}"
echo -e "${GREEN}           Starting ANON Installation             ${NOCOLOR}"
echo -e "${BLUE_ANON}==================================================${NOCOLOR}"

wget -qO- https://deb.en.anyone.tech/anon.asc | sudo tee /etc/apt/trusted.gpg.d/anon.asc
echo "deb [signed-by=/etc/apt/trusted.gpg.d/anon.asc] https://deb.en.anyone.tech anon-live-$VERSION_CODENAME main" | sudo tee /etc/apt/sources.list.d/anon.list
sudo apt-get update --yes
sudo apt-get install anon --yes

if [ $? -ne 0 ]; then
    echo -e "${RED}\nFailed to install the Anon package. Quitting installation. Ensure $PRETTY_NAME $VERSION_CODENAME is supported.\n${NOCOLOR}"
    exit 1
fi

echo -e "${BLUE_ANON}==================================================${NOCOLOR}"
echo -e "${GREEN}           ANON Installation Complete             ${NOCOLOR}"
echo -e "${BLUE_ANON}==================================================${NOCOLOR}"

sudo cp /etc/anon/anonrc /etc/anon/anonrc.bak

echo -e "${BLUE_ANON}"
cat << "EOF"

                                                                 /$$
                                                                |__/
  /$$$$$$  /$$$$$$$  /$$   /$$  /$$$$$$  /$$$$$$$   /$$$$$$      /$$  /$$$$$$
 |____  $$| $$__  $$| $$  | $$ /$$__  $$| $$__  $$ /$$__  $$    | $$ /$$__  $$
  /$$$$$$$| $$  \ $$| $$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$    | $$| $$  \ $$
 /$$__  $$| $$  | $$| $$  | $$| $$  | $$| $$  | $$| $$_____/    | $$| $$  | $$
|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$/| $$  | $$|  $$$$$$$ /$$| $$|  $$$$$$/
 \_______/|__/  |__/ \____  $$ \______/ |__/  |__/ \_______/|__/|__/ \______/
                     /$$  | $$
                    |  $$$$$$/
                     \______/

EOF

echo -e "${BLUE_ANON}\n==================================================${NOCOLOR}"
echo -e "${GREEN}        Start Relay Configuration Wizard          ${NOCOLOR}"
echo -e "${CYAN}  (Or abort and manually edit /etc/anon/anonrc)   ${NOCOLOR}"
echo -e "${BLUE_ANON}==================================================${NOCOLOR}"

echo -e "${CYAN}\n- Enter the desired Nickname and Contact information for your Anon Relay${NOCOLOR}"
read -p "1/7 Nickname (1-19 characters, only [a-zA-Z0-9] and no spaces): " NICKNAME
while ! [[ "$NICKNAME" =~ ^[a-zA-Z0-9]{1,19}$ ]]; do
    echo -e "${RED}\nError: Invalid nickname format. Please enter 1-19 characters, only [a-zA-Z0-9] and no spaces.${NOCOLOR}\n"
	read -p "1/7 Nickname (1-19 characters, only [a-zA-Z0-9] and no spaces): " NICKNAME
done

read -p "1/7 Contact Information (leave empty to skip): " CONTACT_INFO

echo -e "${CYAN}\n- Enter a comma-separated list of fingerprints for your relay's family${NOCOLOR}"
read -p "2/7 MyFamily fingerprints (leave empty to skip): " MY_FAMILY
while [[ -n "$MY_FAMILY" && ! "$MY_FAMILY" =~ ^([A-F0-9]{40})(,[A-F0-9]{40})*$ ]]; do
    echo -e "${RED}\nError: Please enter comma-separated fingerprints, each 40 characters long, with only capital letters A-F and numbers 0-9.${NOCOLOR}\n"
    read -p "2/7 MyFamily fingerprints (leave empty to skip): " MY_FAMILY
done

MAX_BANDWIDTH=100000

while true; do
    echo -e "${CYAN}\n- Enter BandwidthRate and BandwidthBurst in Mbit (e.g., 100 for 100 Mbit)${NOCOLOR}"
    read -p "3/7 BandwidthRate (leave empty to skip): " BANDWIDTH_RATE
    read -p "3/7 BandwidthBurst (leave empty to skip): " BANDWIDTH_BURST
    if [[ -z "$BANDWIDTH_RATE" && -z "$BANDWIDTH_BURST" ]]; then
        break
    fi
    if [[ "$BANDWIDTH_RATE" =~ ^[0-9]+$ ]] && [[ "$BANDWIDTH_BURST" =~ ^[0-9]+$ ]]; then
        if [ "$BANDWIDTH_RATE" -le "$MAX_BANDWIDTH" ] && [ "$BANDWIDTH_BURST" -le "$MAX_BANDWIDTH" ]; then
            if [ "$BANDWIDTH_BURST" -ge "$BANDWIDTH_RATE" ]; then
                break
            else
                echo -e "${RED}\nError: BandwidthBurst must be greater than or equal to BandwidthRate.${NOCOLOR}"
            fi
        else
            echo -e "${RED}\nError: Bandwidth values must be between 1 and $MAX_BANDWIDTH Mbit.${NOCOLOR}"
        fi
    else
        echo -e "${RED}\nError: Please enter valid numeric values for both BandwidthRate and BandwidthBurst.${NOCOLOR}"
    fi
done

while true; do
    echo -e "${CYAN}\n- Enter ORPort${NOCOLOR}"
    read -rp "4/7 ORPort [Default: 9001]: " OR_PORT
    OR_PORT="${OR_PORT:-9001}"
    if [[ "$OR_PORT" =~ ^[0-9]+$ ]] && [ "$OR_PORT" -ge 1 ] && [ "$OR_PORT" -le 65535 ]; then
        echo -e "${GREEN}ORPort set to: $OR_PORT${NOCOLOR}"
        break
    else
        echo -e "${RED}\nError: Invalid ORPort. It must be a number between 1 and 65535.${NOCOLOR}"
		echo -e "${RED}Keep in mind that not all ports in this range will work out of the box.${NOCOLOR}"
    fi
done

echo -e "${BLUE_ANON}\n==================================================${NOCOLOR}"
echo -e "${CYAN}         Ethereum Wallet Configuration                 ${NOCOLOR}"
echo -e "${BLUE_ANON}==================================================${NOCOLOR}"

while true; do
    echo -e "${CYAN}\n- Do you want to enter an Ethereum EVM address for contribution rewards?${NOCOLOR}"
    read -p "5/7 Ethereum Address (yes/no): " HAS_ETH_WALLET
    case "$HAS_ETH_WALLET" in
        [Yy][Ee][Ss])
            while true; do
                read -p "5/7 Enter your Ethereum wallet address: " ETH_WALLET
                if [[ "$ETH_WALLET" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
                    CONTACT_INFO="$CONTACT_INFO @anon: $ETH_WALLET"
                    break
                else
                    echo -e "${RED}\nError: Invalid Ethereum wallet address format. Must start with '0x' followed by 40 hexadecimal characters.${NOCOLOR}"
                fi
            done
            break
            ;;
        [Nn][Oo])
            break
            ;;
        *)
            echo -e "${RED}\nError: Please respond with 'yes' or 'no'.${NOCOLOR}"
            ;;
    esac
done

echo -e "${BLUE_ANON}\n==================================================${NOCOLOR}"
echo -e "${CYAN}       Enable Monitoring and Control port         ${NOCOLOR}"
echo -e "${BLUE_ANON}==================================================${NOCOLOR}"

while true; do
    echo -e "${CYAN}\n- Should the anon.service ControlPort be enabled?${NOCOLOR}"
    read -rp "6/7 Enable ControlPort? [Default: no]: " ENABLE_CONTROL_PORT
    ENABLE_CONTROL_PORT="${ENABLE_CONTROL_PORT:-no}"
    if [[ "$ENABLE_CONTROL_PORT" =~ ^[Yy][Ee][Ss]$ ]]; then
        CONTROL_PORT="9051"
        break
    elif [[ "$ENABLE_CONTROL_PORT" =~ ^[Nn][Oo]$ ]]; then
        CONTROL_PORT=""
        break
    else
        echo -e "${RED}\nError: Please respond with 'yes' or 'no'.${NOCOLOR}"
    fi
done


echo -e "${BLUE_ANON}\n==================================================${NOCOLOR}"
echo -e "${CYAN}      Optional Local Firewall Installation        ${NOCOLOR}"
echo -e "${BLUE_ANON}==================================================${NOCOLOR}"

echo -e "${CYAN}\nThe default firewall configuration tool for Ubuntu is ufw. \nDeveloped to ease iptables firewall configuration, ufw provides\na user friendly way to create an IPv4 or IPv6 host-based firewall. \nBy default UFW is disabled. \n"
echo -e "${CYAN}https://help.ubuntu.com/community/UFW\n"

SSH_PORT=$(grep -E '^[^#]*Port ' /etc/ssh/sshd_config | awk '{print $2}' | head -n 1)
if [ -z "$SSH_PORT" ]; then
    SSH_PORT=22
fi

while true; do
    echo -e "${CYAN}\n- Would you like to install UncomplicatedFirewall and allow incoming traffic on: \n- ORPort ${NOCOLOR}$OR_PORT ${CYAN} \n- SSH port ${NOCOLOR}$SSH_PORT${CYAN}\n${NOCOLOR}"
    read -rp "7/7 Configure and enable ufw (yes/no): " INSTALL_UFW
    case "$INSTALL_UFW" in
        [Yy][Ee][Ss])
            sudo apt-get install ufw --yes
            sudo ufw allow "$OR_PORT"
            sudo ufw allow "$SSH_PORT"
            sudo ufw enable
			
			echo -e "${BLUE_ANON}\n==================================================${NOCOLOR}"
            echo -e "${GREEN}UFW installed and rules added for ORPort ${NOCOLOR}$OR_PORT ${GREEN}and SSH port ${NOCOLOR}$SSH_PORT${GREEN}.${NOCOLOR}"
			echo -e "${CYAN}\nMake sure old firewall rules are removed if they are no longer valid.${NOCOLOR}"
			echo -e "${CYAN}To show current UFW configuration:${NOCOLOR} ${GREEN}sudo ufw status${NOCOLOR}"
			echo -e "${CYAN}To remove an old rule:${NOCOLOR} ${GREEN}sudo ufw delete allow <port-number>${NOCOLOR}"
            break
            ;;
        [Nn][Oo])
			echo -e "${BLUE_ANON}\n==================================================${NOCOLOR}"
            echo -e "${GREEN}Skipping UFW installation.${NOCOLOR}"
            break
            ;;
        *)
            echo -e "${RED}\nError: Please respond with 'yes' or 'no'.${NOCOLOR}"
            ;;
    esac
done

echo -e "${CYAN}\nFor improved security, consider setting up SSH key authentication.${NOCOLOR}"
echo -e "${CYAN}Refer to official documentation: https://ssh.com/ssh/keygen for instructions.${NOCOLOR}\n"

sudo rm -f /etc/anon/anonrc

cat <<EOF | sudo tee /etc/anon/anonrc >/dev/null
Nickname $NICKNAME
ContactInfo $CONTACT_INFO
Log notice file /var/log/anon/notices.log
ORPort $OR_PORT
ControlPort ${CONTROL_PORT:-0}
SocksPort 0
ExitRelay 0
IPv6Exit 0
ExitPolicy reject *:*
ExitPolicy reject6 *:*
$( [[ -n "$BANDWIDTH_RATE" ]] && echo "BandwidthRate $BANDWIDTH_RATE Mbit" )
$( [[ -n "$BANDWIDTH_BURST" ]] && echo "BandwidthBurst $BANDWIDTH_BURST Mbit" )
EOF

if [[ -n "$MY_FAMILY" ]]; then
    echo "MyFamily $MY_FAMILY" | sudo tee -a /etc/anon/anonrc >/dev/null
fi

FINGERPRINT_FILE="/var/lib/anon/fingerprint"

function show_fingerprint {
    if sudo test -f "$FINGERPRINT_FILE"; then
        fingerprint=$(sudo awk '{print $2}' "$FINGERPRINT_FILE")
        
        echo -e "${BLUE_ANON}==================================================${NOCOLOR}"
        echo -e "${GREEN}              Anon Relay Fingerprint                ${NOCOLOR}"
        echo -e "${GREEN}     ${NOCOLOR}$fingerprint"
        echo -e "${BLUE_ANON}==================================================${NOCOLOR}\n"
    else
        echo -e "${RED}\nError: Fingerprint file not found at $FINGERPRINT_FILE.${NOCOLOR}"
        echo "Please make sure the service is properly configured and running."
    fi
}

sudo systemctl restart anon.service

start_time=$(date +%s)
if ! sudo test -f "$FINGERPRINT_FILE"; then
    echo -e "${CYAN}Waiting for the fingerprint to be generated.${NOCOLOR}"
    echo -e "${CYAN}Please don't interrupt the process...${NOCOLOR}\n"
    
    while ! sudo test -f "$FINGERPRINT_FILE"; do
        sleep 2
        current_time=$(date +%s)
        elapsed_time=$(( current_time - start_time ))
        
        if [ "$elapsed_time" -ge "35" ]; then
            echo -e "${RED}\nError: Timeout waiting for the fingerprint to be generated.${NOCOLOR}"
            echo "Please check the service or configuration."
            exit 1
        fi
    done
fi

show_fingerprint



cat /etc/anon/anonrc

echo -e "${GREEN}\n==================================================${NOCOLOR}"
echo -e "${BLUE_ANON}               Congratulations!                   ${NOCOLOR}"
echo -e "${GREEN}   Anon configuration completed successfully.     ${NOCOLOR}"
echo -e "${BLUE_ANON}            https://docs.anyone.io              ${NOCOLOR}"
echo -e "${GREEN}==================================================${NOCOLOR}"
