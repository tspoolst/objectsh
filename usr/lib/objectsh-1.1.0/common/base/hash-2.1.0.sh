#!/bin/sh
##a colloction of hash handling tools

##if using bash insure extglob is on
[[ -n "$BASH_VERSION" ]] && shopt -s extglob
if [[ -n "$BASH_VERSION" && "${BASH_VERSION%%.*}" -ge 4 ]] ; then
#[of]:function hashkeys {
function hashkeys {
#[c]-|var hash [key...key...]
  unset lc_hashkeys_key
  typeset lc_hashkeys_return lc_hashkeys_hash
  lc_hashkeys_return="$1"
  lc_hashkeys_hash="$2"
  while [[ $# -gt 2 ]] ; do
    hashconvert2key lc_hashkeys_key "$3"
    lc_hashkeys_hash="${lc_hashkeys_hash}_${lc_hashkeys_key}"
    shift
  done
  eval "
    if [[ \${${lc_hashkeys_hash}__count} -gt 0 ]] ; then
      lc_hashkeys_key=\${${lc_hashkeys_hash}__first}
      while eval [[ -n \\\"\\\${${lc_hashkeys_hash}__meta_\${lc_hashkeys_key}[2]}\\\" ]] ; do
        eval \"
          typeset lc_hashkeys_hashkeys
          lc_hashkeys_hashkeys[\\\${#lc_hashkeys_hashkeys[@]}]=\\\"\\\${${lc_hashkeys_hash}__meta_\${lc_hashkeys_key}[0]}\\\"
          lc_hashkeys_key=\\\"\\\${${lc_hashkeys_hash}__meta_\${lc_hashkeys_key}[2]}\\\"
        \"
      done
      eval \"
        typeset lc_hashkeys_hashkeys
        lc_hashkeys_hashkeys[\\\${#lc_hashkeys_hashkeys[@]}]=\\\"\\\${${lc_hashkeys_hash}__meta_\${lc_hashkeys_key}[0]}\\\"
      \"
    else
      [[ \"${lc_hashkeys_return}\" != \"-\" ]] && unset ${lc_hashkeys_return}
      unset lc_hashkeys_key
      return 1
    fi
  "
  if [[ "${lc_hashkeys_return}" = "-" ]] ; then
    echo "${lc_hashkeys_hashkeys[@]}"
  else
    eval "aset ${lc_hashkeys_return} \"\${lc_hashkeys_hashkeys[@]}\""
  fi
  unset lc_hashkeys_key
  return 0
}
#[cf]
#[of]:function hashdump {
function hashdump {
#[c]-r hash [key...key...]
  typeset _hash _key _id _tmp _raw _filter
  _filter=true
  if [[ "$1" = "-r" ]] ; then
    _raw=true
    unset _filter
    shift
  fi
  _hash=$1
  while [[ $# -gt 1 ]] ; do
    hashconvert2key _key "$2"
    _hash="${_hash}_${_key}"
    shift
  done
  ##dump entire hash to stdout
  {
    set | grep ^${_hash}__first | (read -r i && echo "${_raw:+${i}}${_filter:+${i#*_}}")
    set | grep ^${_hash}__count | (read -r i && echo "${_raw:+${i}}${_filter:+${i#*_}}")
    if [[ -n "$BASH_VERSION" ]] ; then
      ##force output to a ksh friendly style
      for _key in $(eval echo \${!${_hash}_*}) ; do
        [[  "${_key}" = "${_hash}__first" || \
            "${_key}" = "${_hash}__count" || \
            "${_key}" = "${_hash}__last" ]] && continue
        for _id in $(eval echo \${!${_key}[@]}) ; do
          eval "_tmp=\"\${${_key}[_id]}\""
          _tmp=$(set | grep ^_tmp=)
          echo "${_raw:+${_key}}${_filter:+${_key#*_}}[${_id}]=${_tmp#_tmp=}"
        done
      done
    else
      ##our current shell is ksh -- a simple set dump will do
      set | grep -e "^${_hash}_" | (
        while read -r i ; do
          [[  "${i}" = "${_hash}__first" || \
              "${i}" = "${_hash}__count" || \
              "${i}" = "${_hash}__last" ]] && continue
          echo "${_raw:+${i}}${_filter:+${i#*_}}"
        done
      )
    fi
    set | grep ^${_hash}__last | (read -r i && echo "${_raw:+${i}}${_filter:+${i#*_}}")
  }
  return 0
}
#[cf]
#[of]:function hashsave {
function hashsave {
#[c]-r hash [key...key...] filename
  typeset _hash _file
  aset _hash "$@"
  apop _file _hash
  ##do we have permission to write the hashtable file?
  if [[ -d "${_file}" ]] ; then
    echo "hashtable file \"${_file}\" already exist as a directory" >&2
    return 1
  fi
  ##this checks write permissons and clears the hashtable file
  if ! : > "${_file}" >/dev/null 2>&1 ; then
    echo "the hashtable file \"${_file}\" is not writeable" >&2
    return 1
  fi
  ##dump entire hash to file
  hashdump "${_hash[@]}"  > "${_file}"
  return 0
}
#[cf]
#[of]:function hashload {
function hashload {
#[c]hash [key...key...] filename
  typeset _hash _key _file
  _hash=$1
  while [[ $# -gt 2 ]] ; do
    hashconvert2key _key "$2"
    _hash="${_hash}_${_key}"
    shift
  done
  _file="$2"

  ##do we have permission to read the hashtable file and does it have content?
  if [[ ! -e "${_file}" ]] ; then
    echo "the hashtable file \"${_file}\" does not exist" >&2
    return 1
  fi
  if [[ ! -r "${_file}" ]] ; then
    echo "the hashtable file \"${_file}\" is not readable" >&2
    return 1
  fi
  if [[ ! -s "${_file}" ]] ; then
    echo "the hashtable file \"${_file}\" has no content" >&2
    return 1
  fi
  if ! grep -q -e ^_last= -e __last= "${_file}" ; then
    echo "the hashtable file \"${_file}\" is incomplete or damaged" >&2
    return 1
  fi
  ##is the hashtable file complete, does the hashtable file have a last= element
  while read -r _key ; do
    eval ${_hash}_${_key}
  done < "${_file}"
  ##load entire hash from file as named hash
  return 0
}
#[cf]
#[of]:function hashdel {
if [[ -n "$BASH_VERSION" ]] ; then
  function hashdel {
#[c]  hash
    typeset lc_hashdel_hash
    lc_hashdel_hash="$1"
    while [[ $# -gt 1 ]] ; do
      hashconvert2key lc_hashdel_key "$2"
      lc_hashdel_hash="${lc_hashdel_hash}_${lc_hashdel_key}"
      shift
    done
    eval "
      unset \${!${lc_hashdel_hash}_*}
    "
    return 0
  }
else
  function hashdel {
#[c]  hash
    unset lc_hashdel_key
    typeset lc_hashdel_hash
    lc_hashdel_hash="$1"
    while [[ $# -gt 1 ]] ; do
      hashconvert2key lc_hashdel_key "$2"
      lc_hashdel_hash="${lc_hashdel_hash}_${lc_hashdel_key}"
      shift
    done
    set | grep \
      -e "^${lc_hashdel_hash}_" | \
      while read lc_hashdel_hash ; do
        eval "
          unset ${lc_hashdel_hash%%=*}
        "
      done
    unset lc_hashdel_key
    return 0
  }
fi
#[cf]
#[of]:function hashsetkey {
function hashsetkey {
#[c]hash key [key...key...] [+=|-=|=] value
#[c]
#[c]hash key key += value
#[c]key key += value
#[c]key += value
#[c]
#[c]hash key key key value
#[c]key key key value
#[c]key key value
#[c]
#[c]hash key value
#[c]
#[c]hash key += value
#[c]key += value
#[c]
#[c]
  unset lc_hashsetkey_hashpart lc_hashsetkey_key
  typeset lc_hashsetkey_hash lc_hashsetkey_keyname lc_hashsetkey_math
  typeset _forcelower
  if [[ "$1" = "-l" ]] ; then
    _forcelower="-l"
    shift
  fi

  lc_hashsetkey_hash="$1"
  if [[ $# -eq 3 ]] ; then
    lc_hashsetkey_keyname="$2"
  elif [[ $# -gt 3 ]] ; then
    while [[ $# -gt 3 ]] ; do
      shift
      hashconvert2key lc_hashsetkey_hashpart "$1"
      lc_hashsetkey_hash="${lc_hashsetkey_hash}_${lc_hashsetkey_hashpart}"
    done
    if [[ "$2" = @(+=|-=|=) ]] ; then
      lc_hashsetkey_keyname="$1"
      lc_hashsetkey_math="$2"
    else
      lc_hashsetkey_keyname="$2"
    fi
  else
    unset lc_hashsetkey_hashpart lc_hashsetkey_key
    return 1
  fi
  hashconvert2key ${_forcelower} lc_hashsetkey_key "${lc_hashsetkey_keyname}"

  eval "
    [[ -z \"\${${lc_hashsetkey_hash}__first}\" ]] && ${lc_hashsetkey_hash}__first=${lc_hashsetkey_key}
    if [[ -z \"\${${lc_hashsetkey_hash}__meta_${lc_hashsetkey_key}[0]}\" ]] ; then
      ${lc_hashsetkey_hash}__meta_${lc_hashsetkey_key}[0]=\"\${lc_hashsetkey_keyname}\"
      if [[ -n \"\${${lc_hashsetkey_hash}__last}\" ]] ; then
        eval \"\${lc_hashsetkey_hash}__meta_\${${lc_hashsetkey_hash}__last}[2]=${lc_hashsetkey_key}\"
        ${lc_hashsetkey_hash}__meta_${lc_hashsetkey_key}[1]=\${${lc_hashsetkey_hash}__last}
      fi
      ${lc_hashsetkey_hash}__last=${lc_hashsetkey_key}
      ${lc_hashsetkey_hash}__count=\"\${${lc_hashsetkey_hash}__count:-0}\"
      let \"${lc_hashsetkey_hash}__count+=1\"
    fi
  "
  if [[ -n "${lc_hashsetkey_math}" ]] ; then
    let "${lc_hashsetkey_hash}__data_${lc_hashsetkey_key} ${lc_hashsetkey_math} $3"
  else
    eval "${lc_hashsetkey_hash}__data_${lc_hashsetkey_key}=\"\$3\""
  fi
  unset lc_hashsetkey_hashpart lc_hashsetkey_key
  return 0
}
#[cf]
#[of]:function hashgetkey {
function hashgetkey {
#[c]!|-|var hash key [key...key...]
  unset lc_hashgetkey_hashpart lc_hashgetkey_key
  typeset lc_hashgetkey_return lc_hashgetkey_hash
  typeset _forcelower
  if [[ "$1" = "-l" ]] ; then
    _forcelower="-l"
    shift
  fi

  lc_hashgetkey_return="$1"
  lc_hashgetkey_hash="$2"
  while [[ $# -gt 3 ]] ; do
    hashconvert2key lc_hashgetkey_hashpart "$3"
    lc_hashgetkey_hash="${lc_hashgetkey_hash}_${lc_hashgetkey_hashpart}"
    shift
  done
  hashconvert2key ${_forcelower} lc_hashgetkey_key "$3"

  if [[ "${lc_hashgetkey_return}" = "!" ]] ; then
    :
  elif [[ "${lc_hashgetkey_return}" = "-" ]] ; then
    eval "echo \"\${${lc_hashgetkey_hash}__data_${lc_hashgetkey_key}}\""
  else
    eval "${lc_hashgetkey_return}=\"\${${lc_hashgetkey_hash}__data_${lc_hashgetkey_key}}\""
  fi
  isset "${lc_hashgetkey_hash}__meta_${lc_hashgetkey_key}"
  lc_hashgetkey_return=$?
  unset lc_hashgetkey_hashpart lc_hashgetkey_key
  return ${lc_hashgetkey_return}
}
#[cf]
#[of]:function hashdelkey {
function hashdelkey {
#[c]hash key [key...key...]
  unset lc_hashdelkey_hashpart lc_hashdelkey_key
  typeset lc_hashdelkey_hash
  typeset _forcelower
  if [[ "$1" = "-l" ]] ; then
    _forcelower="-l"
    shift
  fi

  lc_hashdelkey_hash="$1"
  while [[ $# -gt 2 ]] ; do
    hashconvert2key lc_hashdelkey_hashpart "$2"
    lc_hashdelkey_hash="${lc_hashdelkey_hash}_${lc_hashdelkey_hashpart}"
    shift
  done
  hashconvert2key ${_forcelower} lc_hashdelkey_key "$2"

  eval "
    if [[ -n \"\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[0]}\" ]] ; then
      if [[ \"\${${lc_hashdelkey_hash}__first}\" = \"${lc_hashdelkey_key}\" ]] ; then
        ${lc_hashdelkey_hash}__first=\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[2]}
        eval \"unset \${lc_hashdelkey_hash}__meta_\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[2]}[1]\"
      elif [[ \"\${${lc_hashdelkey_hash}__last}\" = \"${lc_hashdelkey_key}\" ]] ; then
        ${lc_hashdelkey_hash}__last=\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[1]}
        eval \"unset \${lc_hashdelkey_hash}__meta_\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[1]}[2]\"
      else
        eval \"
          \${lc_hashdelkey_hash}__meta_\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[1]}[2]=\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[2]}
          \${lc_hashdelkey_hash}__meta_\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[2]}[1]=\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[1]}
        \"
      fi
      unset ${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}
      unset ${lc_hashdelkey_hash}__data_${lc_hashdelkey_key}
      let \"${lc_hashdelkey_hash}__count-=1\"
      if [[ \${${lc_hashdelkey_hash}__count} -eq 0 ]] ; then
        unset ${lc_hashdelkey_hash}__first
        unset ${lc_hashdelkey_hash}__last
        unset ${lc_hashdelkey_hash}__count
      fi
    else
      unset lc_hashdelkey_hashpart lc_hashdelkey_key
      return 1
    fi
  "
  unset lc_hashdelkey_hashpart lc_hashdelkey_key
  return 0
}
#[cf]
#[of]:function hashgetsize {
function hashgetsize {
#[c]!|-|var hash [key...key...]
  unset lc_hashgetsize_hashpart
  typeset lc_hashgetsize_var lc_hashgetsize_hash lc_hashgetsize_count lc_hashgetsize_return
  lc_hashgetsize_var="$1"
  lc_hashgetsize_hash="$2"
  while [[ $# -gt 2 ]] ; do
    hashconvert2key lc_hashgetsize_hashpart "$3"
    lc_hashgetsize_hash="${lc_hashgetsize_hash}_${lc_hashgetsize_hashpart}"
    shift
  done
  if [[ "${lc_hashgetsize_var}" = "!" ]] ; then
    :
  elif [[ "${lc_hashgetsize_var}" = "-" ]] ; then
    eval "echo \"\${${lc_hashgetsize_hash}__count-0}\""
  else
    eval "${lc_hashgetsize_var}=\"\${${lc_hashgetsize_hash}__count-0}\""
  fi
  unset lc_hashgetsize_hashpart
  isset "${lc_hashgetsize_hash}__count"
}
#[cf]
#[of]:function hashconvert2key {
if [[ -n "$BASH_VERSION" ]] ; then
  function hashconvert2key {
#[c]  [var] value
    typeset lc_hashconvert2key_string lc_hashconvert2key_char lc_hashconvert2key_hexpart lc_hashconvert2key_key
    typeset _forcelower
    _forcelower=false
    if [[ "$1" = "-l" ]] ; then
      _forcelower=true
      shift
    fi
    lc_hashconvert2key_string="${2-$1}"
    if [[ -z "${lc_hashconvert2key_string}" ]] ; then
      echo "hash error, empty keys are not permitted."
      exit 1
    fi
    if ! ${_forcelower} && [[ "${lc_hashconvert2key_string}" = +([[:alnum:]]) ]] ; then
      lc_hashconvert2key_key="${lc_hashconvert2key_string}"
    else
      while [[ ${#lc_hashconvert2key_string} -gt 0 ]] ; do
        lc_hashconvert2key_char="${lc_hashconvert2key_string%"${lc_hashconvert2key_string#?}"}"
        if [[ "${lc_hashconvert2key_char}" = [[:alnum:]] ]] ; then
          if ${_forcelower} && [[ "${lc_hashconvert2key_char}" = [[:alpha:]] ]] ; then
            printf -v lc_hashconvert2key_char %o $((36#${lc_hashconvert2key_char}+87))
            lc_hashconvert2key_key="${lc_hashconvert2key_key}$(echo -ne "\\${lc_hashconvert2key_char}")"
          else
            lc_hashconvert2key_key="${lc_hashconvert2key_key}${lc_hashconvert2key_char}"
          fi
        else
          printf -v lc_hashconvert2key_hexpart %02X "'${lc_hashconvert2key_char}"
          lc_hashconvert2key_key="${lc_hashconvert2key_key}${lc_hashconvert2key_hexpart}"
        fi
        lc_hashconvert2key_string="${lc_hashconvert2key_string#?}"
      done
    fi
    if [[ $# -eq 1 ]] ; then
      echo "${lc_hashconvert2key_key}"
    else
      eval "$1=\"\${lc_hashconvert2key_key}\""
    fi
    return 0
  }
else
  function hashconvert2key {
#[c]  [var] value
    typeset lc_hashconvert2key_string lc_hashconvert2key_char lc_hashconvert2key_hexpart lc_hashconvert2key_key
    typeset _forcelower
    _forcelower=false
    if [[ "$1" = "-l" ]] ; then
      typeset -l lc_hashconvert2key_string
      shift
    fi
  
    lc_hashconvert2key_string="${2-$1}"
    if [[ -z "${lc_hashconvert2key_string}" ]] ; then
      echo "hash error, attempted to create an empty key."
      exit 1
    fi
    if ! ${_forcelower} && [[ "${lc_hashconvert2key_string}" = +([[:alnum:]]) ]] ; then
      lc_hashconvert2key_key="${lc_hashconvert2key_string}"
    else
      while [[ ${#lc_hashconvert2key_string} -gt 0 ]] ; do
        lc_hashconvert2key_char="${lc_hashconvert2key_string%"${lc_hashconvert2key_string#?}"}"
        if [[ "${lc_hashconvert2key_char}" = [[:alnum:]] ]] ; then
          lc_hashconvert2key_key="${lc_hashconvert2key_key}${lc_hashconvert2key_char}"
        else
          lc_hashconvert2key_hexpart=$(printf  %02X "'${lc_hashconvert2key_char}")
          lc_hashconvert2key_key="${lc_hashconvert2key_key}${lc_hashconvert2key_hexpart}"
        fi
        lc_hashconvert2key_string="${lc_hashconvert2key_string#?}"
      done
    fi
    if [[ $# -eq 1 ]] ; then
      echo "${lc_hashconvert2key_key}"
    else
      eval "$1=\"\${lc_hashconvert2key_key}\""
    fi
    return 0
  }
fi
#[cf]
else
#[of]:function hashkeys {
function hashkeys {
#[c]-|var hash [key...key...]
  unset lc_hashkeys_key
  typeset lc_hashkeys_return lc_hashkeys_hash
  lc_hashkeys_return="$1"
  lc_hashkeys_hash="$2"
  while [[ $# -gt 2 ]] ; do
    hashconvert2key lc_hashkeys_key "$3"
    lc_hashkeys_hash="${lc_hashkeys_hash}_${lc_hashkeys_key}"
    shift
  done
  eval "
    if [[ \${${lc_hashkeys_hash}__count} -gt 0 ]] ; then
      lc_hashkeys_key=\${${lc_hashkeys_hash}__first}
      while eval [[ -n \\\"\\\${${lc_hashkeys_hash}__meta_\${lc_hashkeys_key}[2]}\\\" ]] ; do
        eval \"
          typeset lc_hashkeys_hashkeys
          lc_hashkeys_hashkeys[\\\${#lc_hashkeys_hashkeys[@]}]=\\\"\\\${${lc_hashkeys_hash}__meta_\${lc_hashkeys_key}[0]}\\\"
          lc_hashkeys_key=\\\"\\\${${lc_hashkeys_hash}__meta_\${lc_hashkeys_key}[2]}\\\"
        \"
      done
      eval \"
        typeset lc_hashkeys_hashkeys
        lc_hashkeys_hashkeys[\\\${#lc_hashkeys_hashkeys[@]}]=\\\"\\\${${lc_hashkeys_hash}__meta_\${lc_hashkeys_key}[0]}\\\"
      \"
    else
      [[ \"${lc_hashkeys_return}\" != \"-\" ]] && unset ${lc_hashkeys_return}
      unset lc_hashkeys_key
      return 1
    fi
  "
  if [[ "${lc_hashkeys_return}" = "-" ]] ; then
    echo "${lc_hashkeys_hashkeys[@]}"
  else
    eval "aset ${lc_hashkeys_return} \"\${lc_hashkeys_hashkeys[@]}\""
  fi
  unset lc_hashkeys_key
  return 0
}
#[cf]
#[of]:function hashdump {
function hashdump {
#[c]-r hash [key...key...]
  typeset _hash _key _id _tmp _raw _filter
  _filter=true
  if [[ "$1" = "-r" ]] ; then
    _raw=true
    unset _filter
    shift
  fi
  _hash=$1
  while [[ $# -gt 1 ]] ; do
    hashconvert2key _key "$2"
    _hash="${_hash}_${_key}"
    shift
  done
  ##dump entire hash to stdout
  {
    set | grep ^${_hash}__first | (read -r i && echo "${_raw:+${i}}${_filter:+${i#*_}}")
    set | grep ^${_hash}__count | (read -r i && echo "${_raw:+${i}}${_filter:+${i#*_}}")
    if [[ -n "$BASH_VERSION" ]] ; then
      ##force output to a ksh friendly style
      for _key in $(eval echo \${!${_hash}_*}) ; do
        [[  "${_key}" = "${_hash}__first" || \
            "${_key}" = "${_hash}__count" || \
            "${_key}" = "${_hash}__last" ]] && continue
        for _id in $(eval echo \${!${_key}[@]}) ; do
          eval "_tmp=\"\${${_key}[_id]}\""
          _tmp=$(set | grep ^_tmp=)
          echo "${_raw:+${_key}}${_filter:+${_key#*_}}[${_id}]=${_tmp#_tmp=}"
        done
      done
    else
      ##our current shell is ksh -- a simple set dump will do
      set | grep -e "^${_hash}_" | (
        while read -r i ; do
          [[  "${i}" = "${_hash}__first" || \
              "${i}" = "${_hash}__count" || \
              "${i}" = "${_hash}__last" ]] && continue
          echo "${_raw:+${i}}${_filter:+${i#*_}}"
        done
      )
    fi
    set | grep ^${_hash}__last | (read -r i && echo "${_raw:+${i}}${_filter:+${i#*_}}")
  }
  return 0
}
#[cf]
#[of]:function hashsave {
function hashsave {
#[c]-r hash [key...key...] filename
  typeset _hash _file
  aset _hash "$@"
  apop _file _hash
  ##do we have permission to write the hashtable file?
  if [[ -d "${_file}" ]] ; then
    echo "hashtable file \"${_file}\" already exist as a directory" >&2
    return 1
  fi
  ##this checks write permissons and clears the hashtable file
  if ! : > "${_file}" >/dev/null 2>&1 ; then
    echo "the hashtable file \"${_file}\" is not writeable" >&2
    return 1
  fi
  ##dump entire hash to file
  hashdump "${_hash[@]}"  > "${_file}"
  return 0
}
#[cf]
#[of]:function hashload {
function hashload {
#[c]hash [key...key...] filename
  typeset _hash _key _file
  _hash=$1
  while [[ $# -gt 2 ]] ; do
    hashconvert2key _key "$2"
    _hash="${_hash}_${_key}"
    shift
  done
  _file="$2"

  ##do we have permission to read the hashtable file and does it have content?
  if [[ ! -e "${_file}" ]] ; then
    echo "the hashtable file \"${_file}\" does not exist" >&2
    return 1
  fi
  if [[ ! -r "${_file}" ]] ; then
    echo "the hashtable file \"${_file}\" is not readable" >&2
    return 1
  fi
  if [[ ! -s "${_file}" ]] ; then
    echo "the hashtable file \"${_file}\" has no content" >&2
    return 1
  fi
  if ! grep -q -e ^_last= -e __last= "${_file}" ; then
    echo "the hashtable file \"${_file}\" is incomplete or damaged" >&2
    return 1
  fi
  ##is the hashtable file complete, does the hashtable file have a last= element
  while read -r _key ; do
    eval ${_hash}_${_key}
  done < "${_file}"
  ##load entire hash from file as named hash
  return 0
}
#[cf]
#[of]:function hashdel {
if [[ -n "$BASH_VERSION" ]] ; then
  function hashdel {
#[c]  hash
    typeset lc_hashdel_hash
    lc_hashdel_hash="$1"
    while [[ $# -gt 1 ]] ; do
      hashconvert2key lc_hashdel_key "$2"
      lc_hashdel_hash="${lc_hashdel_hash}_${lc_hashdel_key}"
      shift
    done
    eval "
      unset \${!${lc_hashdel_hash}_*}
    "
    return 0
  }
else
  function hashdel {
#[c]  hash
    unset lc_hashdel_key
    typeset lc_hashdel_hash
    lc_hashdel_hash="$1"
    while [[ $# -gt 1 ]] ; do
      hashconvert2key lc_hashdel_key "$2"
      lc_hashdel_hash="${lc_hashdel_hash}_${lc_hashdel_key}"
      shift
    done
    set | grep \
      -e "^${lc_hashdel_hash}_" | \
      while read lc_hashdel_hash ; do
        eval "
          unset ${lc_hashdel_hash%%=*}
        "
      done
    unset lc_hashdel_key
    return 0
  }
fi
#[cf]
#[of]:function hashsetkey {
function hashsetkey {
#[c]hash key [key...key...] [+=|-=|=] value
#[c]
#[c]hash key key += value
#[c]key key += value
#[c]key += value
#[c]
#[c]hash key key key value
#[c]key key key value
#[c]key key value
#[c]
#[c]hash key value
#[c]
#[c]hash key += value
#[c]key += value
#[c]
#[c]
  unset lc_hashsetkey_hashpart lc_hashsetkey_key
  typeset lc_hashsetkey_hash lc_hashsetkey_keyname lc_hashsetkey_math
  typeset _forcelower
  if [[ "$1" = "-l" ]] ; then
    _forcelower="-l"
    shift
  fi

  lc_hashsetkey_hash="$1"
  if [[ $# -eq 3 ]] ; then
    lc_hashsetkey_keyname="$2"
  elif [[ $# -gt 3 ]] ; then
    while [[ $# -gt 3 ]] ; do
      shift
      hashconvert2key lc_hashsetkey_hashpart "$1"
      lc_hashsetkey_hash="${lc_hashsetkey_hash}_${lc_hashsetkey_hashpart}"
    done
    if [[ "$2" = @(+=|-=|=) ]] ; then
      lc_hashsetkey_keyname="$1"
      lc_hashsetkey_math="$2"
    else
      lc_hashsetkey_keyname="$2"
    fi
  else
    unset lc_hashsetkey_hashpart lc_hashsetkey_key
    return 1
  fi
  hashconvert2key ${_forcelower} lc_hashsetkey_key "${lc_hashsetkey_keyname}"

  eval "
    [[ -z \"\${${lc_hashsetkey_hash}__first}\" ]] && ${lc_hashsetkey_hash}__first=${lc_hashsetkey_key}
    if [[ -z \"\${${lc_hashsetkey_hash}__meta_${lc_hashsetkey_key}[0]}\" ]] ; then
      ${lc_hashsetkey_hash}__meta_${lc_hashsetkey_key}[0]=\"\${lc_hashsetkey_keyname}\"
      if [[ -n \"\${${lc_hashsetkey_hash}__last}\" ]] ; then
        eval \"\${lc_hashsetkey_hash}__meta_\${${lc_hashsetkey_hash}__last}[2]=${lc_hashsetkey_key}\"
        ${lc_hashsetkey_hash}__meta_${lc_hashsetkey_key}[1]=\${${lc_hashsetkey_hash}__last}
      fi
      ${lc_hashsetkey_hash}__last=${lc_hashsetkey_key}
      ${lc_hashsetkey_hash}__count=\"\${${lc_hashsetkey_hash}__count:-0}\"
      let \"${lc_hashsetkey_hash}__count+=1\"
    fi
  "
  if [[ -n "${lc_hashsetkey_math}" ]] ; then
    let "${lc_hashsetkey_hash}__data_${lc_hashsetkey_key} ${lc_hashsetkey_math} $3"
  else
    eval "${lc_hashsetkey_hash}__data_${lc_hashsetkey_key}=\"\$3\""
  fi
  unset lc_hashsetkey_hashpart lc_hashsetkey_key
  return 0
}
#[cf]
#[of]:function hashgetkey {
function hashgetkey {
#[c]!|-|var hash key [key...key...]
  unset lc_hashgetkey_hashpart lc_hashgetkey_key
  typeset lc_hashgetkey_return lc_hashgetkey_hash
  typeset _forcelower
  if [[ "$1" = "-l" ]] ; then
    _forcelower="-l"
    shift
  fi

  lc_hashgetkey_return="$1"
  lc_hashgetkey_hash="$2"
  while [[ $# -gt 3 ]] ; do
    hashconvert2key lc_hashgetkey_hashpart "$3"
    lc_hashgetkey_hash="${lc_hashgetkey_hash}_${lc_hashgetkey_hashpart}"
    shift
  done
  hashconvert2key ${_forcelower} lc_hashgetkey_key "$3"

  if [[ "${lc_hashgetkey_return}" = "!" ]] ; then
    :
  elif [[ "${lc_hashgetkey_return}" = "-" ]] ; then
    eval "echo \"\${${lc_hashgetkey_hash}__data_${lc_hashgetkey_key}}\""
  else
    eval "${lc_hashgetkey_return}=\"\${${lc_hashgetkey_hash}__data_${lc_hashgetkey_key}}\""
  fi
  isset "${lc_hashgetkey_hash}__meta_${lc_hashgetkey_key}"
  lc_hashgetkey_return=$?
  unset lc_hashgetkey_hashpart lc_hashgetkey_key
  return ${lc_hashgetkey_return}
}
#[cf]
#[of]:function hashdelkey {
function hashdelkey {
#[c]hash key [key...key...]
  unset lc_hashdelkey_hashpart lc_hashdelkey_key
  typeset lc_hashdelkey_hash
  typeset _forcelower
  if [[ "$1" = "-l" ]] ; then
    _forcelower="-l"
    shift
  fi

  lc_hashdelkey_hash="$1"
  while [[ $# -gt 2 ]] ; do
    hashconvert2key lc_hashdelkey_hashpart "$2"
    lc_hashdelkey_hash="${lc_hashdelkey_hash}_${lc_hashdelkey_hashpart}"
    shift
  done
  hashconvert2key ${_forcelower} lc_hashdelkey_key "$2"

  eval "
    if [[ -n \"\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[0]}\" ]] ; then
      if [[ \"\${${lc_hashdelkey_hash}__first}\" = \"${lc_hashdelkey_key}\" ]] ; then
        ${lc_hashdelkey_hash}__first=\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[2]}
        eval \"unset \${lc_hashdelkey_hash}__meta_\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[2]}[1]\"
      elif [[ \"\${${lc_hashdelkey_hash}__last}\" = \"${lc_hashdelkey_key}\" ]] ; then
        ${lc_hashdelkey_hash}__last=\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[1]}
        eval \"unset \${lc_hashdelkey_hash}__meta_\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[1]}[2]\"
      else
        eval \"
          \${lc_hashdelkey_hash}__meta_\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[1]}[2]=\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[2]}
          \${lc_hashdelkey_hash}__meta_\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[2]}[1]=\${${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}[1]}
        \"
      fi
      unset ${lc_hashdelkey_hash}__meta_${lc_hashdelkey_key}
      unset ${lc_hashdelkey_hash}__data_${lc_hashdelkey_key}
      let \"${lc_hashdelkey_hash}__count-=1\"
      if [[ \${${lc_hashdelkey_hash}__count} -eq 0 ]] ; then
        unset ${lc_hashdelkey_hash}__first
        unset ${lc_hashdelkey_hash}__last
        unset ${lc_hashdelkey_hash}__count
      fi
    else
      unset lc_hashdelkey_hashpart lc_hashdelkey_key
      return 1
    fi
  "
  unset lc_hashdelkey_hashpart lc_hashdelkey_key
  return 0
}
#[cf]
#[of]:function hashgetsize {
function hashgetsize {
#[c]!|-|var hash [key...key...]
  unset lc_hashgetsize_hashpart
  typeset lc_hashgetsize_var lc_hashgetsize_hash lc_hashgetsize_count lc_hashgetsize_return
  lc_hashgetsize_var="$1"
  lc_hashgetsize_hash="$2"
  while [[ $# -gt 2 ]] ; do
    hashconvert2key lc_hashgetsize_hashpart "$3"
    lc_hashgetsize_hash="${lc_hashgetsize_hash}_${lc_hashgetsize_hashpart}"
    shift
  done
  if [[ "${lc_hashgetsize_var}" = "!" ]] ; then
    :
  elif [[ "${lc_hashgetsize_var}" = "-" ]] ; then
    eval "echo \"\${${lc_hashgetsize_hash}__count-0}\""
  else
    eval "${lc_hashgetsize_var}=\"\${${lc_hashgetsize_hash}__count-0}\""
  fi
  unset lc_hashgetsize_hashpart
  isset "${lc_hashgetsize_hash}__count"
}
#[cf]
#[of]:function hashconvert2key {
if [[ -n "$BASH_VERSION" ]] ; then
  function hashconvert2key {
#[c]  [var] value
    typeset lc_hashconvert2key_string lc_hashconvert2key_char lc_hashconvert2key_hexpart lc_hashconvert2key_key
    typeset _forcelower
    _forcelower=false
    if [[ "$1" = "-l" ]] ; then
      _forcelower=true
      shift
    fi
    lc_hashconvert2key_string="${2-$1}"
    if [[ -z "${lc_hashconvert2key_string}" ]] ; then
      echo "hash error, empty keys are not permitted."
      exit 1
    fi
    if ! ${_forcelower} && [[ "${lc_hashconvert2key_string}" = +([[:alnum:]]) ]] ; then
      lc_hashconvert2key_key="${lc_hashconvert2key_string}"
    else
      while [[ ${#lc_hashconvert2key_string} -gt 0 ]] ; do
        lc_hashconvert2key_char="${lc_hashconvert2key_string%"${lc_hashconvert2key_string#?}"}"
        if [[ "${lc_hashconvert2key_char}" = [[:alnum:]] ]] ; then
          if ${_forcelower} && [[ "${lc_hashconvert2key_char}" = [[:alpha:]] ]] ; then
            printf -v lc_hashconvert2key_char %o $((36#${lc_hashconvert2key_char}+87))
            lc_hashconvert2key_key="${lc_hashconvert2key_key}$(echo -ne "\\${lc_hashconvert2key_char}")"
          else
            lc_hashconvert2key_key="${lc_hashconvert2key_key}${lc_hashconvert2key_char}"
          fi
        else
          printf -v lc_hashconvert2key_hexpart %02X "'${lc_hashconvert2key_char}"
          lc_hashconvert2key_key="${lc_hashconvert2key_key}${lc_hashconvert2key_hexpart}"
        fi
        lc_hashconvert2key_string="${lc_hashconvert2key_string#?}"
      done
    fi
    if [[ $# -eq 1 ]] ; then
      echo "${lc_hashconvert2key_key}"
    else
      eval "$1=\"\${lc_hashconvert2key_key}\""
    fi
    return 0
  }
else
  function hashconvert2key {
#[c]  [var] value
    typeset lc_hashconvert2key_string lc_hashconvert2key_char lc_hashconvert2key_hexpart lc_hashconvert2key_key
    typeset _forcelower
    _forcelower=false
    if [[ "$1" = "-l" ]] ; then
      typeset -l lc_hashconvert2key_string
      shift
    fi
  
    lc_hashconvert2key_string="${2-$1}"
    if [[ -z "${lc_hashconvert2key_string}" ]] ; then
      echo "hash error, attempted to create an empty key."
      exit 1
    fi
    if ! ${_forcelower} && [[ "${lc_hashconvert2key_string}" = +([[:alnum:]]) ]] ; then
      lc_hashconvert2key_key="${lc_hashconvert2key_string}"
    else
      while [[ ${#lc_hashconvert2key_string} -gt 0 ]] ; do
        lc_hashconvert2key_char="${lc_hashconvert2key_string%"${lc_hashconvert2key_string#?}"}"
        if [[ "${lc_hashconvert2key_char}" = [[:alnum:]] ]] ; then
          lc_hashconvert2key_key="${lc_hashconvert2key_key}${lc_hashconvert2key_char}"
        else
          lc_hashconvert2key_hexpart=$(printf  %02X "'${lc_hashconvert2key_char}")
          lc_hashconvert2key_key="${lc_hashconvert2key_key}${lc_hashconvert2key_hexpart}"
        fi
        lc_hashconvert2key_string="${lc_hashconvert2key_string#?}"
      done
    fi
    if [[ $# -eq 1 ]] ; then
      echo "${lc_hashconvert2key_key}"
    else
      eval "$1=\"\${lc_hashconvert2key_key}\""
    fi
    return 0
  }
fi
#[cf]
fi
