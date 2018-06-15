#!/bin/bash
#
# Check JBoss 7.1 Connection and Throughput Performance Data Module
# @2013 by ankl
#
###################################################################

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

Conn=$($CLI --connect --controller=localhost:${CLIPORT} --user=${CLIUSER} --password=${CLIPASSWD} --commands="/subsystem=web/connector=http:read-attribute(name=requestCount), /subsystem=web/connector=http:read-attribute(name=errorCount), /subsystem=web/connector=http:read-attribute(name=bytesReceived), /subsystem=web/connector=http:read-attribute(name=bytesSent)")

ConnectionReqs=$(echo $Conn | cut -d "\"" -f 8)
ConnectionErrs=$(echo $Conn | cut -d "\"" -f 16)
DataInbound=$(echo $Conn | cut -d "\"" -f 24)
DataOutbound=$(echo $Conn | cut -d "\"" -f 32)

#ConnectionReqs=`$CLI --connect --controller=localhost:${CLIPORT} --user=${CLIUSER} --password=${CLIPASSWD} command="/subsystem=web/connector=http:read-attribute(name=requestCount)" | grep "result" | awk -F' => ' '{ print $2 }' | sed 's/"//g'`
#ConnectionErrs=`$CLI --connect --controller=localhost:${CLIPORT} --user=${CLIUSER} --password=${CLIPASSWD} command="/subsystem=web/connector=http:read-attribute(name=errorCount)" | grep "result" | awk -F' => ' '{ print $2 }' | sed 's/"//g'`
#DataInbound=`$CLI --connect --controller=localhost:${CLIPORT} --user=${CLIUSER} --password=${CLIPASSWD} command="/subsystem=web/connector=http:read-attribute(name=bytesReceived)" | grep "result" | awk -F' => ' '{ print $2 }' | sed 's/"//g'`
#DataOutbound=`$CLI --connect --controller=localhost:${CLIPORT} --user=${CLIUSER} --password=${CLIPASSWD} command="/subsystem=web/connector=http:read-attribute(name=bytesSent)" | grep "result" | awk -F' => ' '{ print $2 }' | sed 's/"//g'`

PerfData="ConnectionRequests:$ConnectionReqs ConnectionErrors:$ConnectionErrs DataInbound:$DataInbound DataOutbound:$DataOutbound"

if [ ${ConnectionReqs} -ne 0 ]
then
ErrorRatio=`bc -l <<<"scale=0;(${ConnectionErrs}*100)/${ConnectionReqs}"`
else
ErrorRatio=0
fi

if [ ${ErrorRatio} -gt ${CRITICAL} ]
then
	echo "CRITICAL: ${ErrorRatio}% Connection Errors ( ${ConnectionErrs}/s of ${ConnectionReqs}/s )|${PerfData}"
	exit 2
fi
if [ ${ErrorRatio} -gt ${WARNING} ]
then
	echo "WARNING: ${ErrorRatio}% Connection Errors ( ${ConnectionErrs}/s of ${ConnectionReqs}/s )|${PerfData}"
	exit 1
fi

echo "OK: ${ErrorRatio}% Connection Errors ( ${ConnectionErrs}/s of ${ConnectionReqs}/s )|${PerfData}"
exit 0
