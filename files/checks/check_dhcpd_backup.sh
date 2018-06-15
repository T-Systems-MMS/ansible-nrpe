#!/bin/bash
#set -x

# Script zur Pruefung von dhcpd Backups

HOSTNAME=$(hostname)
DATE_LAST_HOUR=$(date -d "today -4 hour" +%Y%m%d%H)
BACKUPDIR="/vol1/backup/dhcpd"
DHCPD_BACKUP_FILE_TODAY1="dhcpd-basic*.tgz"
DHCPD_BACKUP_FILE_TODAY2="dhcpd-dynamic*.tgz"
NAGIOS_OK="0"

###

# nagios functions
nagios_ok () {
        echo "OK! Backup seit $DATE_LAST_HOUR vorhanden."
        exit 0
}

#

nagios_critical () {
        echo $@
        exit 2
}

#

nagios_unknown () {
        echo $@
        exit 3
}

#

check_nagios_return_value() {
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

check_dhcpd_backup_exists () {

for DHCPD_BACKUP_FILE_TODAY in $DHCPD_BACKUP_FILE_TODAY1 $DHCPD_BACKUP_FILE_TODAY2
do
        COUNT_DHCPD_BACKUP_FILE_TODAY=$(find $BACKUPDIR -name $DHCPD_BACKUP_FILE_TODAY* -mmin -240 | wc -l)

        if [ $COUNT_DHCPD_BACKUP_FILE_TODAY -gt 0 ] ; then
                NAGIOS_OK="1"
        else
                nagios_critical "Kein DHCPD Backup seit $DATE_LAST_HOUR gefunden";
        fi
done
}

#

check_dhcpd_backup_completed () {
for BACKUPFILE in dhcpd.conf dhcpd.conf.temporaer dhcpd.conf.dynamic
do
        case $BACKUPFILE in
                dhcpd.conf)
                        BACKUP_FILE=$(find $BACKUPDIR -name $DHCPD_BACKUP_FILE_TODAY1 -mmin -240)
                ;;
                *)
                        BACKUP_FILE=$(find $BACKUPDIR -name $DHCPD_BACKUP_FILE_TODAY2 -mmin -240)
                ;;
        esac

        for BACKUP_FILE_IN in $BACKUP_FILE
        do
                COUNT_DHCPD_BACKUP_FILE_COMPLETED=$(zgrep -c "$BACKUPFILE" $BACKUP_FILE_IN | cut -d ":" -f "2" | uniq)
                if [ "$COUNT_DHCPD_BACKUP_FILE_COMPLETED" -gt "0" ] ; then
                        NAGIOS_OK="1"
                else
                        nagios_critical "FEHLER! DHCPD Backup seit $DATE_LAST_HOUR nicht vollstaendig: $BACKUPFILE fehlt!";
                fi
        done
done
}

#

check_dhcpd_backup_exists;
check_dhcpd_backup_completed;
check_nagios_return_value;

###EOF
##
#

