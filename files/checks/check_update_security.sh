#!/bin/bash
# 09.2014 by ankl
#################################################

# global config variables
critical_days=90
warning_days=76

# files
openscap_result_file=/vol1/app/openscap/results.xml
openscap_vuln_file=/vol1/app/openscap/com.redhat.rhsa-all.xml

# operating system update variables
last_yum_update=$(sudo /usr/bin/yum history | sed -e '1,3d' -e '$d' | cut -d'|' -f3,4 | egrep 'Update|U' | head -n1 | cut -d'|' -f1)
days_since_last_update=$((($(date +%s --date 'now')-$(date +%s --date "$last_yum_update"))/60/60/24))


if [ ! -e $openscap_vuln_file ] || test "$(find $openscap_vuln_file -mtime +10)"; then
	echo "CRITICAL: Openscap vulnerability file does not exist or is older than 10 days, download from ServiceShell or Redhat not working!"
	exit 2
fi

if [ -z "$last_yum_update" ]
then
        days_since_last_update=99999
fi

if [ -e $openscap_result_file ]
then
        openscap_check_result=$(sed -n -e 's/.*<score.*>\(.*\)<\/score>.*/\1/p' $openscap_result_file)
        openscap_check_count=$(sed -n -e 's/.*<result>\(.*\)<\/result>.*/\1/p' $openscap_result_file | wc -l)
        openscap_check_count_passed=$(sed -n -e 's/.*<result>\(.*\)<\/result>.*/\1/p' $openscap_result_file | egrep "^pass$" | wc -l)
        days_since_last_check=$((($(date +%s --date 'now')-$(stat --format=%Y $openscap_result_file))/60/60/24))
else
        days_since_last_check=99999
fi

# cases of operating system update and openscap check status

if [ $days_since_last_update -gt $critical_days -o $days_since_last_check -gt $critical_days -o $openscap_check_count_passed -lt $openscap_check_count ]
then
        echo "CRITICAL: OS-Updates: $days_since_last_update days ago, OpenSCAP-Checks: $days_since_last_check days ago ( $openscap_check_count_passed of $openscap_check_count checks passed )"
        exit 2
fi

if [ $days_since_last_update -gt $warning_days -o $days_since_last_check -gt $warning_days ]
then
        echo "Warning: OS-Updates: $days_since_last_update days ago, OpenSCAP-Checks: $days_since_last_check days ago ( $openscap_check_count_passed of $openscap_check_count checks passed )"
        exit 1
fi

echo "OK: OS-Updates: $days_since_last_update days ago, OpenSCAP-Checks: $days_since_last_check days ago ( $openscap_check_count_passed of $openscap_check_count checks passed )"
exit 0

