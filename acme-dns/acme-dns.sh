#!/bin/sh
#
SH_DIR=$(cd "$(dirname "$0")" && pwd)
echo "SH_DIR = $SH_DIR"
NAME="acme-dns.sh"
DESCRIPTION="Wrapper for ACME.SH (https://github.com/Neilpang/acme.sh)"
VERSION=5
# Print messages level: 0= Crit; 1= Error; 2=Warn; 3= Info; 4= Debug
PRINT_LEVEL=2
## Using vars from .env file
DNS_PLUGIN=""
RELOAD_CMD=""

help_v () {
  echo "VERSION: $NAME v$VERSION - $DESCRIPTION"
  echo "USAGE: $NAME <COMMAND> [<ARGUMENT-1> ... <ARGUMENT-LAST>]"
}

help_issue () {
  echo "* (i) issue [--dry] [ECDSA-TYPE] <DOMAIN> [<ANOTHER_DOMAIN>] == Issue SSL-cert"
  echo "   |- --dry - Dry-run: only print final shell-cmd without execution of it"
  echo "   |- <ECDSA-TYPE> - [Optional] EC-Type for generating ECDSA SSL-cert:"
  echo "    < --ec | --ec-256 | --ec-384 | --ec-521 >, otherwise RSA is used"
  echo "   |- <DOMAIN> - First Domain-name for SSL-cert"
  echo "   |- <ANOTHER_DOMAINS> - [Optional] Additional domain-names for SSL-cert WITHOUT wildcard-subdomains:"
  echo "      Certificate will be issued for domain-names: '<DOMAIN>, *.<DOMAIN>, <ANOTHER_DOMAINS>'"
}

help_manual () {
  echo "* (man) manual == Show install- & usage- instructions"
  echo "   1) Install ACME.SH"
  echo " # wget -O -  https://get.acme.sh | sh"
  echo "   2) Make stricted user for DNS:"
  echo " # https://github.com/Neilpang/acme.sh/wiki/How-to-use-Amazon-Route53-API"
  echo "   3) Configure ACME.SH"
  echo " # https://github.com/Neilpang/acme.sh/tree/master/dnsapi"
  echo " # nano $0.env"
  echo ' export  DNS_PLUGIN="dns_aws"'
  echo ' export  AWS_ACCESS_KEY_ID="XXXXXXXX"'
  echo ' export  AWS_SECRET_ACCESS_KEY="XXXXXXXXX"'
  echo ' export  RELOAD_CMD="service nginx force-reload"'
  echo ' # Print messages level: 0= Crit; 1= Error; 2=Warn; 3= Info; 4= Debug'
  echo ' export  PRINT_LEVEL=3'
  echo "   4) Issue cert. For example:"
  echo " # ./$NAME issue [--ec] abc.xyz '*.abc.xyz'"
  echo "   will issue [ECDSA] cert for 'abc.xyz, *.abc.xyz'"
  echo "   See full help for 'issue' command:"
  echo " # ./$NAME issue"
  echo "   5) Configure Nginx. For example:"
  echo " # nano /etc/nginx/sites-available/abc.xyz"
  echo "  ssl_certificate_key     /etc/letsencrypt/live/abc.xyz/privkey.pem;"
  echo "  ssl_certificate         /etc/letsencrypt/live/abc.xyz/fullchain.pem;"
  echo ""
  echo "   6) Renew all Certs"
  echo "  No, you don't need to renew the certs manually! :-)"
  echo "  All the certs will be renewed automatically every 60 days."
  echo "   7) Upgrade ACME.SH"
  echo " # acme.sh --upgrade "
}

help_all () {
  help_v
  echo "COMMAND choose one of those:"
  help_issue
  help_manual
}

# Simple commands check
if [ -z "$1" ]; then
  help_all
  exit 0
elif [ "$1" = "--help" ]; then
  help_all
  exit 0
elif [ "$1" = "--version" ]; then
  help_v
  exit 0
fi

# Load parameters
if [ -f "$0.env" ]; then
  # shellcheck source=acme-dns.sh.env
  . "$0.env"
else
  echo "WARN: Config for API-access '$0.env' is absent !!!"
  exit 0
fi

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

# Issue certificate
issue_cert () {
    _print 3 "issue_cert: '$*'; USER=${USER}"
    domain=""
    domains=""
    dry_run=""
    ecc=""
    # loop for prepare domains-list as args for ACME.SH
    for item in "$@"
    do
      # [BASH]
      # first_letter=${item:0:1}
      first_letter=$(echo "${item}" | cut -c1-1)
      #_print 4 "first_letter = ${first_letter}"
      if [ "${first_letter}" != "-" ]; then
        domains="${domains} -d '${item}'";
        if [ -z "$domain" ]; then domain="${item}"; fi
      else
        if [ "$item" = "--dry" ]; then dry_run=" --dry-run";
        elif [ "$item" = "--ec" ]; then ecc=" --keylength ec-384";
        elif [ "$item" = "--ec-256" ]; then ecc=" --keylength ec-256";
        elif [ "$item" = "--ec-384" ]; then ecc=" --keylength ec-384";
        elif [ "$item" = "--ec-521" ]; then ecc=" --keylength ec-521";
        fi
      fi
    done
    # 'domain' must contain at least 1 name
    _print 4 "issue_cert: ecc='${ecc}', dry_run='${dry_run}' domains = ${domains}"
    if [ -z "$domains" ]; then
      help_issue;
      exit 1;
    fi
    # User check - setup CERTS_DIR
    if [ "${USER}" = "root" ]; then
      CERTS_DIR=/etc/letsencrypt/live ;
    else
      CERTS_DIR=~/letsencrypt/live ;
    fi
    # cert dir
    if [ -z "${ecc}" ]; then
      CERT_DIR="${CERTS_DIR}/${domain}";
    else
      CERT_DIR="${CERTS_DIR}/${domain}_ecc";
    fi
    _print 4 "CERT_DIR = $CERT_DIR"
    mkdir -p "${CERT_DIR}"
    chmod 700 ${CERTS_DIR}
    #
    cmd="~/.acme.sh/acme.sh --issue --dns ${DNS_PLUGIN} ${ecc} ${domains} \
     --cert-file ${CERT_DIR}/cert.pem \
     --ca-file ${CERT_DIR}/chain.pem \
     --fullchain-file ${CERT_DIR}/fullchain.pem \
     --key-file  ${CERT_DIR}/privkey.pem \
     --reloadcmd \"${RELOAD_CMD}\""
    _print 3 "${cmd}"
    if [ -z "${dry_run}" ]; then
      _print 4 "issue_cert: BEGIN"
      eval "${cmd}"
      _print 4 "issue_cert: DONE";
    fi
}

### ARGUMENTS PARSER ###
# var for General Command
gcmd="$1"
# Shift params for 1 step
shift
if [ "$gcmd" = "i" ]; then gcmd="issue"
#elif [ "$gcmd" = "-" ]; then gcmd="revoke"
fi

case "$gcmd" in
  issue )
    if [ -z "$1" ]; then
      help_issue;
      exit 1;
    fi
    issue_cert $@
    ;;
  debug_test )
    _print 0 "0 Mandatory Text"
    _print 1 "1 Error Text"
    _print 2 "2 Warn Text"
    _print 3 "3 Info Text"
    _print 4 "4 Debug Text"
    ;;
  *)
    help_all
    ;;
esac
