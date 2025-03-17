#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to display spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf "${CYAN} [%c]  ${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Function to run command with progress
run_command() {
    local cmd="$1"
    local msg="$2"
    printf "${YELLOW}%-50s${NC}" "$msg..."
    eval "$cmd" > /dev/null 2>&1 &
    spinner $!
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Done${NC}"
    else
        echo -e "${RED}Failed${NC}"
        exit 1
    fi
}

# Print banner
print_banner() {
	echo -e "${BLUE}${BOLD}"
	echo ""
	echo "                  --- NodeJS MongoDB Ubuntu 24.04 ---"
  echo ""
	echo -e "${NC}"
}

# Check for root access
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Check Ubuntu version
if [ "$(lsb_release -cs)" != "noble" ]; then
    echo -e "${RED}This script only supports Ubuntu 24.04 (Noble)${NC}"
    exit 1
fi

# Print banner
print_banner

# Main installation process
total_steps=25
current_step=0

echo -e "\n${MAGENTA}${BOLD}Starting NodeJS and MongoDB Installation Process${NC}\n"

run_command "apt-get update -y" "Updating system ($(( ++current_step ))/$total_steps)"

run_command "sed -i 's/#\$nrconf{restart} = '"'"'i'"'"';/\$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf" "Configuring needrestart ($(( ++current_step ))/$total_steps)"

run_command "apt install -y nodejs" "Installing NodeJS ($(( ++current_step ))/$total_steps)"

run_command "apt install -y npm" "Installing NPM ($(( ++current_step ))/$total_steps)"

run_command "wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb && dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb" "Installing libssl ($(( ++current_step ))/$total_steps)"

run_command "curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor" "Adding MongoDB key ($(( ++current_step ))/$total_steps)"

run_command "echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list"Adding MongoDB repository ($(( ++current_step ))/$total_steps)"

run_command "apt-get update -y" "Updating package list ($(( ++current_step ))/$total_steps)"

run_command "apt-get install mongodb-org -y" "Installing MongoDB ($(( ++current_step ))/$total_steps)"

run_command "apt-get upgrade -y" "Upgrading system ($(( ++current_step ))/$total_steps)"

run_command "systemctl start mongod" "Starting MongoDB service ($(( ++current_step ))/$total_steps)"

run_command "systemctl enable mongod" "Enabling MongoDB service ($(( ++current_step ))/$total_steps)"

# Check services status
echo -e "\n${MAGENTA}${BOLD}Checking services status:${NC}"
for service in mongod; do
    status=$(systemctl is-active $service)
    if [ "$status" = "active" ]; then
        echo -e "${GREEN}✔ $service is running${NC}"
    else
        echo -e "${RED}✘ $service is not running${NC}"
    fi
done

echo -e "\n${GREEN}${BOLD}Script execution completed successfully!${NC}"
