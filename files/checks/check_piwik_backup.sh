#!/bin/bash

## variables

DATE="`date --date="yesterday" +%F`"
HOSTNAME="`hostname`"
BACKUPDIR="/opt/backup/piwik"
BACKUPFILE="$BACKUPDIR/backup_"

declare -i failcount=0


### nagios functions

 nagios_ok () {
        echo $@
        exit 0
}

 nagios_critical () {
        echo $@
        exit 2
}



### function check backup files

filecheck(){
filecheck=$(find $BACKUPDIR -name "backup-$DATE.tar.gz" -size +1M | wc -l)
if [ $filecheck -ne  1 ]; then
        failcount=$failcount+1
fi
}


### function nagios messages
nagios_message() {
if [ $failcount -eq 0  ]; then
        nagios_ok "OK. The current backup exists."
else
        nagios_critical "Can not find current backup for Piwik on $HOSTNAME! Please check backup folder $BACKUPDIR/."
fi
}

# execute functions
filecheck
nagios_message

