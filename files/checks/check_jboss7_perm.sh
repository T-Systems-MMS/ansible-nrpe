#!/bin/bash
#
# Check JBoss 7.1 Perm Performance Data Module
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

JBOSSUSER="jboss"
JBOSSPID=`ps -U ${JBOSSUSER} -o pid,cmd | grep ${LABEL} | grep java | grep "-server" | awk '{ print $1 }'`

if [[ -z "${JBOSSPID}" ]]; then
        echo "JBOSS down or not reachable."
        exit 1
fi

Perm=`$CLI --connect --controller=localhost:${CLIPORT} --user=${CLIUSER} --password=${CLIPASSWD} command="/core-service=platform-mbean/type=memory:read-attribute(name=non-heap-memory-usage)"`
PermUsed=`echo ${Perm} | awk -F'"used" => ' '{ print $2 }' | awk -F'L' '{ print $1 }'`
PermTotal=`echo ${Perm} | awk -F'"committed" => ' '{ print $2 }' | awk -F'L' '{ print $1 }'`
PermFree=$(($PermTotal - $PermUsed))
PermMax=`echo ${Perm} | awk -F'"max" => ' '{ print $2 }' | awk -F'L' '{ print $1 }'`

PerfData="PermUsed:$PermUsed PermFree:$PermFree PermTotal:$PermTotal PermMax:$PermMax"

PermRatio=$(((${PermUsed}*100)/${PermMax}))

PermUsed=`bc <<<"scale=2;(${PermUsed}/1024)/1024"`
PermMax=`bc <<<"scale=2;(${PermMax}/1024)/1024"`

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

