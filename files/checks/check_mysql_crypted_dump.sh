#!/bin/bash
# Script zur Pruefung von mysqldump erstellten files

inst="$1"
hostname=`hostname`
date_yesterday=`date -d "today -1 day" +%Y-%m-%d`
backupdir="/opt/backup/mysql/dumps"
mysqldumpfile="$backupdir/backup-$hostname-$inst-$date_yesterday*.sql.gz"
mysqldumperrorlogfile="$backupdir/backup-$hostname-$inst-$date_yesterday*.log"
PASSWORD=$2
GPG=$(command -v gpg)

# nagios functions
function nagios_ok () {
        echo $@
}

function nagios_critical () {
        echo $@
        exit 2
}


# pruefe ob mysqldumpfile vorhanden ist
function check_mysqldump_exist () {
anzahl_mysqldumpfiles=$(ls $mysqldumpfile | wc -l)
if [ "$anzahl_mysqldumpfiles" -lt 1 ] ; then
        nagios_critical "FEHLER! Kein mysqldumpfile gefunden.";
fi
}

# pruefe mysqldumpfile auf "dump completed"
function check_mysqldump_completed () {
for dumpfile in $mysqldumpfile
do
        anzahl_mysqldumpfile_complete_message=$(su - nrpe -c "$GPG -q --batch -rnrpe --passphrase $PASSWORD -d $mysqldumpfile | tail -1 | grep -c 'Dump completed'")
        if [ "$anzahl_mysqldumpfile_complete_message" -lt 1 ] ; then
                nagios_critical "FEHLER! Mysqldumpfile ist nicht vollstaendig.";
        fi
done
}

# pruefe ob errorlogfile vorhanden ist
function check_mysqldump_errorlogfile_exist () {
anzahl_mysqldump_errorlogfiles=$(ls $mysqldumperrorlogfile | wc -l)
if [ "$anzahl_mysqldump_errorlogfiles" -lt 1 ] ; then
        nagios_critical "FEHLER! Kein mysqldump-errorlogfile gefunden";
fi

# pruefe ob errorlogfile leer ist
function check_mysqldump_errorlogfile_errors () {
mysqldump_errorlogfile_error=$(tail -n 1 $mysqldumperrorlogfile)
#echo "$mysqldump_errorlogfile_error"
if [ "$mysqldump_errorlogfile_error" != "" ] ; then
        nagios_critical "Fehler in mysqldump_errorlogfile gefunden: $mysqldump_errorlogfile_error";
else
        nagios_ok "OK"
        exit 0
fi
}

check_mysqldump_exist;
check_mysqldump_completed;
check_mysqldump_errorlogfile_exist;
check_mysqldump_errorlogfile_errors;

