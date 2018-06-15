#!/bin/bash
#
# Check JBoss 7.1 Heap Performance Data Module
# @2013 by ankl
#
##############################################

LABEL=$1
WARNING=$2
CRITICAL=$3
ROOTPATH="/opt/app"
CLIUSER=$4
CLIPASSWD=$5
CLI="${ROOTPATH}/${LABEL}/bin/jboss-cli.sh"
CLIPORT=`cat ${ROOTPATH}/${LABEL}/standalone/configuration/server.xml | grep "management-native" | grep "port" | awk -F':' '{ print $2 }' | awk -F'}' '{ print $1 }'`
JSTAT=$(command -v jstat)

JBOSSUSER="jboss"
JBOSSPID=`ps -U ${JBOSSUSER} -o pid,cmd | grep ${LABEL} | grep java | grep "-server" | awk '{ print $1 }'`

if [[ -z "${JBOSSPID}" ]]; then
        echo "JBOSS down or not reachable."
        exit 1
fi

Heap=`$CLI --connect --controller=localhost:${CLIPORT} --user=${CLIUSER} --password=${CLIPASSWD} command="/core-service=platform-mbean/type=memory:read-attribute(name=heap-memory-usage)"`
HeapUsed=`echo ${Heap} | awk -F'"used" => ' '{ print $2 }' | awk -F'L' '{ print $1 }'`
HeapTotal=`echo ${Heap} | awk -F'"committed" => ' '{ print $2 }' | awk -F'L' '{ print $1 }'`
HeapFree=$(($HeapTotal - $HeapUsed))
HeapMax=`echo ${Heap} | awk -F'"max" => ' '{ print $2 }' | awk -F'L' '{ print $1 }'`

Gen=$(sudo $JSTAT -gcold ${JBOSSPID} | tail -1)
GarbageCollectTime=$(echo $Gen | awk '{ print $8 }')
GarbageCollectTime=$(bc <<<"scale=0;(${GarbageCollectTime}*1000)")
GarbageCollectTime=${GarbageCollectTime/.*}

# Check if variable is a integer and not an exception
if ! [[ $HeapUsed -eq $HeapUsed ]] || ! [[ $HeapTotal -eq $HeapTotal ]] || ! [[ $HeapMax -eq $HeapMax ]] || ! [[ $GarbageCollectTime -eq $GarbageCollectTime ]] ; then
        echo "CRITITCAL: No data received"
        exit 1
fi

Oldgen=$(echo $Gen | awk '{ print $4 }')
Oldgen=$(bc <<<"scale=0;(${Oldgen}*1000)")
Oldgen=${Oldgen/.*}

PerfData="HeapUsed:$HeapUsed HeapFree:$HeapFree HeapTotal:$HeapTotal HeapMax:$HeapMax GarbageCollectTime:$GarbageCollectTime Oldgen:$Oldgen"

HeapRatio=$(((${HeapUsed}*100)/${HeapMax}))

HeapUsed=`bc <<<"scale=2;(${HeapUsed}/1024)/1024"`
HeapMax=`bc <<<"scale=2;(${HeapMax}/1024)/1024"`

if [ ${HeapRatio} -gt ${CRITICAL} ]
then
	echo "CRITICAL: ${HeapRatio}% Heap Space used ( ${HeapUsed}MB of ${HeapMax}MB )|${PerfData}"
	exit 2
fi
if [ ${HeapRatio} -gt ${WARNING} ]
then
	echo "WARNING: ${HeapRatio}% Heap Space used ( ${HeapUsed}MB of ${HeapMax}MB )|${PerfData}"
	exit 1
fi

echo "OK: ${HeapRatio}% Heap Space used ( ${HeapUsed}MB of ${HeapMax}MB )|${PerfData}"
exit 0
