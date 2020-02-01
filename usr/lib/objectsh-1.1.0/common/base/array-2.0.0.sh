#!/bin/sh
##a colloction of array handling tools
#[of]:function aset {
function aset {
#[of]:  usage
  if false ; then
    echo "Usage: aset var [val val val ...]"
    echo "Error: must have at least 1 args"
    echo "Description:"
    echo "  sets a given array variable"
    echo "  this exist because, there is no common way of setting an array in ksh and bash"
    echo "Examples:"
    echo "  i.e.  aset gl_BusinessDays mon tue wed thu fri"
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
}
if [[ -n "$BASH_VERSION" ]] ; then
  function aset {
    eval "
      shift
      $1=(\"\$@\")
    "
  }
else
  function aset {
    eval "
      shift
      set -A $1 -- \"\$@\"
    "
  }
fi
#[cf]
#[of]:function asort {
function asort {
#[of]:  usage
  if [[ $# -lt 2 ]] ; then
    echo "Usage: asort {-|array} [val val val ...]"
    echo "Error: must have at least 2 args"
    echo "Description:"
    echo "  sorts an array"
    echo "Examples:"
    echo '  i.e.  asort a "${a[@]}"'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  typeset lc_asort_tmp lc_asort_size lc_asort_index
  unset lc_asort_array
  aset lc_asort_array "$@"
  ashift ! lc_asort_array
  lc_asort_size=${#lc_asort_array[@]}
  ((lc_asort_size-=1))
  while [[ ${lc_asort_size} -gt 0 ]] ; do
    lc_asort_index=0    
    while [[ ${lc_asort_index} -lt ${lc_asort_size} ]] ; do
      if [[ "${lc_asort_array[${lc_asort_index}]}" > "${lc_asort_array[$((lc_asort_index+1))]}" ]] ; then
        lc_asort_tmp="${lc_asort_array[$((lc_asort_index+1))]}"
        lc_asort_array[$((lc_asort_index+1))]="${lc_asort_array[${lc_asort_index}]}"
        lc_asort_array[${lc_asort_index}]="${lc_asort_tmp}"
      fi
      ((lc_asort_index+=1))
    done
    ((lc_asort_size-=1))
  done
  if [[ "$1" = "-" ]] ; then
    echo "${lc_asort_array[@]}"
  else
    eval "aset $1 \"\${lc_asort_array[@]}\""
  fi
  unset lc_asort_array
  return 0
}
#[cf]

#[of]:function asplit {
function asplit {
#[of]:  usage
  if [[ $# -lt 2 ]] ; then
    echo "Usage: asplit {array} {delimiter} [string]"
    echo "Error: must have at least 2 args"
    echo "Description:"
    echo "  splits a string into an array list"
    echo "  this emulates the perl function join"
    echo "Examples:"
    echo '  i.e.  asplit b : "part1:part2:part3:part4"'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  typeset _esc
  if [[ "$1" = "-e" ]] ; then
    _esc=true
    shift
  fi
#[of]:  if [[ -z "$2" ]] ; then
  if [[ -z "$2" ]] ; then
    eval "
      shift;shift
      typeset _string
      _string=\"\$*\"
      while [[ \${#_string} -gt 0 ]] ; do
        typeset _array
        _array[\${#_array[@]}]=\"\${_string%\"\${_string#?}\"}\"
        _string=\"\${_string#?}\"
      done
      if isnum \"$1\" ; then
        echo \"\${_array[$1]}\"
      else
        aset $1 \"\${_array[@]}\"
      fi
    "
#[cf]
#[of]:  elif ${_esc\:-false} ; then
  elif ${_esc:-false} ; then
    eval "
      shift;shift
      typeset _array _char _lit _index _string
      _lit=false
      _index=0
      _string=\"\$*\"

      while [[ \${#_string} -gt 0 ]] ; do
        _char=\"\${_string%\"\${_string#?}\"}\"
        _string=\"\${_string#?}\"
        if [[ \"\${_char}\" = \"\\\\\" ]] ; then
          _lit=true
          continue
        elif ! \${_lit} && [[ \"\${_char}\" = \"$2\" ]] ; then
          _array[\${_index}]=\"\${_entry}\"
          unset _entry
          let \"_index+=1\"
          continue
        fi
        _lit=false
        typeset _entry
        _entry=\"\${_entry}\${_char}\"
      done
      _array[\${_index}]=\"\${_entry}\"

      if isnum \"$1\" ; then
        echo \"\${_array[$1]}\"
      else
        aset $1 \"\${_array[@]}\"
      fi
    "
#[cf]
#[of]:  else
  else
    eval "
      shift;shift
      typeset IFS
      IFS=\"$2\"
      typeset _string
      _string=\"\$*\"
      if isnum \"$1\" ; then
        set -- \$@
        eval \"echo \\\"\\\$\$(($1 +1))\\\" \"
      else
        if [[ \"\${_string%$2}\" = \"\$*\" ]] ; then
          aset $1 \$@
        else
          aset $1 \$@ \"\"
        fi
      fi
    "
#[cf]
  fi
}
##if first arg is a number it is a zero based position in the string
##ugh.  yet another lovely backslash forrest.
#[cf]
#[of]:function ajoin {
function ajoin {
#[of]:  usage
  if [[ $# -lt 2 ]] ; then
    echo "Usage: ajoin {var} {delimiter} [val val val ...]"
    echo "Error: must have at least 2 args"
    echo "Description:"
    echo "  joins a list into a single string"
    echo "  this emulates the perl function join"
    echo "Examples:"
    echo '  i.e.  ajoin a : "${a[@]}"'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  eval "
    shift;shift
    typeset IFS
    IFS=\"$2\"
    if [[ \"$1\" = \"-\" ]] ; then
      echo \"\$*\"
    else
      $1=\"\$*\"
    fi
  "
}
#[cf]

#[of]:function apush {
function apush {
#[of]:  usage
  if [[ $# -eq 0 ]] ; then
    echo "Usage: apush {array} [val val val ...]"
    echo "Error: must have at least 2 args"
    echo "Description:"
    echo "  adds new element/s to the end of an array"
    echo "  this emulates the perl array function push"
    echo "Examples:"
    echo '  i.e.  apush b "a string"'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  eval "
    shift
    aset $1 \"\${$1[@]}\" \"\$@\"
  "
}
#[cf]
#[of]:function apop {
function apop {
#[of]:  usage
  if [[ $# -ne 2 ]] ; then
    echo "Usage: apop {!|-|var} {array}"
    echo "Error: must have at least 2 args"
    echo "Description:"
    echo "  shift an array 1 element right and return that element in var"
    echo "  this emulates the perl array function pop"
    echo "Examples:"
    echo '  i.e.  apop b a'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  eval "
    if [[ \${#$2[@]} -gt 0 ]] ; then
      if [[ \"$1\" = \"!\" ]] ; then
        :
      elif [[ \"$1\" = \"-\" ]] ; then
        echo \"\${$2[\$((\${#$2[@]} -1))]}\"
      else
        $1=\"\${$2[\$((\${#$2[@]} -1))]}\"
      fi
      unset $2[\$((\${#$2[@]} -1))]
    else
      return 1
    fi
  "
  return 0
}
#[cf]

#[of]:function aunshift {
function aunshift {
#[of]:  usage
  if [[ $# -eq 0 ]] ; then
    echo "Usage: aunshift {array} [val val val ...]"
    echo "Error: must have at least 2 args"
    echo "Description:"
    echo "  adds new element/s to the beginning of an array"
    echo "  this emulates the perl array function unshift"
    echo "Examples:"
    echo '  i.e.  aunshift b "a string"'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  eval "
    shift
    aset $1 \"\$@\" \"\${$1[@]}\"
  "
}
#[cf]
#[of]:function ashift {
function ashift {
#[of]:  usage
  if [[ $# -ne 2 ]] ; then
    echo "Usage: ashift {!|-|var} {array}"
    echo "Error: must have at least 2 args"
    echo "Description:"
    echo "  shift an array 1 element left and return that element in var"
    echo "  this emulates the perl array function shift"
    echo "Examples:"
    echo '  i.e.  ashift b a'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  eval "
    set -- \"\${$2[@]}\"
    if [[ \$# -gt 0 ]] ; then
      if [[ \"$1\" = \"!\" ]] ; then
        :
      elif [[ \"$1\" = \"-\" ]] ; then
        echo \"\$1\"
      else
        $1=\"\$1\"
      fi
      [[ \$# -gt 0 ]] && shift
      aset $2 \"\$@\"
    else
      return 1
    fi
  "
  return 0
}
#[cf]

#[of]:function awalkl {
function awalkl {
#[of]:  usage
  if [[ $# -ne 2 ]] ; then
    echo "Usage: awalkl {left array} {right array}"
    echo "Error: must have at least 2 args"
    echo "Description:"
    echo "  walks/moves array elements  <---  right to left"
    echo "Examples:"
    echo '  i.e.  awalkl nodes args'
    echo "Returns:"
    echo "  0 success"
    echo "  1 if right array is empty"
    exit 1
  fi
#[cf]
  ashift lc_awalkl_tmp $2 || return $?
  apush $1 "${lc_awalkl_tmp}"
  unset lc_awalkl_tmp
  return 0
}
#[cf]
#[of]:function awalkr {
function awalkr {
#[of]:  usage
  if [[ $# -ne 2 ]] ; then
    echo "Usage: awalkr {left array} {right array}"
    echo "Error: must have at least 2 args"
    echo "Description:"
    echo "  walks/moves array elements  --->  left to right"
    echo "Examples:"
    echo '  i.e.  awalkr args nodes'
    echo "Returns:"
    echo "  0 success"
    echo "  1 if left array is empty"
    exit 1
  fi
#[cf]
  apop lc_awalkl_tmp $1 || return $?
  aunshift $2 "${lc_awalkl_tmp}"
  unset lc_awalkl_tmp
  return 0
}
#[cf]
