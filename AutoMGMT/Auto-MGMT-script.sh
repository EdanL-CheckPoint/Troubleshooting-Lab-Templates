#!/bin/bash

#Fill in the machine IPs below
CLUSTERIP="51.58.32.150"
MEMBER1="51.58.32.163"
MEMBER2="20.217.180.241"
WEBSERVER="172.18.2.4"

#Log in and get session ID
mgmt_cli login --root true > id.txt

#Change cleanup rule to Any-Any accept
mgmt_cli set access-rule name "Cleanup rule" layer "Network" action "Accept" -s id.txt --format json

#Create Cluster
mgmt_cli add simple-cluster name "AzureLab1" version "R82" ip-address "$CLUSTERIP" cluster-mode "cluster-xl-ha" firewall true vpn false members.1.name "AzureLab1gw1" members.1.one-time-password "Checkpoint123" members.1.ip-address "$MEMBER1" members.2.name "AzureLab1gw2" members.2.one-time-password "Checkpoint123" members.2.ip-address "$MEMBER2" -s id.txt --format json

#Get topology
mgmt_cli get-interfaces target-name "AzureLab1" with-topology true -s id.txt --format json

#Interfaces - Fetch eth0 VIP
mgmt_cli show simple-cluster name "AzureLab1"  -s id.txt --format json -r true | jq -r '.["cluster-members"][] | .interfaces[] | select(.name=="eth0") | .["ipv4-address"]' > eth0ip1.txt
awk -F. '{ $4=$4+1; print $1"."$2"."$3"."$4 }' eth0ip1.txt > eth0vip.txt
ETH0_VIP=$(sed -n '2p' eth0vip.txt)

#Interfaces - Set topology
mgmt_cli set simple-cluster name "AzureLab1" interfaces.update.name "eth0" interfaces.update.ip-address "$ETH0_VIP" interfaces.update.network-mask "255.255.255.0" interfaces.update.interface-type "cluster" interfaces.update.topology "External" interfaces.update.anti-spoofing false -s id.txt  --format json
mgmt_cli set simple-cluster name "AzureLab1" interfaces.update.name "eth1" interfaces.update.interface-type "Sync" interfaces.update.anti-spoofing false -s id.txt  --format json

#Create network objects
mgmt_cli add service-tcp name "TCP8083" port 8083 -s id.txt --format json
mgmt_cli add host name "AzureLab1WebServer" ip-address "$WEBSERVER" -s id.txt --format json
mgmt_cli add dynamic-object name "LocalGatewayExternal" -s id.txt --format json

#Add NAT rule
mgmt_cli add nat-rule package "Standard" position "top" original-source "Any" original-destination "LocalGatewayExternal" original-service "TCP8083" translated-service "http" translated-destination "AzureLab1WebServer"  -s id.txt --format json

#Publish
mgmt_cli publish -s id.txt

#Push policy
mgmt_cli install-policy policy-package "Standard" targets "AzureLab1" -s id.txt --format json