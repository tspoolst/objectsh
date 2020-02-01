#!/bin/sh
function die {
#[of]:  usage
  if false ; then
    echo 'Usage: die exitcode "message"'
    echo "Error: none"
    echo "Description: outputs messages to stderr and exits with exitcode"
    echo "  a quick way to kill a script"
    echo "Examples:"
    echo '  die 1 "this bit of code failed to do something"'
    echo "Returns:"
    echo "  1 or given exitcode"
    exit 1
  fi
#[cf]
}
  function die {
    typeset lc_die_return lc_die_message
    if isnum "${1}" ; then
      lc_die_return=$1
      shift
    fi
    lc_die_message="$1"
    msgdbg 0 "${lc_die_message:-no reason was given}"
    exit ${lc_die_return:-1}
  }
