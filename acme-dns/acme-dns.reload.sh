#!/bin/bash

SH_DIR=$(cd "$(dirname "$0")" && pwd)
# Print messages level: 0=Crit; 1=Error; 2=Warn; 3=Info; 4=Debug
PRINT_LEVEL=2

LOG="${SH_DIR}/acme-dns.log"

### Functions ###
# Print output
# https://svn.apache.org/repos/asf/commons/proper/logging/tags/LOGGING_1_0_3/usersguide.html
_print () {
  msg_lvl=$1
  shift
  if [ ${msg_lvl} -gt ${PRINT_LEVEL} ]; then return 0 ; fi
  # msg_type
  if [ ${msg_lvl} -eq 0 ]; then type="" ;
  elif [ ${msg_lvl} -eq 1 ]; then type=" ERROR:" ;
  elif [ ${msg_lvl} -eq 2 ]; then type=" WARN:" ;
  elif [ ${msg_lvl} -eq 3 ]; then type=" INFO:" ;
  elif [ ${msg_lvl} -eq 4 ]; then type=" DEBUG:" ;
  fi
  DATE_FORMAT="+'%Y-%m-%d %H:%M:%S %z'"
  dt=$(eval "date ${DATE_FORMAT}")
  echo "[$dt] $type $*"
}

_print 0 "--- ACME-DNS.Reload.sh ---" >> ${LOG}

cd "${HOME}/compose/nginx"
docker-compose exec nginx nginx -t >> ${LOG} \
 && docker-compose exec nginx nginx -s reload >> ${LOG} \
 && _print 0 "Nginx is reloaded" >> ${LOG}
# && docker-compose restart nginx >> ${LOG_FILE}

#echo "--- ACME-DNS.Reload.sh ---" >> ${LOG_FILE}
