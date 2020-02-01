#!/bin/sh
function errorlevel {
  if false ; then
    echo "Usage: errorlevel [arg]"
    echo "Error: none"
    echo "Description:"
    echo "  this simply sets the desired errorlevel on return.  if arg is not a number it returns 0"
    echo "Examples:"
    echo '  i.e. errorlevel 7'
    echo "    sets errorlevel to 7"
    echo "Returns: 0 or arg"
    exit 1
  fi
  if [ -z "${1##*[a-zA-Z]*}" ] ; then
    return 0
  else
    return $1
  fi
}
