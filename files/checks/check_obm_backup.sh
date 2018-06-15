#!/bin/sh
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#       - OBM Check script
#               - version: 1.1
#               - function: should check wether log files exist in /root/.obm/log for the current day,
#                           if not, this is a clue that something went wrong while the last backup run
#               - author: jzo, mky
#
#
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#

#STARTTIME=`date +%s`
LOG_PATH="/root/.obm/log"

cd $LOG_PATH

# get the LOG_DIR, which is a timecode
LOG_DIR=`ls -t $LOG_PATH/ | egrep '^([1-9]{1})([0-9]*)$' -m1`

# check wether the log_dir contains a logfile for YYYY-MM-DD-*
CURRENT_DATE=`date +%F`
YESTERDATE=`date -d"now -1 day" +%F`
LOGFILES=`ls ${LOG_PATH}/${LOG_DIR}/Backup/${CURRENT_DATE}*`
EC1=$?
YESTERLOGFILE=`ls ${LOG_PATH}/${LOG_DIR}/Backup/${YESTERDATE}*`
EC2=$?

if [ $EC1 -eq 0 ]; then

        # grep through all logfiles the the string '[err]'
        grep '\[erro\]' $LOGFILES
        EC3=$?

        if [ $EC3 -eq 0 ]; then
                echo "An error occured to the backup. Please check!"
                exit 2
        else
                grep -e "Backup erfolgreich abgeschlossen" $LOGFILES
                exit 0
        fi
else
        if [ $EC2 -eq 0 ]; then
                echo "Backup isn't finished yet, please check later."
                exit 0
        else
                echo "No Log-Files generated for today and yesterday. Please check your Backup!"
                exit 1
        fi
fi

