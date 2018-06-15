#!/bin/bash
#
# Check JBoss 7.1 Threads Performance Data Module
# @2013 by ankl
#
#################################################

LABEL=$1
WARNING=$2
CRITICAL=$3
ROOTPATH="/opt/app"
CLIUSER=$4
CLIPASSWD=$5
CLI="${ROOTPATH}/${LABEL}/bin/jboss-cli.sh"
CLIPORT=`cat ${ROOTPATH}/${LABEL}/standalone/configuration/server.xml | grep "management-native" | grep "port" | awk -F':' '{ print $2 }' | awk -F'}' '{ print $1 }'`
THREADPOOLTYPE="unbounded-queue-thread-pool"
THREADPOOLNAME="JBossWeb"

JBOSSUSER="jboss"
JBOSSPID=`ps -U ${JBOSSUSER} -o pid,cmd | grep ${LABEL} | grep java | grep "-server" | awk '{ print $1 }'`

if [[ -z "${JBOSSPID}" ]]; then
        echo "JBOSS down or not reachable."
        exit 1
fi

Threads=`$CLI --connect --controller=localhost:${CLIPORT} --user=${CLIUSER} --password=${CLIPASSWD} command="/subsystem=threads/${THREADPOOLTYPE}=${THREADPOOLNAME}:read-resource(include-runtime=true)"`
ThreadsBusy=`echo ${Threads} | awk -F'"active-count" => ' '{ print $2 }' | awk -F',' '{ print $1 }'`
ThreadsExist=`echo ${Threads} | awk -F'"current-thread-count" => ' '{ print $2 }' | awk -F',' '{ print $1 }'`
ThreadsMax=`echo ${Threads} | awk -F'"max-threads" => ' '{ print $2 }' | awk -F',' '{ print $1 }'`

PerfData="ThreadsBusy:$ThreadsBusy ThreadsExist:$ThreadsExist ThreadsMax:$ThreadsMax"

ThreadRatio=$(((${ThreadsBusy}*100)/${ThreadsMax}))

if [ ${ThreadRatio} -gt ${CRITICAL} ]
then
	echo "CRITICAL: ${ThreadRatio}% Threads are busy ( ${ThreadsBusy} of ${ThreadsMax} )|${PerfData}"
	exit 2
fi
if [ ${ThreadRatio} -gt ${WARNING} ]
then
	echo "WARNING: ${ThreadRatio}% Threads are busy ( ${ThreadsBusy} of ${ThreadsMax} )|${PerfData}"
	exit 1
fi

echo "OK: ${ThreadRatio}% Threads are busy ( ${ThreadsBusy} of ${ThreadsMax} )|${PerfData}"
exit 0
