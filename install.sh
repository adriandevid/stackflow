#!/bin/bash
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with administrator/root privileges. Please use sudo:"
    echo "sudo ./install.sh"
    exit 1
fi

STACKFLOW_CURRENT_VERSION="0.0.3"

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'

NC='\e[0m'

echo -e "
Welcome to installer of ${CYAN}StackFlow DevOps Toolkit${NC} v0.0.1."

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

PACKAGES_INSTALLED=true

echo -e "
=> ${CYAN}Stackflow${NC} essential resources
"

if command_exists "node"; then
    echo -e "${GREEN}[x]${NC} node"
else
    echo -e "${RED}[ ]${NC} node"
    PACKAGES_INSTALLED=false
fi

if command_exists "git"; then
    echo -e "${GREEN}[x]${NC} git"
else
    echo -e "${RED}[ ]${NC} git"
    PACKAGES_INSTALLED=false
fi

if command_exists "wget"; then
    echo -e "${GREEN}[x]${NC} wget"
else
    echo -e "${RED}[ ]${NC} wget"
    PACKAGES_INSTALLED=false
fi

if command_exists "kubectl"; then
    echo -e "${GREEN}[x]${NC} kubectl"
else
    echo -e "${RED}[ ]${NC} kubectl"
    PACKAGES_INSTALLED=false
fi

if [ "$PACKAGES_INSTALLED" == false ]
then
    echo "install dependencies for execute this script"
    exit 1
fi

echo ""
echo -e "=> ${CYAN}StackFlow${NC} install packages"
echo "=> => pm2"
echo "=> => => installing pm2..."
npm install pm2@latest -g > /dev/null 2>&1
echo -e "=> => => instaled pm2 \n"

echo "=> => k3d"
echo "=> => => installing k3d..."
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash > /dev/null 2>&1
echo -e "=> => => instaled k3d... \n"

echo -e "=> configuring ${CYAN}Stackflow Web${NC} project"
if [ -e "/opt/stackflow" ]; then
    echo "=> => exist stackflow web"
    echo "=> => => updating stackflow web..."
    cd /opt/stackflow && git pull origin master > /dev/null 2>&1
    echo "=> => => => install dependencies"
    cd /opt/stackflow && npm i > /dev/null 2>&1
    echo "=> => => => instaled dependencies"
    echo -e "=> => => updated stackflow. \n"
else    
    echo "=> => installing stackflow web..."
    git clone https://github.com/adriandevid/stackflow-web.git /opt/stackflow > /dev/null 2>&1

    echo "=> => => install dependencies"
    cd /opt/stackflow 
    npm i --verbose > /dev/null 2>&1
    echo "=> => => instaled dependencies"

    echo -e "=> => instaled stackflow. \n"
fi

echo -e "=> installing ${CYAN}Stackflow Control Plane${NC}..."

if [ -e "/usr/local/bin/stackflow" ]
then 
    rm /usr/local/bin/stackflow
fi
if [ -e "/usr/local/bin/stackflow.sh" ]
then 
    rm /usr/local/bin/stackflow.sh
fi

wget -P /usr/local/bin https://raw.githubusercontent.com/adriandevid/stackflow/refs/tags/$STACKFLOW_CURRENT_VERSION/stackflow.sh > /dev/null 2>&1
cd /usr/local/bin
chmod +x ./stackflow.sh
ln -s ./stackflow.sh stackflow
echo -e "=> instaled ${CYAN}Stackflow${NC}..."