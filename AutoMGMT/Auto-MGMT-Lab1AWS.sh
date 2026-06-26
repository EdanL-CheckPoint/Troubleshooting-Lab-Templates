#!/bin/bash

#Log in and get session ID
mgmt_cli login --root true > id.txt

#Change cleanup rule to Any-Any accept
mgmt_cli set access-rule name "Cleanup rule" layer "Network" action "Accept" -s id.txt --format json

#Adding Network objects for Web server and App server subnets
#mgmt_cli add network name "Web-Network" subnet "10.1.1.0" subnet-mask "255.255.255.0" -s id.txt --format json
#mgmt_cli add network name "App-Network" subnet "10.1.2.0" subnet-mask "255.255.255.0" -s id.txt --format json

#Adding web and app servers
mgmt_cli add host name "Web-Server" ip-address "10.1.1.10" -s id.txt --format json
mgmt_cli add host name "App-Server" ip-address "10.1.2.10" -s id.txt --format json

#Adding access rules
mgmt_cli add access-rule layer "Network" position "1" name "Allow Web to App" source.1 "Web-Server" source.2 "App-Server" destination.1 "Web-Server" destination.2 "App-Server" service.1 "SSH" service.2 "icmp-proto" action "Accept" -s id.txt --format json

#Publish
mgmt_cli publish -s id.txt

#Push policy
mgmt_cli install-policy policy-package "Standard" -s id.txt --format json