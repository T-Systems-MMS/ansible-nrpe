#!/bin/sh
#Description
#This Scripts checks the RPM development directories and writes it into a text-file. This file will be copied to the other node. Further the file will be compared with the file from the other node by md5 sum.

directories="/var/spool/cron /etc/ /opt/nagios/libexec/ /opt/nagios/share/www/nagiosbpi/ /opt/cacti/share/www/scripts/ /root/scripts/"

# Check all directories
rm -f /tmp/etcdir_local_md5.txt >> /dev/null 2>&1
find $directories \( -path '/etc/adjtime' -o -path '/etc/aliases.db' -o -path '/etc/blkid' -o -path '/etc/gconf/gconf.xml.defaults/%gconf-tree.xml' -o -path '/etc/gtk-2.0/i686-redhat-linux-gnu' -o -path '/etc/hosts' -o -path '/etc/ld.so.cache' -o -path '/etc/lvm/archive' -o -path '/etc/lvm/backup' -o -path '/etc/lvm/cache/.cache' -o -path '/etc/mail/*.db' -o -path '/etc/mtab' -o -path '/etc/my.cnf' -o -path '/etc/opt/hp/sslshare/*' -o -path '/etc/opt/microsoft/scx/ssl/*' -o -path '/etc/pki/tls/certs/exim.pem' -o -path '/etc/pki/tls/private/exim.pem' -o -path '/etc/prelink.cache' -o -path '/etc/shadow*' -o -path '/etc/snmp/snmpd.conf' -o -path '/etc/ssh/ssh_host_*' -o -path '/etc/sysconfig/hwconf' -o -path '/etc/sysconfig/network' -o -path '/etc/sysconfig/network-scripts/*' -o -path '/etc/sysconfig/networking/*' -o -path '/etc/selinux/targeted/modules/active/commit_num' -o -path '/etc/selinux/targeted/modules/previous/*' -o -path '/etc/avahi/etc/localtime' \) -prune -o -type f  -exec md5sum {} \; | sort +1 -2 >> /tmp/etcdir_local_md5.txt

rm -f /tmp/etcdir_local.txt >> /dev/null 2>&1
find $directories -type d | sort >> /tmp/etcdir_local.txt


ssh othernode "rm -f /tmp/etcdir_remote_md5.txt >> /dev/null 2>&1"
ssh othernode "find $directories \( -path '/etc/adjtime' -o -path '/etc/aliases.db' -o -path '/etc/blkid' -o -path '/etc/gconf/gconf.xml.defaults/%gconf-tree.xml' -o -path '/etc/gtk-2.0/i686-redhat-linux-gnu' -o -path '/etc/hosts' -o -path '/etc/ld.so.cache' -o -path '/etc/lvm/archive' -o -path '/etc/lvm/backup' -o -path '/etc/lvm/cache/.cache' -o -path '/etc/mail/*.db' -o -path '/etc/mtab' -o -path '/etc/my.cnf' -o -path '/etc/opt/hp/sslshare/*' -o -path '/etc/opt/microsoft/scx/ssl/*' -o -path '/etc/pki/tls/certs/exim.pem' -o -path '/etc/pki/tls/private/exim.pem' -o -path '/etc/prelink.cache' -o -path '/etc/shadow*' -o -path '/etc/snmp/snmpd.conf' -o -path '/etc/ssh/ssh_host_*' -o -path '/etc/sysconfig/hwconf' -o -path '/etc/sysconfig/network' -o -path '/etc/sysconfig/network-scripts/*' -o -path '/etc/sysconfig/networking/*' -o -path '/etc/selinux/targeted/modules/active/commit_num' -o -path '/etc/selinux/targeted/modules/previous/*' -o -path '/etc/avahi/etc/localtime' \) -prune -o -type f  -exec md5sum {} \; | sort +1 -2 >> /tmp/etcdir_remote_md5.txt"

ssh othernode "rm -f /tmp/etcdir_remote.txt >> /dev/null 2>&1"
ssh othernode "find $directories -type d | sort>> /tmp/etcdir_remote.txt"

scp othernode:/tmp/etcdir_remote.txt /tmp/ >> /dev/null 2>&1
scp othernode:/tmp/etcdir_remote_md5.txt /tmp/ >> /dev/null 2>&1

# Compare directories
diff /tmp/etcdir_local.txt /tmp/etcdir_remote.txt > /tmp/etcdir_comp.txt 2>&1
EC1=$?
diff /tmp/etcdir_local_md5.txt /tmp/etcdir_remote_md5.txt > /tmp/etcdir_comp_md5.txt 2>&1
EC2=$?
CHECK_FILE=`grep -P "^<" /tmp/etcdir_comp_md5.txt | grep -o -P "/.*[A-Za-z].*$"`;
CHECK_DIRECTORY=`grep -P "^<" /tmp/etcdir_comp.txt | grep -o -P " .*[A-Za-z0-9]"`;

# Evaluation
if [ $EC1 -eq 0 ] && [ $EC2 -eq 0 ]; then
        echo "The directories $directories are equal on both hosts"
        exit 0
else
        if [ $EC1 -ne 0 ]; then
        if [ -z "$CHECK_DIRECTORY" ]; then
        echo "Directory missing on this node. Please check the other node!"
        exit 1
        else
        echo "Directory: \""$CHECK_DIRECTORY"\" needs to be checked"
        exit 2
        fi
        fi

        if [ $EC2 -ne 0 ]; then
        if [ -z "$CHECK_FILE" ]; then
        echo "File(s) missing on this node. Please check the other node!"
        exit 1
        else
        echo "File: \""$CHECK_FILE"\" needs to be checked"
        exit 2
        fi
        fi
fi
