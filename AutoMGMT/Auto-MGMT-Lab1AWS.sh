#!/bin/bash

#Log in and get session ID
mgmt_cli login --root true > id.txt

#Change cleanup rule to Any-Any accept
mgmt_cli set access-rule name "Cleanup rule" layer "Network" action "Accept" -s id.txt --format json

#Adding Network objects for Web server and App server subnets
mgmt_cli add network name "Web-Network" subnet "192.168.1.0/24" -s id.txt --format json
mgmt_cli add network name "App-Network" subnet "192.168.2.0/24" -s id.txt --format json

#Publish
mgmt_cli publish -s id.txt

#Push policy
mgmt_cli install-policy policy-package "Standard" -s id.txt --format json