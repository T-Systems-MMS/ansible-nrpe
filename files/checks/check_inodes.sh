#!/bin/bash
###################################
### MANAGED BY PUPPET ['nrpe'] ###
### DON'T CHANGE THIS FILE HERE ###
### DO IT ON THE PUPPET MASTER! ###
###################################
DF=$(df -Pkih | tail -n+2 |awk {' print $5 '}|cut -f1 -d'%' | tr -d "-")

DF_STRING=$(df -Pkih | tail -n+2 | grep "%"| awk {' print $6 ": " $5 '})

OUTPUT=$(echo -e "${DF_STRING}" | sed ':a;N;$!ba;s/\n/ --- /g')
MAX=0

for ENTRY in ${DF[*]}; do
        if [ "${ENTRY}" != "-" ]; then
                if [ ${ENTRY} -gt ${MAX} ]; then
                        MAX=${ENTRY}
                fi
        fi
done

if [ ${MAX} -lt 80 ]; then
        echo -n "OK - "
        echo "${OUTPUT}"
        exit 0
elif [ ${MAX} -lt 90 ]; then
        echo -n "WARNING - "
        echo "${OUTPUT}"
        exit 1
else
        echo -n "CRITICAL - "
        echo "${OUTPUT}"
        exit 2
fi
