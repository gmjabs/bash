#
# cd alias which tracks a stack of recently visited directories with some magic
# - cd to an explicit directory places that directory on the top of the stack
# - cd +/-n changes to the n'th next/previous directory in the stack
# - cd ..n changes to the nth directory above this one
# - dirs prints the current directory stack
#
# additionaly, tab-completion will match directories in the stack if there are no matches in the
# current working directory
#
# requires bash 4 or higher

DIRS=($PWD)
_cd() {

   local i=0;
   local to=$1;
   local cdarg="";
   local dirlen=${#DIRS[*]};

   if [ "$to" == "-P" ] || [ "$to" == "-L" ] || [ "$to" == "--" ] ; then
       cdarg=$to;
       to=$2;
   fi

   if [ "$to" == "" ] ; then to=$HOME; fi

   if [[ "$to" == ..[[:digit:]]* ]] ; then
       local up=${to:2};
       to=..;
       while [ "$up" -gt 1 ] ; do
          to="$to/..";
          ((up--));
       done;
   fi;

   if [ ${to:0:1} == "-" ] && [ "$cdarg" != "--" ] ; then
       local count=${to:1};
       if [ "$count" == "" ] ; then count=1; fi
       if [[ ! $count == [[:digit:]]* ]] ; then
           echo "expected number (got \"$count\")" 1>&2 ;
           return;
       fi
       i=$count;
       while [ $i -lt $dirlen ] ; do
           if [ ${DIRS[$i]} == $PWD ] ; then
               to=${DIRS[$((i-count))]};
           fi
           ((i++));
       done
       if [ ${to:0:1} == "-" ] ; then
           echo "previous dir not found" 1>&2 ;
           return;
       fi
       cd $cdarg $to > /dev/null

   elif [ ${to:0:1} == "+" ] ; then
       local count=${to:1};
       if [ "$count" == "" ] ; then count=1; fi
       if [[ ! $count == [[:digit:]]* ]] ; then
           echo "expected number (got \"$count\")" 1>&2 ;
           return ;
       fi
       i=$((dirlen-count-1));
       while [ $i -ge 0 ] ; do
           if [ ${DIRS[$i]} == $PWD ] ; then
               to=${DIRS[$((i+count))]};
           fi
           ((i--));
       done
       if [ ${to:0:1} == "+" ] ; then
           echo "next dir not found" 1>&2 ;
           return;
       fi
       cd $cdarg $to > /dev/null
   else
       cd $cdarg $to > /dev/null && {
           local j=0;
           for i in ${DIRS[*]} ; do
               if [ "$i" == "$PWD" ] ; then
                   unset DIRS[$j];
                   DIRS=(${DIRS[*]});
               fi
               ((j++))
               # max the dir stack at 20
               if [ $j -gt 20 ] ; then
                   unset DIRS[0];
                   DIRS=(${DIRS[*]});
               fi;
           done; 
           DIRS[${#DIRS[*]}]=$PWD;
       }
   fi
}
complete -d cd

_dirs() {
    if [ "$1" == "-c" ] ; then
        DIRS=();
        echo "directory history cleared";
        return;
    fi
    local i;
    for i in ${DIRS[*]} ; do
       if [ "$i" == "$PWD" ] ; then
           echo -n " > ";
       else
           echo -n "   ";
       fi
       echo "$i";
   done; 
}

_cdHistComplete()   
{
  local cur
  local DPATH
  local COMPDIRS

  cur=${COMP_WORDS[COMP_CWORD]}

  # only look through history if we're not going to complete a local subdirectory
  COMPDIRS=( $(compgen -o dirnames $cur) )

  if [ ${#COMPDIRS[*]} == 0 ] ; then
    for DPATH in ${DIRS[*]} ; do
      local regex='.*/'${cur}'[^/]*$'
      if echo "${DPATH}" | grep -q "$regex"; then
        COMPREPLY[${#COMPREPLY[*]}]=${DPATH}/
      fi
    done
  fi

  return 0
}
complete -F _cdHistComplete -o dirnames -o nospace cd
