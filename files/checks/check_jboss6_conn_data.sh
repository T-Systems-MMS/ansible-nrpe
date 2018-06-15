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
PORT=$(grep 'Connector protocol="HTTP/1.1" port="' $ROOTPATH/$LABEL/server/default/deploy/jbossweb.sar/server.xml| awk -F'"' '{print $4}')
CLIPORT=1390
JBOSSUSER="jboss"
JBOSSPID=`ps -U ${JBOSSUSER} -o pid,cmd | grep ${LABEL} | grep java | grep "-server" | awk '{ print $1 }'`

if [[ -z "${JBOSSPID}" ]]; then
        echo "JBOSS down or not reachable."
        exit 1
fi

#declare values
values=(ConnectionReqs ConnectionErrs DataInbound DataOutbound)
count=

#run query only once
Conns=$($CLI -s service:jmx:rmi:///jndi/rmi://${ADDRESS}:${CLIPORT}/jmxrmi get "jboss.web:type=GlobalRequestProcessor,name=http-$ADDRESS-$PORT" requestCount errorCount bytesReceived bytesSent --noprefix)

#assign values
for i in $Conns; do
        eval ${values[$count]}=$i
        count=$(( $count + 1 ))
done

#ConnectionReqs=$($CLI -s service:jmx:rmi:///jndi/rmi://${ADDRESS}:${CLIPORT}/jmxrmi get "jboss.web:type=GlobalRequestProcessor,name=http-$ADDRESS-$PORT" requestCount --noprefix)
#ConnectionErrs=$($CLI -s service:jmx:rmi:///jndi/rmi://${ADDRESS}:${CLIPORT}/jmxrmi get "jboss.web:type=GlobalRequestProcessor,name=http-$ADDRESS-$PORT" errorCount --noprefix)
#DataInbound=$($CLI -s service:jmx:rmi:///jndi/rmi://${ADDRESS}:${CLIPORT}/jmxrmi get "jboss.web:type=GlobalRequestProcessor,name=http-$ADDRESS-$PORT" bytesReceived --noprefix)
#DataOutbound=$($CLI -s service:jmx:rmi:///jndi/rmi://${ADDRESS}:${CLIPORT}/jmxrmi get "jboss.web:type=GlobalRequestProcessor,name=http-$ADDRESS-$PORT" bytesSent --noprefix)

PerfData="ConnectionRequests:$ConnectionReqs ConnectionErrors:$ConnectionErrs DataInbound:$DataInbound DataOutbound:$DataOutbound"

if [ $ConnectionReqs -ne 0 ]
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

