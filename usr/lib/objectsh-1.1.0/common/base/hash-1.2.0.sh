#!/bin/bash
##a colloction of hash handling tools
#[of]:hashkeys() {
hashkeys() {
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
#[of]:hashdump() {
hashdump() {
#[c]-r hash [key...key...]
  typeset lc_hashdump_hash lc_hashdump_key lc_hashdump_id lc_hashdump_raw lc_hashdump_tmp lc_hashdump_filter
  lc_hashdump_filter=true
  if [[ "$1" = "-r" ]] ; then
    lc_hashdump_raw=true
    unset lc_hashdump_filter
    shift
  fi
  lc_hashdump_hash=$1
  while [[ $# -gt 1 ]] ; do
    hashconvert2key lc_hashdump_key "$2"
    lc_hashdump_hash="${lc_hashdump_hash}_${lc_hashdump_key}"
    shift
  done
  ##dump entire hash to stdout
  {
    set | grep ^${lc_hashdump_hash}__first | (read -r i && echo "${lc_hashdump_raw:+${i}}${lc_hashdump_filter:+${i#*_}}")
    set | grep ^${lc_hashdump_hash}__count | (read -r i && echo "${lc_hashdump_raw:+${i}}${lc_hashdump_filter:+${i#*_}}")
    if [[ -n "$BASH_VERSION" ]] ; then
      ##force output to a ksh friendly style
      for lc_hashdump_key in $(eval echo \${!${lc_hashdump_hash}_*}) ; do
        [[  "${lc_hashdump_key}" = "${lc_hashdump_hash}__first" || \
            "${lc_hashdump_key}" = "${lc_hashdump_hash}__count" || \
            "${lc_hashdump_key}" = "${lc_hashdump_hash}__last" ]] && continue
        for lc_hashdump_id in $(eval echo \${!${lc_hashdump_key}[@]}) ; do
          eval "lc_hashdump_tmp=\"\${${lc_hashdump_key}[lc_hashdump_id]}\""
          lc_hashdump_tmp=$(set | grep ^lc_hashdump_tmp=)
          if [[ -z "${lc_hashdump_key##*__data_*}" ]] ; then
            echo "${lc_hashdump_raw:+${lc_hashdump_key}}${lc_hashdump_filter:+${lc_hashdump_key#*_}}=${lc_hashdump_tmp#lc_hashdump_tmp=}"
          else
            echo "${lc_hashdump_raw:+${lc_hashdump_key}}${lc_hashdump_filter:+${lc_hashdump_key#*_}}[${lc_hashdump_id}]=${lc_hashdump_tmp#lc_hashdump_tmp=}"
          fi
        done
      done
    else
      ##our current shell is ksh -- a simple set dump will do
      set | grep -e "^${lc_hashdump_hash}_" | (
        while read -r i ; do
          [[  "${i%%=*}" = "${lc_hashdump_hash}__first" || \
              "${i%%=*}" = "${lc_hashdump_hash}__count" || \
              "${i%%=*}" = "${lc_hashdump_hash}__last" ]] && continue
          echo "${lc_hashdump_raw:+${i}}${lc_hashdump_filter:+${i#*_}}"
        done
      )
    fi
    set | grep ^${lc_hashdump_hash}__last | (read -r i && echo "${lc_hashdump_raw:+${i}}${lc_hashdump_filter:+${i#*_}}")
  }
  return 0
}
#[cf]
#[of]:hashsave() {
hashsave() {
#[c]-r hash [key...key...] filename
  unset lc_hashsave_file
  aset lc_hashsave_hash "$@"
  apop lc_hashsave_file lc_hashsave_hash
  ##do we have permission to write the hashtable file?
  if [[ -d "${lc_hashsave_file}" ]] ; then
    echo "hashtable file \"${lc_hashsave_file}\" already exist as a directory" >&2
    return 1
  fi
  ##this checks write permissons and clears the hashtable file
  if ! : > "${lc_hashsave_file}" >/dev/null 2>&1 ; then
    echo "the hashtable file \"${lc_hashsave_file}\" is not writeable" >&2
    return 1
  fi
  ##dump entire hash to file
  hashdump "${lc_hashsave_hash[@]}"  > "${lc_hashsave_file}"
  unset lc_hashsave_hash lc_hashsave_file
  return 0
}
#[cf]
#[of]:hashload() {
hashload() {
#[c]hash [key...key...] filename
  typeset lc_hashload_hash lc_hashload_key lc_hashload_file
  lc_hashload_hash=$1
  while [[ $# -gt 2 ]] ; do
    hashconvert2key lc_hashload_key "$2"
    lc_hashload_hash="${lc_hashload_hash}_${lc_hashload_key}"
    shift
  done
  lc_hashload_file="$2"

  ##do we have permission to read the hashtable file and does it have content?
  if [[ ! -e "${lc_hashload_file}" ]] ; then
    echo "the hashtable file \"${lc_hashload_file}\" does not exist" >&2
    return 1
  fi
  if [[ ! -r "${lc_hashload_file}" ]] ; then
    echo "the hashtable file \"${lc_hashload_file}\" is not readable" >&2
    return 1
  fi
  if [[ ! -s "${lc_hashload_file}" ]] ; then
    echo "the hashtable file \"${lc_hashload_file}\" has no content" >&2
    return 1
  fi
  if ! grep -q -e ^_last= -e __last= "${lc_hashload_file}" ; then
    echo "the hashtable file \"${lc_hashload_file}\" is incomplete or damaged" >&2
    return 1
  fi
  ##is the hashtable file complete, does the hashtable file have a last= element
  while read -r lc_hashload_key ; do
    eval ${lc_hashload_hash}_${lc_hashload_key}
  done < "${lc_hashload_file}"
  ##load entire hash from file as named hash
  return 0
}
#[cf]
#[of]:hashdel() {
if [[ -n "$BASH_VERSION" ]] ; then
  hashdel() {
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
  hashdel() {
#[c]  hash
    unset lc_hashdel_key
    typeset lc_hashdel_hash
    lc_hashdel_hash="$1"
    while [[ $# -gt 1 ]] ; do
      hashconvert2key lc_hashdel_key "$2"
      lc_hashdel_hash="${lc_hashdel_hash}_${lc_hashdel_key}"
      shift
    done
    for lc_hashdel_hash in $(set | grep -e "^${lc_hashdel_hash}_") ; do
      eval "
        unset ${lc_hashdel_hash%%=*}
      "
    done
    unset lc_hashdel_key
    return 0
  }
fi
#[cf]
#[of]:hashsetkey() {
hashsetkey() {
#[c][-l] hash key [key...key...] [+=|-=|=] value
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
  typeset lc_hashsetkey_forcelower lc_hashsetkey_math
  if [[ "$1" = "-l" ]] ; then
    lc_hashsetkey_forcelower="-l"
    shift
  fi

  [[ $# -lt 3 ]] && die 1 "usage: [-l] hash key [key...key...] [+=|-=|=] value"
  aset lc_hashsetkey_args "$@"
  ashift lc_hashsetkey_hash lc_hashsetkey_args
  apop lc_hashsetkey_value lc_hashsetkey_args
  apop lc_hashsetkey_keyname lc_hashsetkey_args
  
  if [[ "${lc_hashsetkey_keyname}" = @(+=|-=|=) ]] ; then
    lc_hashsetkey_math="${lc_hashsetkey_keyname}"
    apop lc_hashsetkey_keyname lc_hashsetkey_args
  fi
  while ashift lc_hashsetkey_hashpart lc_hashsetkey_args ; do
    hashconvert2key lc_hashsetkey_hashpart "${lc_hashsetkey_hashpart}"
    lc_hashsetkey_hash="${lc_hashsetkey_hash}_${lc_hashsetkey_hashpart}"
  done

  hashconvert2key ${lc_hashsetkey_forcelower} lc_hashsetkey_key "${lc_hashsetkey_keyname}"

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
  if [[ -n "${lc_hashsetkey_math}" ]] && isset ${lc_hashsetkey_hash}__data_${lc_hashsetkey_key} ; then
    let "${lc_hashsetkey_hash}__data_${lc_hashsetkey_key} ${lc_hashsetkey_math} ${lc_hashsetkey_value}"
  else
    eval "${lc_hashsetkey_hash}__data_${lc_hashsetkey_key}=\"\${lc_hashsetkey_value}\""
  fi
  unset lc_hashsetkey_args lc_hashsetkey_hash lc_hashsetkey_hashpart lc_hashsetkey_keyname lc_hashsetkey_key lc_hashsetkey_value
  return 0
}
#[cf]
#[of]:hashgetkey() {
hashgetkey() {
#[c]!|-|var hash key [key...key...]
  unset lc_hashgetkey_hashpart lc_hashgetkey_key
  typeset lc_hashgetkey_return lc_hashgetkey_hash
  typeset lc_hashgetkey_forcelower
  if [[ "$1" = "-l" ]] ; then
    lc_hashgetkey_forcelower="-l"
    shift
  fi

  lc_hashgetkey_return="$1"
  lc_hashgetkey_hash="$2"
  while [[ $# -gt 3 ]] ; do
    hashconvert2key lc_hashgetkey_hashpart "$3"
    lc_hashgetkey_hash="${lc_hashgetkey_hash}_${lc_hashgetkey_hashpart}"
    shift
  done
  hashconvert2key ${lc_hashgetkey_forcelower} lc_hashgetkey_key "$3"

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
#[of]:hashdelkey() {
hashdelkey() {
#[c]hash key [key...key...]
  unset lc_hashdelkey_hashpart lc_hashdelkey_key
  typeset lc_hashdelkey_hash
  typeset lc_hashdelkey_forcelower
  if [[ "$1" = "-l" ]] ; then
    lc_hashdelkey_forcelower="-l"
    shift
  fi

  lc_hashdelkey_hash="$1"
  while [[ $# -gt 2 ]] ; do
    hashconvert2key lc_hashdelkey_hashpart "$2"
    lc_hashdelkey_hash="${lc_hashdelkey_hash}_${lc_hashdelkey_hashpart}"
    shift
  done
  hashconvert2key ${lc_hashdelkey_forcelower} lc_hashdelkey_key "$2"

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
#[of]:hashgetsize() {
hashgetsize() {
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
#[of]:hashgetfirst() {
hashgetfirst() {
#[c]!|-|var [-k key] hash [key...key...]
  unset lc_hashgetfirst_key lc_hashgetfirst_hashpart
  typeset lc_hashgetfirst_return lc_hashgetfirst_hash
  lc_hashgetfirst_return="$1"

  if [[ "$2" = "-k" ]] ; then
    shift
    hashconvert2key lc_hashgetfirst_key "$2"
    shift
  fi

  lc_hashgetfirst_hash="$2"
  while [[ $# -gt 2 ]] ; do
    hashconvert2key lc_hashgetfirst_hashpart "$3"
    lc_hashgetfirst_hash="${lc_hashgetfirst_hash}_${lc_hashgetfirst_hashpart}"
    shift
  done

  if ! isset lc_hashgetfirst_key ; then
    typeset lc_hashgetfirst_key
    eval "lc_hashgetfirst_key=\${${lc_hashgetfirst_hash}__first}"
  fi
  if ! isset "${lc_hashgetfirst_hash}__meta_${lc_hashgetfirst_key}" ; then
    unset lc_hashgetfirst_key lc_hashgetfirst_hashpart
    return 1
  fi
  eval "
    if isset ${lc_hashgetfirst_hash}__meta_${lc_hashgetfirst_key}[2] ; then
      ${lc_hashgetfirst_hash}__next=\${${lc_hashgetfirst_hash}__meta_${lc_hashgetfirst_key}[2]}
    else
      unset ${lc_hashgetfirst_hash}__next
    fi

    if [[ \"\${lc_hashgetfirst_return}\" = \"!\" ]] ; then
      :
    elif [[ \"\${lc_hashgetfirst_return}\" = \"-\" ]] ; then
      echo \"\${${lc_hashgetfirst_hash}__data_${lc_hashgetfirst_key}}\"
    else
      ${lc_hashgetfirst_return}=\"\${${lc_hashgetfirst_hash}__data_${lc_hashgetfirst_key}}\"
    fi
  "
  unset lc_hashgetfirst_key lc_hashgetfirst_hashpart
  return 0
}
#[cf]
#[of]:hashgetnext() {
hashgetnext() {
#[c]!|-|var hash [key...key...]
  unset lc_hashgetnext_hashpart
  typeset lc_hashgetnext_return lc_hashgetnext_hash lc_hashgetnext_key
  lc_hashgetnext_return="$1"

  lc_hashgetnext_hash="$2"
  while [[ $# -gt 2 ]] ; do
    hashconvert2key lc_hashgetnext_hashpart "$3"
    lc_hashgetnext_hash="${lc_hashgetnext_hash}_${lc_hashgetnext_hashpart}"
    shift
  done

  if ! isset ${lc_hashgetnext_hash}__next ; then
    unset lc_hashgetnext_hashpart
    return 1
  fi
  eval "lc_hashgetnext_key=\${${lc_hashgetnext_hash}__next}"

  eval "
    if isset ${lc_hashgetnext_hash}__meta_${lc_hashgetnext_key}[2] ; then
      ${lc_hashgetnext_hash}__next=\${${lc_hashgetnext_hash}__meta_${lc_hashgetnext_key}[2]}
    else
      unset ${lc_hashgetnext_hash}__next
    fi

    if [[ \"\${lc_hashgetnext_return}\" = \"!\" ]] ; then
      :
    elif [[ \"\${lc_hashgetnext_return}\" = \"-\" ]] ; then
      echo \"\${${lc_hashgetnext_hash}__data_${lc_hashgetnext_key}}\"
    else
      ${lc_hashgetnext_return}=\"\${${lc_hashgetnext_hash}__data_${lc_hashgetnext_key}}\"
    fi
  "
  unset lc_hashgetnext_hashpart
  return 0
}
#[cf]
#[of]:hashconvert2key() {
if [[ -n "$BASH_VERSION" ]] ; then
  hashconvert2key() {
#[c]  [var] value
    typeset lc_hashconvert2key_string lc_hashconvert2key_char lc_hashconvert2key_hexpart lc_hashconvert2key_key
    typeset lc_hashconvert2key_forcelower
    lc_hashconvert2key_forcelower=false
    if [[ "$1" = "-l" ]] ; then
      lc_hashconvert2key_forcelower=true
      shift
    fi
    lc_hashconvert2key_string="${2-$1}"
    if [[ -z "${lc_hashconvert2key_string}" ]] ; then
      echo "hash error, empty keys are not permitted."
      exit 1
    fi
    if { ! ${lc_hashconvert2key_forcelower} && [[ -n "${lc_hashconvert2key_string##*[^[:alnum:]_]*}" ]]; } || [[ -n "${lc_hashconvert2key_string##*[^[:lower:][:digit:]_]*}" ]] ; then
      lc_hashconvert2key_key="${lc_hashconvert2key_string//_/5F}"
    else
      while [[ ${#lc_hashconvert2key_string} -gt 0 ]] ; do
        lc_hashconvert2key_char="${lc_hashconvert2key_string%"${lc_hashconvert2key_string#?}"}"
        if [[ "${lc_hashconvert2key_char}" = [[:alnum:]] ]] ; then
          if ${lc_hashconvert2key_forcelower} && [[ "${lc_hashconvert2key_char}" = [[:alpha:]] ]] ; then
            printf -v lc_hashconvert2key_char %o $((36#${lc_hashconvert2key_char}+87))
            lc_hashconvert2key_key="${lc_hashconvert2key_key}$(echo -ne "\\0${lc_hashconvert2key_char}")"
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
  hashconvert2key() {
#[c]  [var] value
    typeset lc_hashconvert2key_string lc_hashconvert2key_char lc_hashconvert2key_hexpart lc_hashconvert2key_key
    typeset lc_hashconvert2key_forcelower
    lc_hashconvert2key_forcelower=false
    if [[ "$1" = "-l" ]] ; then
      typeset -l lc_hashconvert2key_string
      shift
    fi
  
    lc_hashconvert2key_string="${2-$1}"
    if [[ -z "${lc_hashconvert2key_string}" ]] ; then
      echo "hash error, attempted to create an empty key."
      exit 1
    fi
    if ! ${lc_hashconvert2key_forcelower} && [[ -n "${lc_hashconvert2key_string##*[^[:alnum:]]*}" ]] ; then
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
