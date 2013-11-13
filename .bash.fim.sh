# fim = vim + find-completion
alias fim=vim
_fimComplete()   
{
  local cur
  local COMPFILES
  local FPATH

  cur=${COMP_WORDS[COMP_CWORD]}

  # only find if we're not matching a path in the current directory
  COMPFILES=( $(compgen -o filenames $cur) )

  if [ ${#COMPFILES[*]} == 0 ] ; then
    for FPATH in `find . -type file  -regex ".*/${cur}.*"` ; do
      COMPREPLY[${#COMPREPLY[*]}]=${FPATH}
    done
  fi

  return 0
}
complete -F _fimComplete -o filenames fim

