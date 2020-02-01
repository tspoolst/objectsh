#!/bin/sh
function msgdbg {
##input level,message
  typeset lc_msgdbg_return lc_msgdbg_level lc_msgdbg_message
  lc_msgdbg_return=$?
  lc_msgdbg_level="$1"
  lc_msgdbg_message="$2"
#[of]:  usage
  if ! isnum "${lc_msgdbg_level}" || [[ -z "${lc_msgdbg_message}" ]] ; then
    echo "Usage: msgdbg debuglevel message"
    echo "Error: debuglevel is not a number or message is missing"
    echo "Description: outputs messages to stdout based on debuglevel"
    echo "  used for debugging code as it is being built/tested"
    echo 'Examples: msgdbg 3 "this bit of code is doing something"'
    echo "  the message will only be seen if gl_debuglevel=3 or higher"
    echo "Returns: whatever errorlevel was before this function was called"
    exit 1
  fi
#[cf]
  if [ ${gl_debuglevel:-0} -ge ${lc_msgdbg_level} ] ; then
    printf "return=${lc_msgdbg_return:-0}  ${gl_funcname}:%s\n" "${lc_msgdbg_message}" >&2
  fi
  return ${lc_msgdbg_return}
}
