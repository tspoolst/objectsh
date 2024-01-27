#!/bin/bash

##if using bash insure extglob is on
[[ -n "$BASH_VERSION" ]] && shopt -s extglob

#[of]:instring() {
instring() {
#[of]:  usage
  if [ $# -ne 3 ] ; then
    echo 'Usage: instring {!|-|var} "{string}" {pattern}'
    echo "Error: must have at least 3 args"
    echo "Description:"
    echo "  returns the index of a pattern within a given string"
    echo "    var|stdout = the index of the match 0-n"
    echo "             if no match -1"
    echo "Examples:"
    echo "  if found _position will be set with the index of YYYY"
    echo '    _position=$(instring - "${_format}" YYYY)'
    echo '    instring _position "${_format}" YYYY'
    echo "Returns:"
    echo "  0 success"
    echo "  1 no match"
    exit 1
  fi
#[cf]
  typeset lc_instring_index lc_instring_string lc_instring_pattern lc_instring_searchlength lc_instring_result lc_instring_return
  lc_instring_string="$2"
  lc_instring_pattern="$3"
  lc_instring_searchlength=$((1 + ${#lc_instring_string} - ${#lc_instring_pattern}))
  lc_instring_index=0
  if [[ -n "${lc_instring_pattern}" ]] ; then
    while [[ ${lc_instring_index} -lt ${lc_instring_searchlength} ]] ; do
      if eval "[[ \"\${lc_instring_string}\" != \"\${lc_instring_string#@(${lc_instring_pattern})}\" ]]" ; then
        lc_instring_result=${lc_instring_index}
        lc_instring_return=0
        break
      fi
      lc_instring_string="${lc_instring_string#?}"
      lc_instring_index=$(( lc_instring_index + 1 ))
    done
  else
    lc_instring_result=0
    lc_instring_return=0
  fi
  if [[ "$1" = "!" ]] ; then
      :
  elif [[ "$1" = "-" ]] ; then
    echo ${lc_instring_result:--1}
  else
    eval $1=\"\${lc_instring_result:--1}\"
  fi
  return ${lc_instring_return:-1}
}
#[cf]
#[of]:substr() {
substr() {
#[of]:  usage
  if false ; then
    echo 'Usage: substr {-|var} "{string}" {index} [length]'
    echo "Error: must have at least 4 args"
    echo "Description:"
    echo "  returns, via stdout, a substring of the given string"
    echo "  the index is 0 based"
    echo "  this exist because, there is no common way of doing a substring in ksh and bash"
    echo "Examples:"
    echo "  sets _year to a 2 character substring of _var"
    echo '    _year="$(subst "${_var}" ${_position} 2)"'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
}
if [[ -n "${BASH_VERSION}" ]] ; then
  ##when with bash do the bash
  substr() {
    eval typeset lc_substr_string=\"\${2:$3${4:+:}$4}\"
    if [[ "$1" = "-" ]] ; then
      echo "${lc_substr_string}"
    else
      eval $1=\"\${lc_substr_string}\"
    fi
    return 0
  }
else
  substr() {
    typeset lc_substr_string
    lc_substr_string=$(
      if [[ ${4:-1} -eq 0 ]] ; then
        echo ""
      else
        echo "$2" | cut -c $(($3+1))-${4:+$(($3+$4))}
      fi
    )
    if [[ "$1" = "-" ]] ; then
      echo "${lc_substr_string}"
    else
      eval $1=\"\${lc_substr_string}\"
    fi
    return 0
  }
fi
#[cf]
#[of]:tolower() {
tolower() {
#[of]:  usage
  if [ -z "$1" ] ; then
    echo "Usage: tolower {-|var} [string]"
    echo "Error: must have at least 1 argument"
    echo "Description: transforms a variable to lower case"
    echo "Examples:"
    echo '  tolower lc_main_filename'
    echo '  tolower - "A Test String"'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  typeset lc_tolower_data lc_tolower_result
  if [[ $# = 1 ]] ; then
    eval lc_tolower_data=\"\${$1}\"
  else
    lc_tolower_data="$2"
  fi
  if [ -n "$BASH_VERSION" ] ; then
    typeset lc_tolower_result=$(echo "${lc_tolower_data}" | tr A-Z a-z)
  else
    typeset -l lc_tolower_result="${lc_tolower_data}"
  fi
  if [[ "$1" = "-" ]] ; then
    echo "${lc_tolower_result}"
  else
    eval $1=\"\${lc_tolower_result}\"
  fi
  return 0
}
#[cf]
#[of]:toupper() {
toupper() {
#[of]:  usage
  if [ -z "$1" ] ; then
    echo "Usage: toupper {-|var} [string]"
    echo "Error: must have at least 1 argument"
    echo "Description: transforms a variable to lower case"
    echo "Examples:"
    echo '  toupper lc_main_filename'
    echo '  toupper - "A Test String"'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  typeset lc_toupper_data lc_toupper_result
  if [[ $# = 1 ]] ; then
    eval lc_toupper_data=\"\${$1}\"
  else
    lc_toupper_data="$2"
  fi
  if [ -n "$BASH_VERSION" ] ; then
    typeset lc_toupper_result=$(echo "${lc_toupper_data}" | tr a-z A-Z)
  else
    typeset -u lc_toupper_result="${lc_toupper_data}"
  fi
  if [[ "$1" = "-" ]] ; then
    echo "${lc_toupper_result}"
  else
    eval $1=\"\${lc_toupper_result}\"
  fi
  return 0
}
#[cf]
#[of]:ascii2hex() {
ascii2hex() {
#[c][var] value
  typeset lc_ascii2hex_string lc_ascii2hex_hexpart lc_ascii2hex_hex
  lc_ascii2hex_string="${2:-$1}"
  while [[ ${#lc_ascii2hex_string} -gt 0 ]] ; do
    lc_ascii2hex_hexpart=$(printf  %02X "'${lc_ascii2hex_string%"${lc_ascii2hex_string#?}"}")
    lc_ascii2hex_hex="${lc_ascii2hex_hex}${lc_ascii2hex_hexpart}"
    lc_ascii2hex_string="${lc_ascii2hex_string#?}"
  done
  if [[ $# -eq 1 ]] ; then
    echo "${lc_ascii2hex_hex}"
  else
    eval "$1=\"\${lc_ascii2hex_hex}\""
  fi
  return 0
}
#[cf]
#[of]:cleancat() {
cleancat() {
#[of]:  usage
  if [ $# -gt 1 ] ; then
    echo "Usage: cleancat [filename]|[redirect]"
    echo "Error: must have 0 or 1 argument"
    echo "Description: dumps a file or pipe removing blank lines and comments"
    echo "Examples:"
    echo '  cleancat ${lc_main_filename}'
    echo '  bigdataapp | cleancat'
    echo '  cleancat < echo "A Test String"'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  if [[ -n "$1" ]] ; then
    [[ ! -r "$1" ]] && die 1 "could not read file $1"
    grep -v -e "^[[:blank:]]*$" -e "^[[:blank:]]*#" "$1" 2>/dev/null
  else
    grep -v -e "^[[:blank:]]*$" -e "^[[:blank:]]*#" 2>/dev/null
  fi
}
#[cf]
#[of]:urldecode() {
urldecode() {
#[of]:  usage
  if false ; then
    echo 'Usage: urldecode [-|var] "{string}"'
    echo "Error: none"
    echo "Description:"
    echo "  returns string decoded from url hex"
    echo "Examples:"
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  typeset lc_urldecode_string
  lc_urldecode_string="${2:-$1}"
  lc_urldecode_string="${lc_urldecode_string//+/ }"
  if [[ $# -eq 1 ]] ; then
    echo -e "${lc_urldecode_string//%/\\x}"
  else
    eval "$1=\"\$(echo -e \"\${lc_urldecode_string//%/\\\\x}\")\""
  fi
}
#[cf]
#[of]:urlencode() {
urlencode() {
  #would like to figure out how to do this without "xxd"
#[of]:  usage
  if ! which xxd >/dev/null ; then
    echo 'Usage: urlencode [-|var] "{string}"'
    echo 'Error: "xxd" must be installed to use this function'
    echo "Description:"
    echo "  returns url utf8 encoded hex string"
    echo "Examples:"
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  typeset lc_urlencode_string lc_urlencode_chr lc_urlencode_utf
  lc_urlencode_string="${2:-$1}"
  lc_urlencode_string=$(
    echo -n "${lc_urlencode_string}" | while read -rN 1 lc_urlencode_chr ; do
      echo -n "${lc_urlencode_chr}" | xxd -u -p | (while read -rN 2 lc_urlencode_utf;do
        [[ -n "${lc_urlencode_utf}" ]] && echo -n "%${lc_urlencode_utf}"
      done)
    done
    echo
  )
  if [[ $# -eq 1 ]] ; then
    echo -e "${lc_urlencode_string}"
  else
    eval "$1=\"\${lc_urlencode_string}\""
  fi
}
#[cf]


