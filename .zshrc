if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

## Options section
setopt correct correctall
setopt extendedglob nocaseglob rcexpandparam numericglobsort
setopt appendhistory histignorealldups
setopt inc_append_history histignorespace
setopt aliases autocd
setopt hist_save_no_dups hist_reduce_blanks

zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' rehash true
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
HISTFILE=~/.zhistory
HISTSIZE=100
SAVEHIST=100
WORDCHARS=${WORDCHARS//\/[&.;]}

## Keybindings section
bindkey -e
bindkey '^[[7~' beginning-of-line
bindkey '^[[H' beginning-of-line
if [[ "${terminfo[khome]}" != "" ]]; then
  bindkey "${terminfo[khome]}" beginning-of-line
fi
bindkey '^[[8~' end-of-line
bindkey '^[[F' end-of-line
if [[ "${terminfo[kend]}" != "" ]]; then
  bindkey "${terminfo[kend]}" end-of-line
fi
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

## Alias section
alias cp="cp -i"
alias df='df -h'
alias free='free -m'
alias vim="vim -f"
alias ls='ls --color=auto'
alias c="clear"
alias q="exit"

## Theming section
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

## Offer to install missing package if command is not found
if [[ -r /usr/share/zsh/functions/command-not-found.zsh ]]; then
    source /usr/share/zsh/functions/command-not-found.zsh
    export PKGFILE_PROMPT_INSTALL_MISSING=1
fi

## Custom functions
function precmd() {case $? in 0) printf '\033[0m' ;; *) clear ; tgpt "`tail -n1 ~/.zhistory`";; esac}

function chpwd() {printf "\033[34mThere are $((`ls -l | wc -l`-1)) files in the current dir. exec ls?\033[0m: [Y/n]? "; read YN; case $YN in y|Y) ls -ash ;; *) ;; esac}

function tk() {truncate ~/.zhistory -s 0 ; notify-send "History cleared"} ; zle -N tk ; bindkey '^Z' tk

function ts() {trans -b -p :`trans -list-codes | fzf --layout=reverse --border=rounded --preview-window=down,33% --preview 'trans -b :{} "$(trans --help)"'` "$BUFFER" | most} ; zle -N ts ; bindkey "^T" ts

function sp() {setopt shwordsplit; ORIG=$(echo $BUFFER | rev | cut -f1 -d' ' | rev) ; NOTE=$( echo $ORIG | aspell -a -m 10 --lang=en list | tr ' ' '\n' | tail -n +14 | sed s/,//g | fzf --layout=reverse) ; wtype -M ctrl h -m ctrl|| xdotool key --clearmodifiers ctrl+h ; RBUFFER+=" $NOTE" ; wtype -M ctrl e -m ctrl || xdotool key --clearmodifiers ctrl+e ; unsetopt shwordsplit} ; zle -N sp ; bindkey "^D" sp

function weather() {echo 'Fetching weather data...'; LOC=galveston,texas ; CUR=$(ansiweather -l $LOC -u imperial &) ; echo 'Fetching 7-day forecast...' ; FRC=$(ansiweather -F -l $LOC -u imperial &) ; echo '\n' $CUR '\n\n' $FRC | most -wd ; clear} ; zle -N weather ; bindkey "^W" weather

function radio() {clear ; mpv --start=0 $(find "$HOME/Music/" -type d | fzf )/*} ; zle -N radio ; bindkey "^P" radio

## Sources
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
