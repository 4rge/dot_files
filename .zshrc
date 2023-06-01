if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then ; source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ; fi

############
## Setops ##
############

setopt correct correctall # Enables spelling correction for commands that are mistyped and for all arguments in a command.
setopt extendedglob nocaseglob rcexpandparam numericglobsort # Enables advanced pattern matching operators, such as '!' for negation and '|' for alternation. Matches file names case-insensitively when using glob patterns. Expands parameters inside of single quotes. Sorts file names in numerical order rather than lexicographical order.
setopt appendhistory histignorealldups inc_append_history histignorespace hist_save_no_dups hist_reduce_blanks # Appends new commands to the existing history file. Ignores duplicate commands in the history file. Writes each command to the history file as it is executed, rather than only on exit. Ignores commands starting with a space character in the history file. Saves only the most recent instance of a duplicated command in the history file, and Removes extra blank lines from the history file.
setopt aliases autocd # Enables the use of aliases, which are shorthand commands or command sequences. Changes to a directory if the input provided is a valid directory path.

################################
## Completion options & cache ##
################################

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

#############
## History ##
#############

readonly HISTORY=~/.zhistory
export HISTORY

readonly SIZE=100
export SIZE

HISTFILE="${HISTORY}"
HISTSIZE="${SIZE}"
SAVEHIST="${SIZE}"
WORDCHARS=${WORDCHARS//\/[&.;]}

#################
## Keybindings ##
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
## Alias ##
###########

alias cp="cp -i" ## Enable color
alias df='df -h' ## Human readable output
alias free='free -m' ## Show output in medibytes
alias vim="vim -f" ## Force vim into the current window
alias ls='ls --color=auto' ## Force ls to use colors
alias c="clear" ## Clear the current terminal
alias q="exit" ## Exit the current shell
alias z="zcompile ~/.zshrc ; notify-send '.zshrc recompiled'" ## Recompile zsh as a binary source
eval $(thefuck --alias) ## Add 'the fuck' alias

#############
## Theming ##
#############

autoload -Uz compinit && compinit -u ## Autoload all zsh functions
export LESS_TERMCAP_us=$'\E[01;36m'
export LESS=-R
zmodload zsh/terminfo

############
## Precmd ##
############

## Offer to install missing package if command is not found 
if [[ -r /usr/share/zsh/functions/command-not-found.zsh ]]; then
  source /usr/share/zsh/functions/command-not-found.zsh ; export PKGFILE_PROMPT_INSTALL_MISSING=1
fi

## When a command fails in the home dir reroute the output to fuck unless cmd not found, then reroute to chatgpt. If it fails in any other dir run thefuck
function precmd() {
  case "${PWD}" in 
    $HOME)
      case "${?}" in 
        0) ;;
        1) fuck ;;
        *) clear ; tgpt "`tail -n1 ${HISTORY}`" ;;
      esac ;;
    *)
      case "${?}" in 0) ;;
        *) fuck ;;
      esac ;;
  esac }

## When the dir is changed recieve a [y/n] prompt listing the total number of files in the dir and offer to `ls -a` on 'y'
function chpwd() {
  case "${PWD}" in
    "${HOME}") dirs -c ;;
    *)
      printf "\033[m\033[34mThere are $(( `ls -l | wc -l`-1 )) files in the current dir.
      exec ls?\033[0m: [Y/n]? "
      read YN
        case "${YN}" in
          y|Y) ls -ash ;;
      esac ;;
  esac }

################
## _Functions ##
################

## Push ctrl+t in terminal to translate the current buffer into a language selected in fzf and display it in most, unless buffer is empty- then truncate your zsh history file
function _t() {
case "${PWD}" in
  "${HOME}")
    case "${BUFFER}" in
      '')
        notify-send 'Cleaning .zhistory'
        bleachbit -c --preset > /dev/null 2>&1
        truncate "${HISTORY}" -s 0 > /dev/null 2>&1
        dirs -c
        notify-send 'History cleared' ;;
      *)
        trans -b :`trans -list-codes \
        | fzf --layout=reverse --border=rounded --preview-window=down,33% \
        --preview 'trans -b :{} "$( tail -n1 $HISTORY )"'` "${BUFFER}" \
        | most ;;
    esac ;;
  *) ;;
esac }
zle -N _t
bindkey "^T" _t

## Push ctrl+d to view aspell for the correct spelling of last word in the buffer using fzf and replace the last word, if selected. (esc exits fzf searches)
function _s() {
case ${PWD} in
  $HOME)
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
    if [[ -z "${NOTE}" ]] ; then ; return
    else xdotool key --clearmodifiers ctrl+h || wtype -M ctrl h -m ctrl
      RBUFFER+="${NOTE}"
      xdotool key --clearmodifiers ctrl+e || wtype -M ctrl e -m ctrl
    fi
    unsetopt shwordsplit ;;
  *) ;;
esac }
zle -N _s
bindkey "^D" _s

## Push ctrl+w to fetch local weather data for your current region as well as the 7 day forcast and display it in most
function _w() {
case "${PWD}" in
  "${HOME}")
    readonly LOC="galveston,texas"
    printf "\033[0m\033[34mFetching weather data...\033[0m"
    CUR=$(ansiweather -l "${LOC}" -u imperial -i true -w true -h true -H true -p true -d true -a false &)
    printf "\033[0m\033[34m\nFetching 7-day forecast...\033[0m"
    FRC=$(ansiweather -F -l "${LOC}" -u imperial -a false &)
    echo "${CUR}" '\n\n' "${FRC}" | most -wd;;
  *) ;;
esac }
zle -N _w
bindkey "^W" _w

## Push ctrl+p to browse music folder using fzf and launch an album using mpv
function radio() {
  clear
  mpv --start=0 $( find "${HOME}/Music/" -type d | fzf )/* }
zle -N radio
bindkey "^P" radio

#######################
## script::functions ##
#######################

SCRIPT= ## Set the $SCRIPT var

## Push ctrl+a to add the last command run to your script var
function _script::add() {
  SCRIPT+=($(tail -n1 "${HISTORY}")) ; notify-send "Snippet added" }
zle -N _script::add
bindkey "^A" _script::add 

## Push ctrl+v to view the SCRIPT var in vim
function _script::view() {
  echo "${SCRIPT}" | vim -}
zle -N _script::view
bindkey "^V" _script::view

## Push ctrl+e to clear the script buffer
function _script::erase() {
  SCRIPT=() ; notify-send "Script buffer cleared" }
zle -N _script::erase
bindkey "^E" _script::erase

################
## zsh::setup ##
################

## Check for zsh and installed packages and, if not present, prompt for install on initial line 
function _zsh::setup() {
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
## Print the missing packages to terminal
  if [[ -z "${OUT}" ]] ; then ; return
    else; print -z "sudo pacman -Syyu ${OUT}"
  fi }
## Execute Setup at startup
_zsh::setup

#############
## Sources ##
#############

## Source ZSH plugins
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

## Silence p10k message
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
