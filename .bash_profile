
# From https://github.com/halhen/dotfiles/blob/master/.bashrc
# Most of the alises here are from there
# Stop executing if this is not an interactive session.
[ -z "$PS1" ] && return

# Some commands differnet on OSX
if [[ $(uname) == "Darwin" ]]; then
    osx=true
    export PATH=$PATH:/Applications/scala-2-11-7/bin
    export PATH=$PATH:/usr/local/sbin
    export PATH=$PATH:/Users/user/bin

    export BYOBU_PREFIX=$(brew --prefix)

    export CLICOLOR=1

    # Setting memory use limits?
    ulimit -S -n 2048
else
    osx=false
fi

# Disable prompt, will set custom in PS1 below
export VIRTUAL_ENV_DISABLE_PROMPT=1

# ## Command entry {{{
# (Ben) Added brew for OSX use
# Use [bash completion](http://freshmeat.net/projects/bashcompletion), also with sudo completion.
if [[ $osx = true ]]; then
    . $(brew --prefix)/etc/bash_completion
else
    . /etc/bash_completion
fi
complete -cf sudo

# From https://www.reddit.com/r/linux/comments/zgqre/post_your_custom_ps1s/
NONE='\033[0m'     # unsets color to term's fg color
# dark colors
DK='\033[0;30m'    # black
DR='\033[0;31m'    # red
DG='\033[0;32m'    # green
DY='\033[0;33m'    # yellow
DB='\033[0;34m'    # blue
DM='\033[0;35m'    # magenta
DC='\033[0;36m'    # cyan
DW='\033[0;37m'    # white
# light colors
LK='\033[1;30m'    # black
LR='\033[1;31m'    # red
LG='\033[1;32m'    # green
LY='\033[1;33m'    # yellow
LB='\033[1;34m'    # blue
LM='\033[1;35m'    # magenta
LC='\033[1;36m'    # cyan
LW='\033[1;37m'    # white
# inverted dark colors
IDK='\033[0;40m'    # black
IDR='\033[0;41m'    # red
IDG='\033[0;42m'    # green
IDY='\033[0;43m'    # yellow
IDB='\033[0;44m'    # blue
IDM='\033[0;45m'    # magenta
IDC='\033[0;46m'    # cyan
IDW='\033[0;47m'    # white
# inverted light colors
ILK='\033[1;40m'    # black
ILR='\033[1;41m'    # red
ILG='\033[1;42m'    # green
ILY='\033[1;43m'    # yellow
ILB='\033[1;44m'    # blue
ILM='\033[1;45m'    # magenta
ILC='\033[1;46m'    # cyan
ILW='\033[1;47m'    # white
#VCS prompt
prompt_git() {
    git branch &>/dev/null || return 1
    HEAD="$(git symbolic-ref HEAD 2>/dev/null)"
    BRANCH="${HEAD##*/}"
    [[ -n "$(git status 2>/dev/null | \
        grep -E 'working (tree|directory) clean')" ]] || STATUS="*"
    printf '(git:%s)' "${BRANCH:-unknown}${STATUS}"
}
prompt_hg() {
    hg branch &>/dev/null || return 1
    BRANCH="$(hg branch 2>/dev/null)"
    [[ -n "$(hg status 2>/dev/null)" ]] && STATUS="*"
    printf '(hg:%s)' "${BRANCH:-unknown}${STATUS}"
}
prompt_svn() {
    svn info &>/dev/null || return 1
    URL="$(svn info 2>/dev/null | \
        awk -F': ' '$1 == "URL" {print $2}')"
    ROOT="$(svn info 2>/dev/null | \
        awk -F': ' '$1 == "Repository Root" {print $2}')"
    BRANCH=${URL/$ROOT}
    BRANCH=${BRANCH#/}
    BRANCH=${BRANCH#branches/}
    BRANCH=${BRANCH%%/*}
    [[ -n "$(svn status 2>/dev/null)" ]] && STATUS="*"
    printf '(svn:%s)' "${BRANCH:-unknown}${STATUS}"
}
prompt_vcs() {
    prompt_git || prompt_svn || prompt_hg
}
# from https://stackoverflow.com/questions/10406926/how-to-change-default-virtualenvwrapper-prompt
prompt_virtualenv(){
    # Get Virtual Env
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Strip out the path and just leave the env name
        venv="${VIRTUAL_ENV##*/}"
    else
        # In case you don't have one activated
        venv=''
    fi
    [[ -n "$venv" ]] && echo "($venv) "
}
# prompt
prompt_smiley() {
    if [[ $? -eq "0" ]]; then
        printf "$LG %s$NONE " ":)"
    else
        printf "$LR %s$NONE " ":("
    fi
}
prompt_host() {
    host=''
    [[ $SSH_TTY ]] && host="@\h"
    echo $host
}
user_color() {
    local UC=$LY
    [ $UID -eq "0" ] && UC=$LR
    printf "%s" "$UC"
}
# Path colour
PC=$DC
# Git colour
GC=$DM
export PS1="\$(prompt_smiley)$(user_color)\u$(prompt_host)$LW:$PC\w$GC\$(prompt_vcs)$NONE\$(prompt_virtualenv)\n \$ "
export PS2=" > "

# }}}

# ## Shell options {{{
# Correct minor spelling error when `cd`.
shopt -s cdspell

# Check and update window size after each command.
shopt -s checkwinsize

# }}}


# ## Aliases {{{
# Colorize `ls`.
if [[ $osx = true ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=always'
fi

# Show colors in less
alias less='less -R'

# Colorize `grep`.
export GREP_COLORS="1;33"
alias grep='grep --color=auto'

# Convenient `cd..`.
alias c="cd .."

# Never `rm` `/`.
if [[ $osx = false ]]; then
    alias rm="rm --preserve-root"
fi

# Set tmux to open "main" automatically
alias tat='if [[ -n "$VIRTUAL_ENV" ]]; then deactivate; fi && tmux new-session -A -s main'

# Open bash_profile and source after editing
alias bash-profile="vim $HOME/dotfiles/.bash_profile && source $HOME/dotfiles/.bash_profile"

# Update passwords store
alias pass-update='pass git remote update && pass git rebase origin/master'


# ## Functions {{{
# Make directories, cd into the first one
function md {
    mkdir -p "$@" && cd "$1"
}

# Search man pages for user commands
function k {
    man -k "$@" | grep '(1' --color=never
}

# Compress directory and delete after
function gz-dir {
    tar -zcf $1.tar.gz $1 && rm -r $1
}

# Parallel compress directory
function partar {
    [ -z "$2" ] && echo "nprocs not set" && return 1

    outname=${1%/}.tar.gz
    [ -f $outname ] &&  echo "$outname already exists" && return 1

    size=$(du -sk $1 | cut -f 1)
    tar -cf - $1 | pv -N $1 -perts ${size}k | pigz -6 -p $2 > $outname
}


# Tar a directory
function dirtar {
    outname=${1%/}.tar
    [ -f $outname ] &&  echo "$outname already exists" && return 1

    size=$(du -sk $1 | cut -f 1)
    tar -cf - $1 | pv -N $1 -perts ${size}k > $outname
}


# ### cd improvements {{{
# Use pushd to preserve history. `cdm` displays a menu of previous dirs,
# Adapted from Pro Bash Programming - ISBN 978-1430219989

# cd with history - i.e. pushd
function cd {
    local dir error

    while :; do # No support for options, consume them
        case $1 in
            --) break ;;
            -*) shift ;;
            *) break ;;
        esac
    done

    dir=${1:-$HOME}

    pushd "$dir" 2>/dev/null
    error=$?

    [[ $error != 0 ]] && builtin cd "$dir"
    return "$error"
} >/dev/null

# cd by menu, with previous directories as options
function cdm {
    local dir IFS=$'\n' item n

    for dir in $(dirs -p); do
        [[ "$dir" = "${PWD//$HOME/~}" ]] && continue
        [[ ${item[*]} = *"$dir "* ]] && continue

        item+=( "$dir " )
        [[ ++n -ge 10 ]] && break
    done

    [[ -z "${item[@]}" ]] && return
    echo
    select i in "${item[@]}"; do
        if [[ "$i" ]]; then
            cd "${i//\~/$HOME}"
            return $?
        fi
    done
}

# Written (probably badly) by Ben
function last-dir {
    for dir in $(dirs -p | uniq | tail -n +2); do
        [[ "$dir" = "${PWD//$HOME/~}" ]] && continue
        break
    done

    cd "${dir//\~/$HOME}"
}

# Easier navigation: .., ..., ...., ....., ~ and -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~='cd ~'
# Sets - to go to last dir
alias -- -="last-dir"

# }}}
# }}}

# The next line updates PATH for the Google Cloud SDK.
if [ -f ~/google-cloud-sdk/path.bash.inc ]; then source ~/google-cloud-sdk/path.bash.inc; fi

# The next line enables shell command completion for gcloud.
if [ -f ~/google-cloud-sdk/completion.bash.inc ]; then source ~/google-cloud-sdk/completion.bash.inc; fi

