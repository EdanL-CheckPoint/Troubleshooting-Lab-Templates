#!/bin/bash

touch automgmt.sh
curl_cli -s "https://raw.githubusercontent.com/EdanL-CheckPoint/Troubleshooting-Lab-Templates/refs/heads/main/AutoMGMT/Auto-MGMT-script.sh" -o "automgmt.sh"
chmod 777 "automgmt.sh"
