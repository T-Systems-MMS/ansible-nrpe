#!/bin/bash
#
# Check JBoss 6.1 Connection Data Module
# @2013 by segu
#
##############################################

LABEL=$1
WARNING=$2
CRITICAL=$3
ROOTPATH="/opt/app"
CLI="${ROOTPATH}/${LABEL}/bin/twiddle.sh"
ADDRESS=$(ip a s | grep "scope global eth0" | grep -v secondary |  cut -d " " -f6 | cut -d "/" -f1)
CLIPORT=1390
PORT=$(grep 'Connector protocol="HTTP/1.1" port="' $ROOTPATH/$LABEL/server/default/deploy/jbossweb.sar/server.xml| awk -F'"' '{print $4}')
JBOSSUSER="jboss"
JBOSSPID=`ps -U ${JBOSSUSER} -o pid,cmd | grep ${LABEL} | grep java | grep "-server" | awk '{ print $1 }'`

if [[ -z "${JBOSSPID}" ]]; then
        echo "JBOSS down or not reachable."
        exit 1
fi

#declare values
values=(ThreadsMax ThreadsBusy ThreadCount)
count=

#run query only once
Threads=$($CLI -s service:jmx:rmi:///jndi/rmi://${ADDRESS}:${CLIPORT}/jmxrmi get "jboss.web:type=ThreadPool,name=http-$ADDRESS-$PORT" maxThreads currentThreadsBusy currentThreadCount --noprefix) 

#assign values
for i in $Threads; do
        eval ${values[$count]}=$i
        count=$(( $count + 1 ))
done

ThreadsCountCacti=$(echo "${ThreadCount}-${ThreadsBusy}" | bc -l)
PerfData="ThreadsBusy:$ThreadsBusy ThreadsExist:$ThreadCount ThreadsMax:$ThreadsMax"

ThreadRatio=$(bc <<<"scale=2;(${ThreadsBusy}*100/${ThreadsMax})")

if (( $(echo "${ThreadRatio} > ${CRITICAL}" | bc -l) ));
then
        echo "CRITICAL: ${ThreadRatio}% Threads are busy ( ${ThreadsBusy} of ${ThreadsMax} )|${PerfData}"
        exit 2
fi

if (( $(echo "${ThreadRatio} > ${WARNING}" | bc -l) ));
then
        echo "WARNING: ${ThreadRatio}% Threads are busy ( ${ThreadsBusy} of ${ThreadsMax} )|${PerfData}"
        exit 1
fi

echo "OK: ${ThreadRatio}% Threads are busy ( ${ThreadsBusy} of ${ThreadsMax} )|${PerfData}"
exit 0

