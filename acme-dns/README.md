# acme-dns.sh
Wrapper for ACME.SH (https://github.com/Neilpang/acme.sh)

Use *DNS-check* for Issue SSL-certificates.

## Install
Download acme-dns.sh and make it executable.

## Usage
```console
$ wget https://raw.githubusercontent.com/RaSla/sh/main/acme-dns/acme-dns.sh
$ chmod 755 acme-dns.sh

$ ./acme-dns.sh
   1) Install ACME.SH
 # wget -O -  https://get.acme.sh | sh
   2) Make stricted user for DNS:
 # https://github.com/Neilpang/acme.sh/wiki/How-to-use-Amazon-Route53-API
   3) Configure ACME.SH
 # https://github.com/Neilpang/acme.sh/tree/master/dnsapi
 # nano /home/rasla/acme-dns.sh.env
 export  DNS_PLUGIN="dns_aws"
 export  AWS_ACCESS_KEY_ID="XXXXXXXX"
 export  AWS_SECRET_ACCESS_KEY="XXXXXXXXX"
 export  RELOAD_CMD="service nginx force-reload"
 # Print messages level: 0= Crit; 1= Error; 2=Warn; 3= Info; 4= Debug
 export  PRINT_LEVEL=3

   4) Issue cert. For example:
 # ./acme-dns.sh issue [--ec] abc.xyz '*.abc.xyz'
   will issue [ECDSA] cert for 'abc.xyz, *.abc.xyz'
   See full help for 'issue' command:
 # ./acme-dns.sh issue
   5) Configure Nginx. For example:
 # nano /etc/nginx/sites-available/abc.xyz
  ssl_certificate_key     /etc/letsencrypt/live/abc.xyz/privkey.pem;
  ssl_certificate         /etc/letsencrypt/live/abc.xyz/fullchain.pem;

   6) Renew all Certs
  No, you don't need to renew the certs manually! :-)
  All the certs will be renewed automatically every 60 days.
   7) Upgrade ACME.SH
 # acme.sh --upgrade
```
