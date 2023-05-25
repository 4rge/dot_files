if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then ; source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ; fi

####################
## Setops section ##
####################

setopt correct correctall # Enables spelling correction for commands that are mistyped and for all arguments in a command.
setopt extendedglob nocaseglob rcexpandparam numericglobsort # Enables advanced pattern matching operators, such as '!' for negation and '|' for alternation. Matches file names case-insensitively when using glob patterns. Expands parameters inside of single quotes. Sorts file names in numerical order rather than lexicographical order.
setopt appendhistory histignorealldups inc_append_history histignorespace hist_save_no_dups hist_reduce_blanks # Appends new commands to the existing history file. Ignores duplicate commands in the history file. Writes each command to the history file as it is executed, rather than only on exit. Ignores commands starting with a space character in the history file. Saves only the most recent instance of a duplicated command in the history file, and Removes extra blank lines from the history file.
setopt aliases autocd # Enables the use of aliases, which are shorthand commands or command sequences. Changes to a directory if the input provided is a valid directory path.

######################################
## Set completion options and cache ##
######################################

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

######################
## History settings ##
######################

HISTFILE=~/.zhistory
HISTSIZE=100
SAVEHIST=100
WORDCHARS=${WORDCHARS//\/[&.;]}

#########################
## Keybindings section ##
#########################

bindkey -e
bindkey '^[[7~' beginning-of-line
bindkey '^[[H' beginning-of-line
if [[ "${terminfo[khome]}" != "" ]]; then ; bindkey "${terminfo[khome]}" beginning-of-line ; fi
bindkey '^[[8~' end-of-line
bindkey '^[[F' end-of-line
if [[ "${terminfo[kend]}" != "" ]]; then ; bindkey "${terminfo[kend]}" end-of-line ; fi
bindkey '^[[2~' overwrite-mode
bindkey '^[[3~' delete-char
bindkey '^[[C'  forward-char
bindkey '^[[D'  backward-char
bindkey '^[[5~' history-beginning-search-backward
bindkey '^[[6~' history-beginning-search-forward
bindkey '^[Oc' forward-word
bindkey '^[Od' backward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^H' backward-kill-word
bindkey '^[[Z' undo

###################
## Alias section ##
###################

alias cp="cp -i" ## Enable color
alias df='df -h' ## Human readable output
alias free='free -m' ## Show output in medibytes
alias vim="vim -f" ## Force vim into the current window
alias ls='ls --color=auto' ## Force ls to use colors
alias c="clear"
alias q="exit"

#####################
## Theming section ##
#####################

autoload -U compinit colors zcalc ; compinit -d ; colors
export LESS_TERMCAP_mb=$'\E[01;32m'
export LESS_TERMCAP_md=$'\E[01;32m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;47;34m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;36m'
export LESS=-R

zmodload zsh/terminfo

####################
## Precmd Section ##
####################

## Offer to install missing package if command is not found
if [[ -r /usr/share/zsh/functions/command-not-found.zsh ]]; then ; source /usr/share/zsh/functions/command-not-found.zsh ; export PKGFILE_PROMPT_INSTALL_MISSING=1 ; fi
## Add thefuck alias
eval $(thefuck --alias)
# When a command fails in the home dir reroute the output to chatgpt. if it fails in any other dir run thefuck
function precmd() {
    case $PWD in 
        $HOME) case $? in 0) printf '\033[0m' ;; *) clear ; tgpt "`tail -n1 ~/.zhistory`";; esac ;;
        *) case $? in 0) ;; *) fuck ;; esac ;;
        esac}

# When the dir is changed recieve a [y/n] prompt listing the total number of files in the dir and offer to `ls -a` on 'y'  
function chpwd() {
    case $PWD in
        $HOME) dirs -c;;
        *) printf "\033[m\033[34mThere are $((`ls -l | wc -l`-1)) files in the current dir. exec ls?\033[0m: [Y/n]? "; read YN; case $YN in y|Y) ls -ash ;; esac ;;
        esac}

##############################
## Custom command functions ##
##############################

# Push ctrl+t in terminal to translate the current buffer into a language selected in fzf and display it in most, unless buffer is empty- then truncate your zsh history file
function t() {
case $PWD in
    $HOME) case $BUFFER in '') notify-send 'Cleaning .zhistory' ; truncate ~/.zhistory -s 0 ; bleachbit -c --preset > /dev/null 2>&1 ; notify-send 'History cleared' ;; *) trans -b :`trans -list-codes | fzf --layout=reverse --border=rounded --preview-window=down,33% --preview 'trans -b :{} "$(trans --help)"'` "$BUFFER" | most ;; esac ;;
    *) ;;
    esac} ; zle -N t ; bindkey "^T" t

# Push ctrl+d to view aspell for the correct spelling of last word in the buffer using fzf and replace the last word, if selected. (esc exits fzf searches)
function s() {
case $PWD in
    $HOME) setopt shwordsplit; ORIG=$(echo $BUFFER | rev | cut -f1 -d' ' | rev) ; NOTE=$( echo $ORIG | aspell -a -m 10 --lang=en list | tr ' ' '\n' | tail -n +14 | sed s/,//g | fzf --layout=reverse) ; xdotool key --clearmodifiers ctrl+h || wtype -M ctrl h -m ctrl ; RBUFFER+=" $NOTE" ; xdotool key --clearmodifiers ctrl+e || wtype -M ctrl e -m ctrl ; unsetopt shwordsplit ;;
    *) ;;
    esac} ; zle -N s ; bindkey "^D" s

# Push ctrl+w to fetch local weather data for your current region as well as the 7 day forcast and display it in most
function w() {
case $PWD in
    $HOME) echo "\033[0m\033[34mFetching weather data...\033[0m" ; LOC=galveston,texas ; CUR=$(ansiweather -l $LOC -u imperial &) ; printf "\033[0m\033[34mFetching 7-day forecast...\033[0m" ; FRC=$(ansiweather -F -l $LOC -u imperial &) ; echo '\n' $CUR '\n\n' $FRC | most -wd ; clear ;;
    *) ;;
    esac} ; zle -N w ; bindkey "^W" w

# Push ctrl+p to browse music folder using fzf and launch an album using mpv
# function radio() {clear ; mpv --start=0 $(find "$HOME/Music/" -type d | fzf )/*} ; zle -N radio ; bindkey "^P" radio

#########################
## Install ZSH depends ##
#########################

for PKG in ansiweather aspell axel bleachbit discord feh irqbalance logrotate nmap sha3sum tgpt thefuck tlp trans vim ; do ; if ! which $PKG &> /dev/null; then ; case $PKG in aspell) PKG='aspell-en';; trans) PKG='translate-shell' ;; *) ;; esac ; sudo pacman -S $PKG ; fi ; done

#############
## Sources ##
#############

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
