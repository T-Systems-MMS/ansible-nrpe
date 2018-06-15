#!/bin/sh
#Description
#This Scripts checks the RPM / PEAR / CPAN databases and writes it into a text-file. This file will be copied to the other node. Further the file will be compared with the file from the other node by md5 sum.

# Check for RPM installed Packages
rpm -qa | sort > /tmp/rpmdb_local.txt
ssh othernode "rpm -qa | sort> /tmp/rpmdb_remote.txt"
scp othernode:/tmp/rpmdb_remote.txt /tmp/ >> /dev/null 2>&1

# Check for PEAR installed Packages
pear list > /tmp/peardb_local.txt
ssh othernode "pear list > /tmp/peardb_remote.txt"
scp othernode:/tmp/peardb_remote.txt /tmp/ >> /dev/null 2>&1

# Check for CPAN installed Packages
/usr/bin/perl /usr/bin/pminst | sort > /tmp/cpandb_local.txt
ssh othernode "/usr/bin/perl /usr/bin/pminst | sort > /tmp/cpandb_remote.txt"
scp othernode:/tmp/cpandb_remote.txt /tmp/ >> /dev/null 2>&1

# Comparison RPM
diff /tmp/rpmdb_local.txt /tmp/rpmdb_remote.txt >> /dev/null 2>&1
EC1=$?

# Comparison PEAR
diff /tmp/peardb_local.txt /tmp/peardb_remote.txt >> /dev/null 2>&1
EC2=$?

# Comparison CPAN
diff /tmp/cpandb_local.txt /tmp/cpandb_remote.txt >> /dev/null 2>&1
EC3=$?

# Evaluation
ERRORS=""
if [ $EC1 -eq 0 ] && [ $EC2 -eq 0 ] && [ $EC3 -eq 0 ]; then
        echo "all databases equal"
        exit 0
else
 if [ $EC1 -ne 0 ]; then
 ERRORS="$ERRORS rpmdb"
 fi

 if [ $EC2 -ne 0 ]; then
        ERRORS="$ERRORS peardb"
        fi

        if [ $EC3 -ne 0 ]; then
        ERRORS="$ERRORS cpandb"
        fi

 echo "following databases needs to be checked: $ERRORS"
        exit 1
fi
