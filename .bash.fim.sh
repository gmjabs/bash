# fim = vim + find-completion
alias fim=vim
_fimComplete()   
{
  local cur
  local COMPFILES
  local FPATH

  cur=${COMP_WORDS[COMP_CWORD]}

  # only look through history if we're not going to complete a local subdirectory
  COMPFILES=( $(compgen -o filenames $cur) )

  if [ ${#COMPFILES[*]} == 0 ] ; then
    for FPATH in `find . -type file  -regex ".*/${cur}.*"` ; do
      COMPREPLY[${#COMPREPLY[*]}]=${FPATH}
    done
  fi

  return 0
}
complete -F _fimComplete -o filenames fim

