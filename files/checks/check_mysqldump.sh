#!/bin/bash
#set -x

# Script zur Pruefung von mysqldump erstellten files

hostname=$(/bin/hostname)
date_yesterday=$(/bin/date -d "today -1 day" +%Y-%m-%d)
backupdir=$1
instance=$2
mysqldumpfile="backup-$instance-$hostname-$date_yesterday*.sql.gz"
mysqldumperrorlogfile="backup-$instance-$hostname-$date_yesterday*.log"
VIP=""

#check for arguments
if [ $# -eq 0 ]; then
	echo "No instance or backup-dir supplied on command-line."
	echo "Usage: $0 \$BACKUPDIR \$INSTANCE"
	exit 1
fi

# nagios functions
function nagios_ok () {
        echo $@
}

#

function nagios_critical () {
        echo $@
        exit 2
}

# pruefe ob mysqldumpfile vorhanden ist
function check_mysqldump_exist () {
anzahl_mysqldumpfiles=$(ls $backupdir/$mysqldumpfile | wc -l)
if [ "$anzahl_mysqldumpfiles" -lt 1 ] ; then
        nagios_critical "Kein mysqldumpfile fuer $date_yesterday gefunden.";
fi
}

#

# pruefe mysqldumpfile auf "dump completed"
function check_mysqldump_completed () {
for dumpfile in $(ls -tR1 $backupdir/$mysqldumpfile | head -1)
do
        anzahl_mysqldumpfile_complete_message=$(zgrep -c "Dump completed" $dumpfile)

        if [ "$anzahl_mysqldumpfile_complete_message" -lt 1 ] ; then
                nagios_critical "Fehler im Dump fuer $date_yesterday gefunden.";
        fi
done
}

#

# pruefe ob errorlogfile vorhanden ist
function check_mysqldump_errorlogfile_exist () {
anzahl_mysqldump_errorlogfiles=$(ls $backupdir/$mysqldumperrorlogfile | wc -l)
if [ "$anzahl_mysqldump_errorlogfiles" -lt 1 ] ; then
        nagios_critical "Kein mysqldump-errorlogfile fuer $date_yesterday gefunden.";
fi
}

#

# pruefe ob errorlogfile leer ist
function check_mysqldump_errorlogfile_errors () {
mysqldump_errorlogfile_error=$(tail -1 $backupdir/$mysqldumperrorlogfile)
#echo "$mysqldump_errorlogfile_error"
if [ "$mysqldump_errorlogfile_error" != "" ] ; then
        nagios_critical "Fehler in mysqldump_errorlogfile fuer $date_yesterday gefunden: $mysqldump_errorlogfile_error.";
else
        nagios_ok "OK. Backup vom $date_yesterday gefunden."
        exit 0
fi
}

#

check_mysqldump_exist;
check_mysqldump_completed;
check_mysqldump_errorlogfile_exist;
check_mysqldump_errorlogfile_errors;

###
##
#EOF

