#!/usr/bin/env zsh

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

############
## Setops
############

setopt correct correctall # Enables spelling correction for commands that are mistyped and for all arguments in a command.
setopt extendedglob nocaseglob rcexpandparam numericglobsort # Enables advanced pattern matching operators, such as '!' for negation and '|' for alternation. Matches file names case-insensitively when using glob patterns. Expands parameters inside of single quotes. Sorts file names in numerical order rather than lexicographical order.
setopt appendhistory histignorealldups inc_append_history histignorespace hist_save_no_dups hist_reduce_blanks # Appends new commands to the existing history file. Ignores duplicate commands in the history file. Writes each command to the history file as it is executed, rather than only on exit. Ignores commands starting with a space character in the history file. Saves only the most recent instance of a duplicated command in the history file, and Removes extra blank lines from the history file.
setopt aliases autocd # Enables the use of aliases, which are shorthand commands or command sequences. Changes to a directory if the input provided is a valid directory path.

################################
## Completion options & cache
################################

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

#############
## History
#############

HISTORY=(~/.zhistory)
SIZE=(100)
HISTFILE="${HISTORY}"
HISTSIZE="${SIZE}"
SAVEHIST="${SIZE}"
WORDCHARS=${WORDCHARS//\/[&.;]}

#################
## Keybindings
#################

bindkey -e
bindkey '^[[3~' delete-char
bindkey '^[[C'  forward-char
bindkey '^[[D'  backward-char
bindkey '^[[5~' history-beginning-search-backward
bindkey '^[[6~' history-beginning-search-forward
bindkey '^[Oc' forward-word ; bindkey '^[[1;5C' forward-word
bindkey '^H' backward-kill-word

###########
## Alias
###########

# Rewrites
alias cp="cp -i" ## Enable color
alias df='df -h' ## Human readable output
alias free='free -m' ## Show output in medibytes
alias vim="vim -f" ## Force vim into the current window
alias ls='ls --color=auto' ## Force ls to use colors
eval "$(thefuck --alias)" ## Add 'the fuck' alias

# Color aliases
declare -r WHITE="\033[0m"
declare -r RED="\033[31m"
declare -r GREEN="\033[32m"
declare -r BLUE="\033[34m"
declare -r CYAN="\033[36m"
declare -r YELLOW="\033[33m"
declare -r MAGENTA="\033[35m"

# Single letter aliases
alias c="clear" ## Clear the current terminal
alias q="exit" ## Exit the current shell
alias z="zcompile ~/.zshrc ; notify-send '.zshrc recompiled'" ## Recompile zsh as a binary source

#############
## Theming
#############

autoload -Uz compinit && compinit -u ## Autoload all zsh functions
export LESS_TERMCAP_us=$'\E[01;36m'
export LESS=-R
zmodload zsh/terminfo

#############################
## Builtin hook over rides
#############################

## Offer to install missing package if command is not found 
if [[ -r /usr/share/zsh/functions/command-not-found.zsh ]]; then
  source /usr/share/zsh/functions/command-not-found.zsh ; export PKGFILE_PROMPT_INSTALL_MISSING=1
fi

## When a command fails in the home dir reroute the output to fuck unless cmd not found, then reroute to chatgpt. If it fails in any other dir run thefuck
function precmd() {
  case "${PWD}" in 
    "${HOME}")
      case "${?}" in 
        0) ;;
        1) fuck ;;
        *)
          clear
          tgpt "$(tail -n1 "${HISTORY}")"
          ;;
      esac ;;
    *)
      case "${?}" in
        0) ;;
        *) fuck ;;
      esac ;;
  esac
}

## When the dir is changed recieve a [y/n] prompt listing the total number of files in the dir and offer to `ls -ash` on 'y'
function chpwd() {
  case "${PWD}" in
    "${HOME}") dirs -c ;;
    *)
      echo "${BLUE}There are $(( $( ls -l | wc -l)-1 )) files in the current dir. Exec ls?${WHITE}: [Y/n]? "
      read -k 1 -s YN < /dev/null
        case "${YN}" in
          y|Y) clear ; ls -ash ;;
          *) return ;;
      esac
      ;;
  esac
}

#########################
## Language assistance
#########################

## Push ctrl+t in terminal to translate the current buffer into a language selected in fzf and display it in most, unless buffer is empty- then truncate your zsh history file
function _language::936e5d23f3f057b70e4ede374f59826cb3db4e2cd20650b7d2c95ee9() {
case "${PWD}" in
  "${HOME}")
    case "${BUFFER}" in
      '')
        clear
        printf "\033[1;0HCleaning .zhistory"
        bleachbit -c --preset > /dev/null 2>&1
        printf "\033[1;0H                    "
        truncate "${HISTORY}" -s 0 > /dev/null 2>&1
        dirs -c
        printf "${GREEN}\033[1;0HHistory cleared"
        sleep 1
        printf "\033[m                      \033[m"
        printf "\r${GREEN}\033[1;0HPress <Enter> to exit\033[0m" ;;
      *)
        LANG="$(trans -list-codes | fzf --layout=reverse)" 
        TRANS="$(trans -b :$LANG "${BUFFER}")"
        case $LANG in
          es) COLOR="${YELLOW}" ;;
          de) COLOR="${RED}" ;;
          fr) COLOR="${BLUE}" ;;
          it) COLOR="${GREEN}" ;;
          *) COLOR=() ;;
        esac
        echo "${COLOR}${TRANS}" | most
    esac
    ;;
  *) ;;
esac
}
zle -N _language::936e5d23f3f057b70e4ede374f59826cb3db4e2cd20650b7d2c95ee9
bindkey "^T" _language::936e5d23f3f057b70e4ede374f59826cb3db4e2cd20650b7d2c95ee9

## Push ctrl+d to view aspell for the correct spelling of last word in the buffer using fzf and replace the last word, if selected. (esc exits fzf searches)
function _language::6a286594e036b31b5ae96ce5ad39226f6c1a947212b9823f35b14132() {
case ${PWD} in
  "${HOME}")
    setopt shwordsplit
    NOTE=$( echo "${BUFFER}" \
    | rev \
    | cut -f1 -d' ' \
    | rev | \
    aspell -a -m 10 --lang=en list \
    | tr ' ' '\n' \
    | tail -n +14 \
    | sed s/,//g \
    | fzf --layout=reverse )
    if [[ -z "${NOTE}" ]] ; then
      return
    else
      LBUFFER="${NOTE}"
    fi
    unsetopt shwordsplit ;;
  *) ;;
esac }
zle -N _language::6a286594e036b31b5ae96ce5ad39226f6c1a947212b9823f35b14132
bindkey "^D" _language::6a286594e036b31b5ae96ce5ad39226f6c1a947212b9823f35b14132

#########################
## Smartphone utilities
#########################

## Push ctrl+w to fetch local weather data for your current region as well as the 7 day forcast and display it in most
function _weather::d8684fa189038cb94baa4eaaa8d7798e000ea72d0ed49d573a117850() {
case "${PWD}" in
  "${HOME}")
    clear
    declare -r LOC="galveston,texas"
    printf "${BLUE}\033[1;1H\rFetching local weather..."
    CUR=$(ansiweather -l "${LOC}" -u imperial -i true -s true -w true -h true -H true -p true -d true -a false | sed 's/-/\\n/g ; s/:/:\nTemp:/ ; s/ //' &)
    printf "${BLUE}\033[1;1H\rFetching 7-day forecast..."
    FRC=$(ansiweather -f7 -l "${LOC}" -u imperial -s true -a false | sed 's/-/\\n/g ; s/ //' &)
    clear
    echo "${YELLOW}${CUR}\n\n${MAGENTA}${FRC}" \
    | sed 's/\(forecast: \)\(.*\)/\1\n\2/g ; s/^[[:space:]]*//' \
    | most
    printf "${GREEN}Press <Enter> to exit"
   ;;
  *) ;;
esac }
zle -N _weather::d8684fa189038cb94baa4eaaa8d7798e000ea72d0ed49d573a117850
bindkey "^W" _weather::d8684fa189038cb94baa4eaaa8d7798e000ea72d0ed49d573a117850

## Push ctrl+p to browse music folder using fzf and launch an album using mpv
function _radio::50c5e1885673628f5d99a4e1746ad12f2fd112327092d816d9ebad3b() { {
  MUSICDIR="${HOME}/Music/"
  printf "${GREEN}Radio on"
  sleep 1
  BAND="$(find "${MUSICDIR}" -type d -maxdepth 1 -printf "%f\n" \
    | grep -v "Music" \
    | fzf --layout=reverse )"
  ALBUM="$(find "${MUSICDIR}/${BAND}" -type d -maxdepth 1 -printf "%f\n" \
    | grep -v "${BAND}" \
    | fzf --layout=reverse )"
  DISK="${MUSICDIR}/${BAND}/${ALBUM}"
  clear
  printf "\033[0mWould you like to:$YELLOW\nA)$WHITE Play this album$GREEN\nS)$WHITE Play a song off this album$MAGENTA\nC)$WHITE Set an alarm$RED\n*)$WHITE Exit\n"
  read -k 1 -s YN > /dev/null
  case $YN in
    a|A) mpv --start=0 ${DISK}/* >/dev/null ;;
    s|S)
      TRACK="$(find "${DISK}" -type f -maxdepth 1 -printf "%f\n" \
        | grep -v "${ALBUM}" \
        | fzf --layout=reverse)"
      mpv --start=0 ${DISK}/${TRACK}
      ;;
    c|C)
        TRACK="$(find "${DISK}" -type f -maxdepth 1 -printf "%f\n" \
        | grep -v "${ALBUM}" \
        | fzf --layout=reverse)"
        clear
        TIME="$(date -d "$(date) +8 hours" +%H:%M:%S)"
        printf "${GREEN}Alarm set for ${WHITE}${TIME}"
        printf "\033[4;0HWake up song set as ${GREEN}${TRACK}${WHITE} by ${GREEN}${BAND}"
        for i in $(seq 28800.0 -1.0 0); do
          TIME="$(printf "%.2f" $((i/3600.0)) )"
          printf "\033[0m\033[2;0H                                        "
          printf "\033[2;0H${GREEN}${TIME}${WHITE} more hours ${GREEN}$(( 100 - (${TIME} / 8) * 100 ))%%${WHITE} complete"
          sleep 1
        done
        sleep 8h
        mpv --start=0 ${DISK}/${TRACK}
        ;;
    *) clear
       printf "${GREEN}\033[1;0HRadio off"
       sleep 1
       printf "${GREEN}\033[1;0HPress <Enter> to exit"
       return
      ;;
    esac
} always {
case $? in
  0) ;;
  *) return ;;
esac
} }
## Ctrl+p activates fzf/mpv mp3 player
zle -N _radio::50c5e1885673628f5d99a4e1746ad12f2fd112327092d816d9ebad3b
bindkey "^P" _radio::50c5e1885673628f5d99a4e1746ad12f2fd112327092d816d9ebad3b 

##########################################################################
## script::functions bindkeys located in the _zsh::setup function below
##########################################################################

SCRIPT= ## Set the $SCRIPT var

## Add the last command run to your script var
function _script::8e8e2195745c1ddc664c3075594d7ae7c8befb7ac995ce1dd84eabd7() {
  SCRIPT+=("$(tail -n1 "${HISTORY}")\n")
  clear
  printf "${GREEN}\033[1;0HSnippet added"
  sleep 2
  printf "\033[2;0H${PWD}: "
  printf "\r\033[2;14H: "
}

## View the SCRIPT var in vim, or if buffer is blank, open vim
function _script::7672c832e7307e006156cfbbb05258b2b2b36ee55080e1077a234a00() {
  echo "$SCRIPT" | vim -
}

## Clear the script buffer
function _script::1ddb894f60bbaf435d1a3d51837b3ae00673573551d1e5042ac750f1() {
  SCRIPT=()
  clear
  printf "${GREEN}\033[1;0HScript buffer cleared"
  sleep 2
  printf "\033[2;0H${PWD}: "
  printf "\r\033[2;16H"
}

################
## zsh::setup
################

## Check for zsh and installed packages and, if not present, prompt for install on initial line 
function _zsh::c124bad8ecb45eac3ccb51bfb10d2841834ba5168d9a6fda53726e8e() {
## Check if zsh is enabled in ~/.bashrc
  if [[ $(tail -n1  ~/.bashrc) != "exec zsh" ]] ; then
    echo "exec zsh" >> ~/.bashrc
  fi
## Check if zsh plugins are installed
  for PLUGIN in zsh-autosuggestions zsh-completions zsh-syntax-highlighting zsh-theme-powerlevel10k ; do
    if ! pacman -Qs "${PLUGIN}" &> /dev/null ; then
      OUT+="${PLUGIN}"
    fi
  done
## Check if zsh depends are installed
  for PKG in thefuck ansiweather aspell axel bleachbit fzf most mpv tgpt trans vim ; do
    if ! which "${PKG}" &> /dev/null ; then
      case "${PKG}" in
        aspell) PKG='aspell-en' ;;
        trans) PKG='translate-shell' ;;
        *) ;;
      esac
    OUT+="${PKG} "
    fi
  done
## Check if depends are installed
  if [[ -z "${OUT}" ]] ; then 
## Check if an update is needed
    if ! pacman -Qu ; then
      return
    else
      print -z "sudo pacman -Syyu"
    fi
  else
## Print -z any necessary depends
    printf "${RED}Missing package warning!"
    printf "${RED}ZSH requires ${OUT%?}"
    print -z "sudo pacman -Syyu ${OUT%?}"
  fi
## Check desktop version
case $XDG_SESSION_DESKTOP in
  i3)
## Ctrl+a adds the last line to the scripting buffer
    zle -N _script::8e8e2195745c1ddc664c3075594d7ae7c8befb7ac995ce1dd84eabd7
    bindkey "^A" _script::8e8e2195745c1ddc664c3075594d7ae7c8befb7ac995ce1dd84eabd7
## Ctrl+v opens the script in vim
    zle -N _script::7672c832e7307e006156cfbbb05258b2b2b36ee55080e1077a234a00
    bindkey "^V" _script::7672c832e7307e006156cfbbb05258b2b2b36ee55080e1077a234a00
## Ctrl+x erases the script buffer
    zle -N _script::1ddb894f60bbaf435d1a3d51837b3ae00673573551d1e5042ac750f1
    bindkey "^X" _script::1ddb894f60bbaf435d1a3d51837b3ae00673573551d1e5042ac750f1
    ;;
  swmo) ;;
  *) ;;
esac
}
## Execute Setup at startup
_zsh::c124bad8ecb45eac3ccb51bfb10d2841834ba5168d9a6fda53726e8e

#############
## Sources
#############

## Source ZSH plugins
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

## Silence p10k message
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
