#!/bin/bash

PG_HOST=10.134.21.145
PG_PORT=5432
PG_DB="ssd"
PG_USER="ssd"
opts="-h ${PG_HOST} -p ${PG_PORT}"
DUMP_DIR=./
DUMP_FNAME=$1

_print () {
  DATE_FORMAT="+'%Y-%m-%d %H:%M:%S %z'"
  dt=$(eval "date ${DATE_FORMAT}")
  echo "[$dt] $type $*"
}

# Simple commands check
if [ -z "$1" ]; then
  echo "ERROR:  Define SQL.GZ dump-file as Argument #1 !  Example:"
  echo "$0  ssddb_2024-03-05_150116.sql.gz"
  exit 0
fi

set -e

cd ${DUMP_DIR}
_print "*** Start pg_restore '${PG_DB}' from '${DUMP_FNAME}'"
#pg_dump --clean --if-exists ${opts} -U ${PG_USER} -d ${PG_DB} | gzip > ${DUMP_FNAME}_${bdate}.sql.gz
zcat $DUMP_FNAME | psql -h $PG_HOST -p $PG_PORT -d $PG_DB -U $PG_USER
_print "*** Finish pg_restore '${PG_DB}'"

#_print "RECOMMENDATION: time vacuumdb -h $PG_HOST -p $PG_PORT --all --full --analyze -U \$DB_ADMIN"
_print "*** Start vacuumdb '${PG_DB}'"
vacuumdb -h $PG_HOST -p $PG_PORT --full --analyze -d $PG_DB -U $PG_USER
_print "*** Finish vacuumdb '${PG_DB}'"
