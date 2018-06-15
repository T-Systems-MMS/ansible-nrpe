#!/bin/bash
#
# Usage: check_playbook_changes.yml <Jenkins-job root>
#
# All successful jobs in subdirectories will be checked for state changes.
# If the state has been changed, returns WARNING and a list of changed jobs.
# Returns ERROR, if a subdirectory for a job cannot be found in Jenkins folder.
#

JENKINS_HOME=/var/lib/jenkins

IFS=" "
runcheck=$(find ${JENKINS_HOME}/jobs/$1 -name lastSuccessfulBuild -type l -exec grep -Rl 'changed:' {} \; 2> /dev/null)
if [[ "$?" == 1 ]]; then
  echo ERROR - Wrong job name
  exit 2
fi

if [[ -z ${runcheck} ]]; then
  echo OK - No changes
  exit 0
else
  echo WARNING - Playbook run caused changes:
  echo ${runcheck} | grep '/log' | sed 's/\/var\/lib\/jenkins\/jobs\///' | sed 's/\/jobs//' | sed 's/\/builds\/lastSuccessfulBuild\/log//'
  exit 1
fi
