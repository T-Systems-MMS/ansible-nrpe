#!/bin/bash
#set -x

# Script zur Pruefung von tftpd Backups

HOSTNAME=$(hostname)
DATE_YESTERDAY=$(date -d "today -1 day" +%Y%m%d)
BACKUPDIR="/vol1/backup/tftpd"
TFTPD_BACKUP_FILE_YESTERDAY="tftpd-root_$DATE_YESTERDAY*.tgz"
NAGIOS_OK="0"

###

# nagios functions
function nagios_ok () {
        echo "OK! Backup fuer $DATE_YESTERDAY vorhanden."
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


function check_tftpd_backup_exists () {

COUNT_TFTPD_BACKUP_FILE_YESTERDAY=$(find $BACKUPDIR -name $TFTPD_BACKUP_FILE_YESTERDAY | wc -l)

if [ $COUNT_TFTPD_BACKUP_FILE_YESTERDAY -gt 0 ] ; then
        NAGIOS_OK="1"
else
        nagios_critical "Kein TFTPD Backup fuer $DATE_YESTERDAY gefunden";
fi
}

#

function check_tftpd_backup_completed () {
for BACKUPFILE in 57i.st aastra.cfg lang_de.txt
do
        for BACKUP_FILE in $(find $BACKUPDIR -name $TFTPD_BACKUP_FILE_YESTERDAY)
        do
                COUNT_TFTPD_BACKUP_FILE_COMPLETED=$(zgrep -c "$BACKUPFILE" $BACKUP_FILE | cut -d ":" -f "2")
                if [ "$COUNT_TFTPD_BACKUP_FILE_COMPLETED" -gt 0 ] ; then
                        NAGIOS_OK="1"
                else
                        nagios_critical "FEHLER! TFTPD Backup fuer $DATE_YESTERDAY nicht vollstaendig: $BACKUPFILE fehlt!";
                fi
        done
done
}

#

check_tftpd_backup_exists;
check_tftpd_backup_completed;
check_nagios_return_value;

###EOF
##
#

