#!/bin/bash
# checking certificate expire date

###############################################################################################################################################
#+++ configuration                                                                                                                            #
###############################################################################################################################################

CERT=$1
d_warn="60"
d_crit="30"
date_format="+%Y%m%d"
OPENSSL=/usr/bin/openssl
##############################################################################################################################################
#+++ functions                                                                                                                               #
##############################################################################################################################################

function check_cert () {

 date_now=`date "$date_format"`
 date_warn=`date "$date_format" -d "today +${d_warn} day"`
 date_crit=`date "$date_format" -d "today +${d_crit} day"`

 if [ ! -r $CERT ]; then
        nagios_warn "Zertifikat ${CERT} nicht lesbar."
 fi

 expire_date_raw_out=`$OPENSSL x509 -noout -in ${CERT} -dates | grep "notAfter" | cut -d '=' -f2 | awk '{print $1,$2,$3,$4}'`
 expire_date=`date -d "$expire_date_raw_out" "$date_format"`

 if [ "$date_crit" -gt "$expire_date"  ]; then
        nagios_crit "Zertifikat laeft in weniger als ${d_crit} Tagen ab! expireDate=$expire_date"

 elif [ "$date_warn" -gt "$expire_date"  ]; then
        nagios_warn "Zertifikat laeft in weniger als ${d_warn} Tagen ab! expireDate=$expire_date"

 else
        nagios_ok "Zertifikat ist gueltig. expireDate=$expire_date"

 fi

}

###############################################################################################################################################
#+++ nagios functions                                                                                                                         #
###############################################################################################################################################

nagios_ok () {
        echo $@
        exit 0
}
nagios_warn () {
        echo $@
        exit 1
}
nagios_crit () {
        echo $@
        exit 2
}

###############################################################################################################################################
#+++ run proc                                                                                                                                 #
###############################################################################################################################################

check_cert;

