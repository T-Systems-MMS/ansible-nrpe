#!/bin/bash
#
# Check JBoss 6.1 Perm Performance Data Module
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

JBOSSUSER="jboss"
JBOSSPID=`ps -U ${JBOSSUSER} -o pid,cmd | grep ${LABEL} | grep java | grep "-server" | awk '{ print $1 }'`

if [[ -z "${JBOSSPID}" ]]; then
        echo "JBOSS down or not reachable."
        exit 1
fi

Perm=$($CLI -s service:jmx:rmi:///jndi/rmi://${ADDRESS}:${CLIPORT}/jmxrmi get "java.lang:type=MemoryPool,name=PS Perm Gen" CollectionUsage |  cut -d '{' -f 2 | cut -d } -f 1)

PermMax=`bc <<<"scale=0;$(echo $Perm | cut -d = -f 4 | cut -d , -f 1)"`
PermTotal=`bc <<<"scale=0;$(echo $Perm | cut -d = -f 2 | cut -d , -f 1)"`
PermUsed=`bc <<<"scale=0;$(echo $Perm | cut -d = -f 5 | cut -d , -f 1)"`
PermFree=$(($PermTotal - $PermUsed))

PerfData="PermUsed:$PermUsed PermFree:$PermFree PermTotal:$PermTotal PermMax:$PermMax"

PermMax=`bc <<<"scale=2;(${PermMax}/1024/1024)"`
PermUsed=`bc <<<"scale=2;(${PermUsed}/1024/1024)"`

#PermRatio=${PermUsed}*100/${PermMax}
PermRatio=$(bc <<<"scale=0;(${PermUsed}*100/${PermMax})")


if [ ${PermRatio} -gt ${CRITICAL} ]
then
        echo "CRITICAL: ${PermRatio}% Perm Space used ( ${PermUsed}MB of ${PermMax}MB )|${PerfData}"
        exit 2
fi
if [ ${PermRatio} -gt ${WARNING} ]
then
        echo "WARNING: ${PermRatio}% Perm Space used ( ${PermUsed}MB of ${PermMax}MB )|${PerfData}"
        exit 1
fi

echo "OK: ${PermRatio}% Perm Space used ( ${PermUsed}MB of ${PermMax}MB )|${PerfData}"
exit 0

