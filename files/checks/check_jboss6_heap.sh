#!/bin/bash
#
# Check JBoss 6.1 Heap Performance Data Module
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

#declare values
values=(HeapMax HeapTotal HeapFree)
count=

#run query only once
Heap=$($CLI -s service:jmx:rmi:///jndi/rmi://${ADDRESS}:${CLIPORT}/jmxrmi get "jboss.system:type=ServerInfo" MaxMemory TotalMemory FreeMemory --noprefix)

#assign values
for i in $Heap; do
	eval ${values[$count]}=$i
	count=$(( $count + 1 ))
done
HeapUsed=$(($HeapTotal-$HeapFree))

GarbageCollectTime=$($CLI -s service:jmx:rmi:///jndi/rmi://${ADDRESS}:${CLIPORT}/jmxrmi get "java.lang:type=GarbageCollector,name=PS MarkSweep" CollectionTime --noprefix)
Oldgen=$($CLI -s service:jmx:rmi:///jndi/rmi://${ADDRESS}:${CLIPORT}/jmxrmi get "java.lang:type=MemoryPool,name=PS Old Gen" CollectionUsage |  cut -d '{' -f 2 |  cut -d = -f 5 | sed 's/}//' | sed 's/)//')


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

