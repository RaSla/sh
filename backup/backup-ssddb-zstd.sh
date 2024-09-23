#!/bin/bash

PG_HOST=10.134.21.145
PG_PORT=5432
PG_DB="ssd"
PG_USER="ssd"
opts="-h ${PG_HOST} -p ${PG_PORT}"
DUMP_DIR=./
DUMP_FNAME="ssddb"

_print () {
  DATE_FORMAT="+'%Y-%m-%d %H:%M:%S %z'"
  dt=$(eval "date ${DATE_FORMAT}")
  echo "[$dt] $type $*"
}

mkdir -p ${DUMP_DIR}
cd ${DUMP_DIR}
bdate=$(date +'%Y-%m-%d_%H%M%S')
fname=${DUMP_FNAME}_${bdate}.sql.zst
_print "*** Start pg_dump '${PG_DB}' -> ${fname}"
pg_dump --clean --if-exists ${opts} -U ${PG_USER} -d ${PG_DB} | zstd > ${fname}
_print "*** Finish pg_dump '${PG_DB}'"
ls -al $fname
