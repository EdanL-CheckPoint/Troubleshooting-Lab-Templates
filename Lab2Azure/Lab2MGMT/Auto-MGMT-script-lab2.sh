#!/bin/bash

# Function to read and validate an IP address
read_ip() {
  local ip
  while true; do
    read -p "$1: " ip

    # Strict IPv4 validation (0-255 per octet)
    if [[ $ip =~ ^((25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})\.){3}(25[0-5]|2[0-4][0-9]|1?[0-9]{1,2})$ ]]; then
      echo "$ip"
      return
    else
      echo "Invalid IP address. Please enter a valid IPv4 (e.g., 192.168.1.1)"
    fi
  done
}

# Prompt user for Gaia version and 4 IPs
read -rp "Enter the Gaia version: " GVERSION
CLUSTERIP=$(read_ip "Enter cluster VIP")
MEMBER1=$(read_ip "Enter member 1 eth0 IP")
MEMBER2=$(read_ip "Enter member 2 eth0 IP")
WEBSERVER=$(read_ip "Enter Web server IP")

# Example usage later in the script
echo ""
echo "Valid IPs entered:"
echo "Cluser IP: $CLUSTERIP"
echo "Member 1 IP: $MEMBER1"
echo "Member 2 IP: $MEMBER2"
echo "Web Server IP: $WEBSERVER"


# Confirmation prompt
while true; do
  read -p "Are these correct? (y/n): " confirm
  case $confirm in
    [Yy])
      echo "Confirmed. Continuing..."
      break
      ;;
    [Nn])
      echo "Cancelled by user."
      exit 1
      ;;
    *)
      echo "Please enter 'y' for yes or 'n' for no."
      ;;
  esac
done

# ===== Continue with your script here =====
echo "Running operations with provided IPs..."

#Fill in the machine IPs below
#CLUSTERIP="51.58.32.150"
#MEMBER1="51.58.32.163"
#MEMBER2="20.217.180.241"
#WEBSERVER="172.18.2.4"

#Log in and get session ID
mgmt_cli login --root true > id.txt

#Change cleanup rule to Any-Any accept
mgmt_cli set access-rule name "Cleanup rule" layer "Network" action "Accept" -s id.txt --format json

#Create Cluster
mgmt_cli add simple-cluster name "AzureLab2" version "$GVERSION" ip-address "$CLUSTERIP" cluster-mode "cluster-xl-ha" firewall true vpn false members.1.name "AzureLab2gw1" members.1.one-time-password "Checkpoint123" members.1.ip-address "$MEMBER1" members.2.name "AzureLab2gw2" members.2.one-time-password "Checkpoint123" members.2.ip-address "$MEMBER2" -s id.txt --format json

#Get topology
mgmt_cli get-interfaces target-name "AzureLab2" with-topology true -s id.txt --format json

#Interfaces - Fetch eth0 VIP
mgmt_cli show simple-cluster name "AzureLab2"  -s id.txt --format json -r true | jq -r '.["cluster-members"][] | .interfaces[] | select(.name=="eth0") | .["ipv4-address"]' > eth0ip1.txt
awk -F. '{ $4=$4+1; print $1"."$2"."$3"."$4 }' eth0ip1.txt > eth0vip.txt
ETH0_VIP=$(sed -n '2p' eth0vip.txt)

#Interfaces - Set topology
mgmt_cli set simple-cluster name "AzureLab2" interfaces.update.name "eth0" interfaces.update.ip-address "$ETH0_VIP" interfaces.update.network-mask "255.255.255.0" interfaces.update.interface-type "cluster" interfaces.update.topology "External" interfaces.update.anti-spoofing false -s id.txt  --format json
mgmt_cli set simple-cluster name "AzureLab2" interfaces.update.name "eth1" interfaces.update.interface-type "Sync" interfaces.update.anti-spoofing false -s id.txt  --format json

#Create network objects
mgmt_cli add service-tcp name "TCP8083" port 8083 -s id.txt --format json
mgmt_cli add host name "AzureLab2WebServer" ip-address "$WEBSERVER" -s id.txt --format json
mgmt_cli add dynamic-object name "LocalGatewayExternal" -s id.txt --format json

#Add NAT rule
mgmt_cli add nat-rule package "Standard" position "top" original-source "Any" original-destination "LocalGatewayExternal" original-service "TCP8083" translated-service "http" translated-destination "AzureLab2WebServer"  -s id.txt --format json

#Publish
mgmt_cli publish -s id.txt

#Push policy
mgmt_cli install-policy policy-package "Standard" targets "AzureLab2" -s id.txt --format json