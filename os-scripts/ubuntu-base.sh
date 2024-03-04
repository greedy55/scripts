#!/bin/bash

# APT UPDATES && UPGRADE
sudo apt update -y && sudo apt upgrade -y
clear


# SET HOSTNAME
read -p "Enter the new hostname name: " HOST_NAME
echo "$HOST_NAME" | tee /etc/hostname > /dev/null
echo "Verify new hostname"
sleep 1
cat /etc/hostname
sleep 2
clear

# SET STATIC IP
echo "Set a static IP? (y/n)"
read answer

if [ "$answer" == "y" ]; then
  # Get the list of interface names using ip command
  IF_NAMES=$(ip -o link show | awk -F': ' '{print $2}')
  # Display the available interface names
  echo "Available Ethernet interfaces:"
  echo "$IF_NAMES"
  # Prompt to choose an interface and store it in a variable
  read -p "Enter the Ethernet interface name: " INTERFACE
  sleep 1
  read -p "Enter the new IPv4 Address: " STATIC_IPv4
  read -p "Enter the subnet mask: " SUB_MASK
  read -p "Enter the gateway IPv4: " GATEWAY
  read -p "Enter primary nameserver IPv4: " DNS_1 
  read -p "Enter secondary nameserver IPv4: " DNS_2
  NETPLAN="network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $STATIC_IPv4/$SUB_MASK
      routes:
        - to: 0.0.0.0/0
          via: $GATEWAY
      nameservers:
        addresses: [$DNS_1, $DNS_2]"
  echo "$NETPLAN" | tee /etc/netplan/00-installer-config.yaml > /dev/null
  chmod 600 /etc/netplan/00-installer-config.yaml
  sleep 2
  echo "New IPv4 will be applied on reboot"
  clear
else
  echo "Skipping"
  clear
fi

# BASIC SOFTWARE
echo "Setup software now? (y/n)"
read answer

if [ "$answer" == "y" ]; then
  echo "BTOP"
  sudo apt install btop -y
  clear
  
  echo "Midnight Commander"
  sudo apt install mc -y
  clear

  echo "Net-Tools"
  sudo apt install net-tools -y 
  clear 
else
  echo "Skipping"
  clear
fi

# DOCKER ENGINE
echo "Install docker & docker-compose? (y/n)"
read answer

if [ "$answer" == "y" ]; then
  sudo apt update -y && sudo apt upgrade -y
  sudo apt-get install ca-certificates curl gnupg -y
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  clear
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
  clear
  groupadd docker
  usermod -aG docker $USER
  clear
  systemctl enable docker.service
  systemctl enable containerd.service
  clear
else
  echo "Skipping"
  clear
fi

# REBOOT
echo "Reboot? (y/n)"
read answer

if [ "$answer" == "y" ]; then
  sudo netplan apply
  reboot
else
  exit
fi
