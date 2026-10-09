#!/usr/bin/env bash

NAME="devops.sh"
DESCRIPTION="DevOps tool for recent actions"
VERSION=1
# cd ~ && ln -sf ~/git/_ra/sh/devops.sh ~/devops.sh
SH_DIR=$(cd "$(dirname "$0")" && pwd)

# Print messages level: 0=Crit; 1=Error; 2=Warn; 3=Info; 4=Debug
PRINT_LEVEL=2

DEFAULT_ENV="dev"
# Project vars
DOCKER_IMAGES_LIST="alpine:latest busybox:latest"
GIT_DIR="${HOME}/git"
ANSIBLE_DIR="${GIT_DIR}/ansible"
GIT_REPOS_LIST="ansible k8s-config
 au-formula au-front"
# GitLab-CI runner
GITLAB_RUNNER_IMAGE="gitlab/gitlab-runner:alpine"
GITLAB_RUNNER_NAME="gitlab-runner"
GITLAB_RUNNER_CONFIG_DIR="/srv/gitlab-runner/config"
GITLAB_RUNNER_REGISTER_PARAMS=""
# LOG - log-file
LOG="${GIT_DIR}/devops.log"

# Load parameters and rewrite defaults
if [ -f "$0.env" ]; then
  # shellcheck source=devops.sh.env
  . "$0.env"
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
  elif [ ${msg_lvl} 04-as52te-ift   pd04-as52te-ift   04-as52te-ift-user-eq 1 ]; then type=" ERROR:" ;
  elif [ ${msg_lvl} -eq 2 ]; then type=" WARN:" ;
  elif [ ${msg_lvl} -eq 3 ]; then type=" INFO:" ;
  elif [ ${msg_lvl} -eq 4 ]; then type=" DEBUG:" ;
  fi
  DATE_FORMAT="+'%Y-%m-%d %H:%M:%S %z'"
  dt=$(eval "date ${DATE_FORMAT}")
  echo "[$dt] $type $*"
}

# Get current date & time
# cur_date=$(get_date)
# cur_date=$(get_date "10 minute ago")
get_date () {
  # '2018-10-08 10:49:28 +0500'
  DATE_FORMAT="+'%Y-%m-%d %H:%M:%S %z'"
  # ISO 8601
  # date +'%Y-%m-%dT%H:%M:%S%z'
  # '2018-10-08T10:49:28+0500'
  # date -u +'%Y-%m-%dT%H:%M:%SZ'
  # '2018-10-08T05:49:28Z'
  if [ -z "$1" ]; then
    cmd="date ${DATE_FORMAT}";
  else
    cmd="date -d '$@' ${DATE_FORMAT}";
  fi
  eval "${cmd}"
}

help_ansible_playbook () {
  echo "* (ap) ansible_playbook  == DevOps tools for ansible-playbook:"
  echo "   |- ping <COMPONENT> [<ENV>] - Run 'ansible -i inventory/<ENV> -m ping <COMPONENT>' "
  echo ""
  echo "   -- <ENV> choose one of those:"
  echo "    < enersys | hetzner > default is '$DEFAULT_ENV'"
}

help_git () {
  echo "* (g) git     == DevOps tools for Git:"
  echo "   |- (b)  branches - Show current branches for all Project Git-repos"
  echo "   |- (p)  pull  <REPO> - Pull  Git-repo <REPO>"
  echo "   |- (pa) pull_all - Pull all Git-repos for Project"
}

help_gitlab_runner () {
  echo "* (glr) gitlab_runner     == DevOps tools for Gitlab:"
  echo "   |- (i) install - Install and Register GitLab-Runner"
  echo "   |- (+) start - Start GitLab-Runner"
  echo "   |- (-) stop  - Stop  GitLab-Runner"
}

help_docker () {
  echo "* (d) docker  == DevOps tools for Docker:"
  echo "   |- (c)  clean - Delete DANGLING containers and images from localhost"
  echo "   |- (cl) clean_list - List DANGLING containers"
  echo "   |- (i)  images [<SERVICE>] - List docker-images [with <SERVICE>]"
  echo "   |- (pb) pull_base - Pull base docker-images for Project"
}

help_date () {
  echo "* date [<DATETIME>]  ==  Show DateTime (in log-format)"
  echo "   |- <DATETIME> - optional 'date -d' parameter:"
  echo "   ~/$NAME date"
  echo "  2018-10-08 10:58:03 +0500"
  echo "   ~/$NAME date '10 minute ago'"
  echo "  2018-10-08 10:48:03 +0500"
  echo "   ~/$NAME date '1 day 1 hour ago'"
  echo "  2018-10-09 09:58:03 +0500"
  echo "   ~/$NAME date 'next fri'"
  echo "  2018-10-12 00:00:00 +0500"
}

help_v () {
  echo "VERSION: $NAME v$VERSION - ${DESCRIPTION}"
  if [ -f "$0.env" ]; then
    # shellcheck source=acme-dns.sh.env
    echo "CONFIG: Config file '$0.env' is loaded !!!"
  else
    echo "WARN: Config file '$0.env' is absent !!!"
    exit 0
  fi
  echo "USAGE: $NAME <COMMAND> [<ARGUMENT-1> ... <ARGUMENT-LAST>]"
}

help_all () {
  help_v
  echo "COMMAND choose one of those:"
  help_ansible_playbook
  help_docker
  help_git
  help_gitlab_runner
  help_date
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

# log Message
log_msg () {
  dt=$(date "+%Y-%m-%d %H-%M-%S")
  echo "$dt: $1" >> "$LOG"
}

### Eval CMD with print of Cmd
cmd () {
  if [ -n "$1" ]; then
    echo "* EXEC: '$1'"
    eval "$1"
  else
    echo "Can't EXEC: empty CMD"
    exit 1
  fi
}

###  CONVERTER ServiceName TO GitRepo-Name  ###
# an="router"; echo "'$an' => $(sname_to_gitrepo $an)"
# echo $(sname_to_gitrepo ${service})
sname_to_gitrepo () {
  if [ "$1" = "k8s-setup" ]; then echo "k8s-setup"
  elif [ "$1" = "k8s-config" ]; then echo "k8s-config"
  elif [ "$1" = "ies-k8s-config" ]; then echo "ies-k8s-config"
  elif [ "$1" = "logstash" ]; then echo "logstash"
  else echo "ms-$1"
  fi
}

### Ansible functions ###
# ansible_ping "$a_env" "$a_service"
ansible_ping () {
  a_env="$1"
  a_component="$2"
  if [ "${a_component}" = "" ]; then a_component="all" ; fi

  get_date
  cd "${ANSIBLE_DIR}" || exit
# $ ansible -i inventory/test -m ping all
#  cmd "time ansible -i inventory/$a_env -m $a_action $a_component"
# $ ansible -i inventory/test -m shell -a 'uname -a; uptime' content
  cmd "ansible -i inventory/${a_env} -m shell -a 'uname -a; uptime' ${a_component}"
}

### DOCKER functions ###
d_clean_list () {
  echo " *** List DANGLING containers ***"
  docker images --filter "dangling=true" || true
}

d_clean () {
  _print 3 " *** Delete DANGLING containers, images and volumes ***"
  docker container prune -f ;  docker image prune -f ; docker volume prune -f
  log_msg "Docker clean 'dangling' Done"
}

d_images () {
  if [ -z "$1" ]; then
    echo "---====  Docker-Images | head 45  ====---"
    docker images | head -n 45
  else
    echo "---====  Docker-Images | grep '$1'  ====---"
    docker images | grep "$1"
  fi
}

d_pull_base_images () {
  echo " *** Pulling ALL base images ***"
  for var in ${DOCKER_IMAGES_LIST}
  do
    _print 3 "--- Docker pull  ${var}"
    docker pull "${var}"
  done
}

### GIT functions ###
git_branch () {
  w_dir="$GIT_DIR/$1"
  cd "${w_dir}" || exit
  gb=$(git branch | grep '* ')
  echo "--- git '$1' (${gb}) ---"
}

git_branches_all () {
  echo " *** GIT Show current branches for Project-repos ***"
  for var in ${GIT_REPOS_LIST}
  do
    git_branch "${var}"
  done
}

git_pull () {
  echo " "
  _print 3 "--- git pull: $1 ---"
  wdir="${GIT_DIR}/$1"
  mkdir -p "$wdir"
  cd "$wdir" || exit
  pwd
  git branch | grep '* '
  git pull
}

git_pull_all () {
  echo " *** GIT Pulling all Project-repos ***"
  for var in ${GIT_REPOS_LIST}
  do
    git_pull "${var}"
  done
}

### GitLab functions ###
gitlab_runner_stop () {
  _print 3 "Stopping GitLab-CI runner..."
  docker stop ${GITLAB_RUNNER_NAME} && docker rm ${GITLAB_RUNNER_NAME}
}

gitlab_runner_start () {
  _print 3 "Starting GitLab-CI runner..."
  docker run -d --name ${GITLAB_RUNNER_NAME} --restart always \
    -v ${GITLAB_RUNNER_CONFIG_DIR}:/etc/gitlab-runner \
    -v /var/run/docker.sock:/var/run/docker.sock \
    ${GITLAB_RUNNER_IMAGE}
}

gitlab_runner_update () {
  _print 3 "* Updating GitLab-CI runner docker-image"
  docker pull ${GITLAB_RUNNER_IMAGE}
}

gitlab_runner_install () {
  echo " *** Create gitlab-runner config-dir ***"
  sudo mkdir -p ${GITLAB_RUNNER_CONFIG_DIR}
  sudo chmod 777 ${GITLAB_RUNNER_CONFIG_DIR}
  gitlab_runner_update
  gitlab_runner_stop
  sudo mv -f ${GITLAB_RUNNER_CONFIG_DIR}/config.toml ${GITLAB_RUNNER_CONFIG_DIR}/config.toml.previous
  gitlab_runner_start
  echo " *** Register gitlab-runner ***"
#  docker run --rm -t -i -v ${GITLAB_RUNNER_CONFIG_DIR}:/etc/gitlab-runner ${GITLAB_RUNNER_IMAGE} register
  cmd="docker run --rm -it \
    -v ${GITLAB_RUNNER_CONFIG_DIR}:/etc/gitlab-runner -v /var/run/docker.sock:/var/run/docker.sock \
    ${GITLAB_RUNNER_IMAGE} register ${GITLAB_RUNNER_REGISTER_PARAMS}"
  _print 3 "$cmd"
  eval "$cmd"
}

### --MAIN-- ARGUMENTS PARSER ###
# var for General Command
gcmd="$1"
# Shift params for 1 step
shift
if [ "$gcmd" = "ap" ]; then gcmd="ansible_playbook"
elif [ "$gcmd" = "d" ]; then gcmd="docker"
elif [ "$gcmd" = "g" ]; then gcmd="git"
elif [ "$gcmd" = "glr" ]; then gcmd="gitlab_runner"
elif [ "$gcmd" = "l" ]; then gcmd="log"
fi

case "$gcmd" in
  ansible_playbook )
    cmd=$1
    if [ "$1" = "d" ]; then cmd="deploy"
    elif [ "$1" = "n" ]; then cmd="new"
    fi

    case "$cmd" in
      ping )
        # Shift params for 1 step
        shift
        a_service=$1
        a_env=$2

        if [ -z "$1" ]; then
          a_env="all"
        fi

        if [ -z "$2" ]; then
          a_env="$DEFAULT_ENV"
        fi

        ansible_ping "$a_env" "$a_service"
        ;;
      *)
        help_ansible_playbook
        ;;
    esac
    ;;

  docker )
    cmd=$1
    if [ "$1" = "c" ]; then cmd="clean"
    elif [ "$1" = "cl" ]; then cmd="clean_list"
    elif [ "$1" = "i" ]; then cmd="images"
    elif [ "$1" = "pb" ]; then cmd="pull_base"
    fi
    case "$cmd" in
      clean )
        d_clean
        ;;
      clean_list )
        d_clean_list
        ;;
      images )
        d_images "$2"
        ;;
      pull_base )
        d_pull_base_images
        ;;
      *)
        help_docker
        ;;
    esac
    ;;

  git )
    cmd=$1
    if [ "$1" = "b" ]; then cmd="branches"
    elif [ "$1" = "p" ]; then cmd="pull"
    elif [ "$1" = "pa" ]; then cmd="pull_all"
    fi

    case "$cmd" in
      branches )
        git_branches_all
        ;;
      pull )
        git_pull "$2"
        ;;
      pull_all )
        git_pull_all
        ;;
      *)
        help_git
        ;;
    esac
    ;;

  gitlab_runner )
    cmd=$1
    if [ "$1" = "i" ]; then cmd="install"
    elif [ "$1" = "+" ]; then cmd="start"
    elif [ "$1" = "-" ]; then cmd="stop"
    fi

    case "$cmd" in
      install )
        gitlab_runner_install
        ;;
      start )
        gitlab_runner_start
        ;;
      stop )
        gitlab_runner_stop
        ;;
      *)
        help_gitlab_runner
        ;;
    esac
    ;;

  date )
    get_date "$@"
    ;;

  *)
    help_all
    ;;
esac
