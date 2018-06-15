#!/bin/bash
#set -x

# Script zur Pruefung von mysqlbinlog erstellten files

hostname=$(/bin/hostname)
date=$(date +%Y-%m-%d)
date_yesterday=$(/bin/date -d "today -1 day" +%Y-%m-%d)
date_week=$(date +%V)
backupdir=$1
instance=$2
#backupdir="/opt/backup/mysql/binlogs/backup_binlog_$inst/KW_$date_week/$date_yesterday"
mysqlbinlogfile="mysql-bin.*.gz"
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
        exit 0
}

#

function nagios_critical () {
        echo $@
        exit 2
}

#

function nagios_unknown () {
        echo $@
        exit 3
}

#

function check_nagios_return_value() {
        case $NAGIOS_OK in
                0)
                        nagios_critical "Fehler!"
                ;;
                1)
                        nagios_ok "OK! ${anzahl_mysqlbinlogfiles} Binlogs gefunden."
                ;;
                *)
                        nagios_unknown "Unbekannter Fehler!"
                ;;
        esac
}

# pruefe ob mysqlbinlogfile vorhanden ist
function check_mysqlbinlog_exist () {
anzahl_mysqlbinlogfiles=`ls $backupdir/$mysqlbinlogfile | wc -l`
if [ "$anzahl_mysqlbinlogfiles" -lt 1 ] ; then
        nagios_critical "Kein mysqlbinlogfile fuer ${INSTANCE} vom ${date_yesterday} gefunden.";
else
        NAGIOS_OK="1"
fi
}

check_mysqlbinlog_exist;
check_nagios_return_value;

###EOF
##
#


