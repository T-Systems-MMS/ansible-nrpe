#!/bin/bash
#set -x

# Script zur Pruefung von ddns Backups

HOSTNAME=$(hostname)
DATE_YESTERDAY=$(date -d "today -1 day" +%Y%m%d)
DATE_TODAY=$(date -d "today" +%Y%m%d)
DATE_LAST_HOUR=$(date -d "today -4 hour" +%Y%m%d%H)
BACKUPDIR="/vol1/backup/ddns"
DDNS_BACKUP_FILE_YESTERDAY1="ddns-basic*_$DATE_YESTERDAY*.tgz"
DDNS_BACKUP_FILE_YESTERDAY2="ddns-conf*_$DATE_YESTERDAY*.tgz"
NAGIOS_OK="0"

###

# nagios functions
function nagios_ok () {
        echo "OK! Backup seit $DATE_YESTERDAY vorhanden."
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
                        nagios_critical
                ;;
                1)
                        nagios_ok
                ;;
                *)
                        nagios_unknown
                ;;
        esac
}

#

function check_ddns_backup_exists () {

for DDNS_BACKUP_FILE_YESTERDAY in $DDNS_BACKUP_FILE_YESTERDAY1 $DDNS_BACKUP_FILE_YESTERDAY2
do
        COUNT_DDNS_BACKUP_FILE_YESTERDAY=`find $BACKUPDIR -name $DDNS_BACKUP_FILE_YESTERDAY | wc -l`

        if [ "$COUNT_DDNS_BACKUP_FILE_YESTERDAY" -gt 0 ] ; then
                NAGIOS_OK="1"
        else
                nagios_critical "Kein DDNS Backup fuer $DATE_YESTERDAY gefunden";
        fi
done
}

#

function check_ddns_backup_completed () {
for BACKUPFILE in DDNSDaemon.sh wrapper ddnsdaemon.properties wrapper.conf
do
        case $BACKUPFILE in
                DDNSDaemon.sh|wrapper)
                        BACKUP_FILE=$(find $BACKUPDIR -name $DDNS_BACKUP_FILE_YESTERDAY1)
                ;;
                ddnsdaemon.properties|wrapper.conf)
                        BACKUP_FILE=$(find $BACKUPDIR -name $DDNS_BACKUP_FILE_YESTERDAY2)
                ;;
        esac

        for BACKUP_FILE_IN in $BACKUP_FILERSTERDAYE
        do
                COUNT_DDNS_BACKUP_FILE_COMPLETED=$(zgrep -c "$BACKUPFILE" $BACKUP_FILE_IN | cut -d ":" -f "2")
                if [ "$COUNT_DDNS_BACKUP_FILE_COMPLETED" -gt "0" ] ; then
                        NAGIOS_OK="1"
                else
                        nagios_critical "FEHLER! DDNS Backup fuer $DATE_YESTERDAY nicht vollstaendig: $BACKUPFILE fehlt!";
                fi
        done
done
}

#

check_ddns_backup_exists;
check_ddns_backup_completed;
check_nagios_return_value;

###EOF
##
#
