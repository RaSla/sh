#!/usr/bin/env bash

NAME="install-kubectl.sh"
DESCRIPTION="Install kubectl"
VERSION=1
# Print messages level: 0= Crit; 1= Error; 2=Warn; 3= Info; 4= Debug
PRINT_LEVEL=3

set -e

help_v () {
  echo "VERSION: $NAME v$VERSION - $DESCRIPTION"
  echo "USAGE: $NAME [<K8S_VERSION>]"
}

help_kubectl_by_apt () {
  echo "* (k_apt) kubectl_by_apt [K8S_VERSION] == Install 'kubectl' by APT"
  echo "   |- <K8S_VERSION> - [Optional] define kubectl version:"
  echo "     < last | '1.20.3-00' >"
}
help_kubectl_by_curl () {
  echo "* (k_curl) kubectl_by_curl [K8S_VERSION] == Install 'kubectl' by CURL"
  echo "   |- <K8S_VERSION> - [Optional] define kubectl version:"
  echo "     < last | 'v1.20.3' >"
}
help_kubectl_completion_bash () {
  echo "* (k_bash) kubectl_completion_bash == Make 'kubectl' completion for BASH"
}

help_all () {
  help_v
  echo "COMMAND choose one of those:"
  help_kubectl_by_apt
  help_kubectl_by_curl
  help_kubectl_completion_bash
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

is_root () {
  # Check UserID
  if [ $UID != "0" ]; then
    _print 1 "You MUST run this script with ROOT-privileges:  sudo $0 ..."
    exit 1
  fi
}

# Make BASH-completion: /etc/bash_completion.d/kubectl
kubectl_completion_bash () {
  _print 3 "Make BASH-completion: /etc/bash_completion.d/kubectl"
  whereis kubectl
  is_root
  mkdir -p /etc/bash_completion.d
  cmd="kubectl completion bash > /etc/bash_completion.d/kubectl"
  _print 4 "$cmd"
  eval "$cmd"
}

kubectl_by_apt () {
  # $1 = '1.20.3-00'
  _print 4 "$1"
  if [ "$1" = "last" ]; then
    version="";
  else
    version="=$1";
  fi

  ## [Debian] apt install gnupg2 software-properties-common
  is_root
  cmd="apt-get -y install apt-transport-https software-properties-common"
  _print 4 "$cmd"
  eval "$cmd"
  ## Get GPG-key for kubernetes apt-repo
  #curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
  wget -O - https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
  _print 3 "Add APT-REPO 'apt.kubernetes.io'"
  apt-add-repository 'deb http://apt.kubernetes.io/ kubernetes-xenial main'
  _print 3 "APT-GET UPDATE"
  apt-get update

  ## Install kubectl
  apt-mark unhold kubectl
  cmd="apt install kubectl$version"
  _print 4 "$cmd"
  eval "$cmd"
  apt-mark hold kubectl
  kubectl_completion_bash
}

kubectl_by_curl () {
  # $1 = 'v1.20.3'
  _print 4 "$1"
  version="$1"
  cmd="curl -LO https://storage.googleapis.com/kubernetes-release/release/${version}/bin/$(uname | awk '{print tolower($0)}')/amd64/kubectl"
  _print 4 "$cmd"
  eval "$cmd"
  chmod +x ./kubectl
  is_root
  mv ./kubectl /usr/local/bin/kubectl
  kubectl_completion_bash
}

### MAIN PARSER ###
# var for General Command
gcmd="$1"
# Shift params for 1 step
shift
if [ "$gcmd" = "k_apt" ]; then gcmd="kubectl_by_apt"
elif [ "$gcmd" = "k_bash" ]; then gcmd="kubectl_completion_bash"
elif [ "$gcmd" = "k_curl" ]; then gcmd="kubectl_by_curl"
fi

case "$gcmd" in
  kubectl_by_apt )
    if [ -z "$1" ]; then
      # last
      version="last"
    else
      # '1.20.3-00'
      version="$1"
    fi
    _print 3 "kubectl version=$version"
    kubectl_by_apt "$version"
    ;;
  kubectl_by_curl )
    if [ -z "$1" ]; then
      # last
      cmd="curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt"
      version=$(eval "$cmd")
    else
      # 'v1.20.3'
      version="$1"
    fi
    _print 3 "kubectl version=$version"
    kubectl_by_curl "$version"
    ;;
  kubectl_completion_bash )
    kubectl_completion_bash
    ;;
  *)
    help_all
    ;;
esac
