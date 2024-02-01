# nicer-bash-prompt:
# https://github.com/RaSLa/sh/ - by RaSLa (2020)
# fork of:
# https://github.com/RichVel/nicer-bash-prompt
# (C) 2013, RichVel @ github - license is BSD 2-Clause, http://opensource.org/licenses/BSD-2-Clause

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# CUSTOMIZE: Strip suffix for username & hostname for your servers
user=$(echo "$USER" | sed 's/@.*//')
host=${HOSTNAME%%.*}
# CUSTOMIZE mode: by Username & hostname prefixes for your servers
case "${user}" in
    root) sysmode=root;;
    *)    sysmode=user;;
esac
case "${host}" in
    NOTEBOOK-*) mode_color=green;;
    *-WSN-*) mode_color=green;;
    *)       mode_color=yellow;;
esac
if [ "$SIMULATE_ROOT" = "yes" ]; then
    sysmode=root
fi
if [ ! -z "$MODE_COLOR" ]; then
    mode_color=$MODE_COLOR
fi

# ======== History setup - optional ===============
#
# If you use this, must be called as part of per-prompt command (see CUSTOMIZE below to enable) - ensure that all terminals
# have same view of bash history, updated after every command.  Only enable this if you understand that cursor-up
# will sometimes be surprising on returning to a terminal window!
# history_sync: After every command, append latest commands to hist file, then clear shell history, and re-read all from file
history_sync() {
    history -a; history -c; history -r;
}
shopt -s histappend  # Append rather than overwrite

# ======== Prompt setup ===========================
#
# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Expand any symbolic links in the specified pathname and convert to absolute path
function realpath() {
    f=$@
    if [ -d "$f" ]; then
        base=""
        dir="$f"
    else
        base="/$(basename "$f")"
        dir=$(dirname "$f")
    fi

    dir=$(cd "$dir" && /bin/pwd)
    echo "$dir$base"
}

# Set prompt path to max 2 levels for best compromise of readability and usefulness
promptpath () {
    realpwd=$(realpath $PWD)          # Absolute path
    realhome=$(realpath $HOME)

    # if we are in the home directory, show tilde if possible
    if echo $realpwd | grep -q "^$realhome"; then
        path=$(echo $realpwd | sed "s|^$realhome|\~|")
        if [ "$path" = "~" ] || [ "$(dirname "$path")" = "~" ]; then
            echo $path
        else
            echo $(basename $(dirname "$path"))/$(basename "$path")
        fi
        return
    fi

    path_dir=$(dirname $PWD)
    # if our parent dir is a top-level directory, don't mangle it
    if [ $(dirname $path_dir) = "/" ]; then
        echo $PWD
    else
        path_parent=$(basename "$path_dir")
        path_base=$(basename "$PWD")

        echo $path_parent/$path_base
    fi
}


# Terminal colours - must use \[ and \] to tell readline about them, so bash line editing works
inverse="\[$(tput smso)\]"
uninverse="\[$(tput rmso)\]"
bold="\[$(tput bold)\]"
unbold="\[$(tput dim)\]"
reset="\[$(tput sgr0)\]"
black="$bold\[$(tput setaf 0)\]"
red="\[$(tput setaf 1)\]"
green="$bold\[$(tput setaf 2)\]"
blue="$bold\[$(tput setaf 4)\]"
magenta="$bold\[$(tput setaf 5)\]"
yellow="$bold\[$(tput setaf 3)\]"
cyan="$bold\[$(tput setaf 6)\]"

# Output bash prompt, run after every command - output of script is PS1 value, with all values expanded
function bash_prompt() {
    promptpath=$(promptpath)
    branch=""
    git branch >/dev/null 2>&1
    if [[ $? == 0 ]]; then
        branch=$(git branch 2>/dev/null | grep '^*' |  cut -d " " -f 2)
    fi

    specialpart="${user}@${host}"
    # Red prompt if root
    if [ $sysmode = 'root' ]; then
        prompt="$red$bold${specialpart} ${branch:+$cyan[$branch] }$blue${promptpath}$red#$black$reset "
    else
        prompt="${!mode_color}${specialpart} ${branch:+$cyan[$branch] }$blue${promptpath}\$$black$reset "
    fi

    #  CUSTOMIZE: if not using Debian/Ubuntu (or you never use chroot), use the first version of this line
    # prompt="$yellow${specialpart} ${branch:+$cyan[$branch] }$blue${promptpath}\$$black$reset "
    # prompt="${debian_chroot:+($debian_chroot)}${!mode_color}${specialpart} ${branch:+$green[$branch] }$blue${promptpath}\$$black$reset "
    echo -n "$prompt"
}

# Function called every time bash displays the prompt
function per_prompt_command {
    # Set the window title if a terminal window (Mac or Linux)
    if [ $sysmode = 'root' ]; then
        termtitle="[${USER}]: $PWD"
    else
        termtitle="[${user}]: $(promptpath)"
    fi
    case "$TERM" in
        xterm*|rxvt*)
            echo -ne "\033]0;"${termtitle}"\007"
            ;;
    esac
    # Do the prompt
    PS1="$(bash_prompt)"
    PS1="$PS1"

    # CUSTOMIZE: Uncomment this if you want to sync history on every prompt, across multiple windows (see above)
    # history_sync
}
export PROMPT_COMMAND=per_prompt_command
