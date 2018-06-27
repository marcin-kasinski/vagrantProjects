#!/bin/bash
# set -o xtrace

message=$1

echo "$message\n" >>~/restartinservices.log


echo "All services\n" >>~/restartinservices.log



systemctl list-units devstack@* >>~/restartinservices.log

echo "restarting failed START" >>~/restartinservices.log

systemctl list-units devstack@* | grep failed >>~/restartinservices.log
OUTPUT="$( systemctl --state=failed | grep devstack )"
while read -r line; do   SERVICE="$( echo "$line"  | cut -d " " -f 2)" ; echo "Restarting["$SERVICE"]" >>~/restartinservices.log;        sudo systemctl restart $SERVICE  ; done <<< "$OUTPUT"
echo "restarting failed END"
