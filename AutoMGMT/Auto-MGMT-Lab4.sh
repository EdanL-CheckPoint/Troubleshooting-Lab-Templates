#!/bin/bash

#Log in and get session ID
mgmt_cli login --root true > id.txt

#Change cleanup rule to Any-Any accept
mgmt_cli set access-rule name "Cleanup rule" layer "Network" action "Accept" -s id.txt --format json

#Create network objects
mgmt_cli add service-tcp name "TCP8083" port 8083 -s id.txt --format json
mgmt_cli add host name "AzureLab1WebServer" ip-address "172.21.2.4" -s id.txt --format json
mgmt_cli add dynamic-object name "LocalGatewayExternal" -s id.txt --format json

#Add NAT rule
mgmt_cli add nat-rule package "Standard" position "top" original-source "Any" original-destination "LocalGatewayExternal" original-service "TCP8083" translated-service "http" translated-destination "AzureLab1WebServer"  -s id.txt --format json

#Publish
mgmt_cli publish -s id.txt

#Push policy
mgmt_cli install-policy policy-package "Standard" targets "AzureLab1" -s id.txt --format json