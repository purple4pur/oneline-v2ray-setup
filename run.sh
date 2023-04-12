#!/usr/bin/env bash

# ===================================================================
#   Install and setup v2ray service with one command (for VPS)
# ===================================================================


help_menu() {
    echo "  Usage:"
    echo "      $0            # Install/Update v2ray with default port (10727)"
    echo "      $0 -p 10727   # Install/Update v2ray with custom port"
    echo "      $0 -v         # Summarize current config.json"
    echo "      $0 -u         # Install/update v2ray only"
    echo "      $0 -h         # Get this help menu"
}

set_port() {
    if [[ "$1" -ge 1024 && "$1" -le 65535 ]]; then
        port=$1
    else
        echo "Invalid port number. (1024-65535)"
        exit 1
    fi
}

check_and_install_jq() {
    if ! command -v jq > /dev/null 2>&1; then
        echo "================================================================"
        echo "                          Install jq"
        echo "================================================================"
        apt update
        apt install jq -y
    fi
}

check_root() {
    if ! sudo -nv > /dev/null 2>&1; then
        echo "Root privileges are required. Please re-run with sudo."
        exit 1
    fi
}

is_v2ray_installed() {
    if command -v v2ray > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

install_v2ray() {
    echo "================================================================"
    echo "                     Install/Update v2ray"
    echo "================================================================"
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
    if ! is_v2ray_installed; then
        echo "Failed to install 'v2ray'."
        exit 1
    fi
}

summary() {
    echo "  * Config file: $config_file"
    echo "  *   Server IP: $ip"
    echo "  *        Port: $port"
    echo "  *        UUID: $uuid"
}

write_config_file() {
    echo "================================================================"
    echo "                       Write config.json"
    echo "================================================================"
    if [[ -e $config_file ]]; then
        check_and_install_jq
        uuid=$(jq .inbounds[0].settings.clients[0].id $config_file | sed 's/"//g')
        mv $config_file ${config_file}.bak
        echo "Current config.json is backed up: ${config_file}.bak"
    else
        uuid=$(v2ray uuid)
    fi
    cat > $config_file << EOF
{
  "inbounds": [{
    "port": $port,
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "$uuid"
        }
      ]
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
EOF
    summary
}

allow_port() {
    echo "================================================================"
    echo "                          Allow port"
    echo "================================================================"
    echo "Allow $port/tcp..."
    ufw allow $port/tcp
    echo "You may disable previous allowed ports."
}

start_v2ray() {
    echo "================================================================"
    echo "                          Start v2ray"
    echo "================================================================"
    systemctl enable v2ray
    systemctl restart v2ray
    systemctl status v2ray
}

read_from_config() {
    if [[ -e $config_file ]]; then
        check_and_install_jq
        port=$(jq .inbounds[0].port $config_file)
        uuid=$(jq .inbounds[0].settings.clients[0].id $config_file | sed 's/"//g')
    else
        echo "$config_file is not found."
        exit 1
    fi
}


config_file=/usr/local/etc/v2ray/config.json
ip=$(dig -4 +short myip.opendns.com @resolver1.opendns.com)
port=10727

while [[ $# -ne 0 ]]; do
    case $1 in
        -h | --help)
            help_menu
            exit
            ;;
        -p | --port)
            shift
            set_port "$1"
            ;;
        -v | --status)
            read_from_config
            summary
            exit
            ;;
        -u | --update)
            install_v2ray
            exit
            ;;
        *)
            echo "Unrecognized token: $1"
            exit 1
            ;;
    esac
    shift
done

check_root
if is_v2ray_installed; then
    echo "'v2ray' is installed. Update v2ray with '$0 -u'"
else
    install_v2ray
fi

write_config_file
allow_port
start_v2ray
