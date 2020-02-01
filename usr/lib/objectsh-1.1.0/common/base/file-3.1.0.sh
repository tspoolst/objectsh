#!/bin/sh
##a colloction of filename handling tools

##if using bash insure extglob is on
if [[ -n "$BASH_VERSION" ]] ; then
  shopt -s extglob
else
#[of]:  function pushd {
unset DIRSTACK
function pushd {
#[of]:  usage
  if [ -z "$1" ] ; then
    echo "Usage: pushd dir"
    echo "Error: must have at least 1 argument"
    echo "Description:"
    echo "  pushes the current location onto the stack and changes to the dir specified"
    echo "  in other words - pushd saves the current location"
    echo "  this exist to emulate bash functionality in a non bash shells"
    echo "Examples: pushd /home/user"
    echo "Returns:"
    echo "  0  success"
    echo "  90 directory does not exist"
    echo "  91 dest exist but is not a directory"
    echo "  92 access denied"
    exit 1
  fi
#[cf]
  if [[ -e "$1" ]] ; then
    if [[ -d "$1" ]] ; then
      typeset lc_pushd_cdir
      lc_pushd_cdir=$(pwd)
      cd "$1"
      if [[ $? -gt 0 ]] ; then
        [[ ${gl_debuglevel:-0} -ge 0 ]] && echo "pushd: $1 access denied" >&2
        return 92
      fi
      aunshift DIRSTACK "${lc_pushd_cdir}"
      [[ ${gl_debuglevel:-0} -ge 4 ]] && echo "pushd: pushpopstack=$1 ${DIRSTACK[@]}" >&2
    else
      echo "pushd: $1 exist but is not a directory" >&2
      return 91
    fi
  else
    echo "pushd: $1 deos not exist" >&2
    return 90
  fi
  return 0
}
#[cf]
#[of]:  function popd {
function popd {
#[of]:  usage
  if false ; then
    echo "Usage: popd"
    echo "Error: none"
    echo "Description:"
    echo "  pops the topmost dir off the stack and changes to that location"
    echo "  in other words - popd returns us to the most recently saved dir"
    echo "  this exist to emulate bash functionality in a non bash shells"
    echo "Examples: popd"
    echo "Returns:"
    echo "  0  success"
    echo "  93 previously saved directory no longer exist"
    exit 1
  fi
#[cf]
}
  function popd {
    if [[ -n "${DIRSTACK}" ]] ; then
      cd "${DIRSTACK[0]}"
      if [[ $? -gt 0 ]] ; then
        [[ ${gl_debuglevel:-0} -ge 0 ]] && echo "popd: previously saved directory ${DIRSTACK[0]} no longer exist" >&2
        ashift DIRSTACK
        #### an error level must be reserved
        return 93
      fi
      [[ ${gl_debuglevel:-0} -ge 4 ]] && echo "popd: pushpopstack ${DIRSTACK[@]}" >&2
      ashift ! DIRSTACK
    else
      echo "popd: directory stack is empty" >&2
      exit 1
    fi
    return 0
  }
#[cf]
#[of]:  function dirs {
function dirs {
#[of]:  usage
  if false ; then
    echo "Usage: dirs [-c]"
    echo "Error: none"
    echo "Description:"
    echo "  displays the DIRSTACK array used by pushd/popd"
    echo "  this exist to emulate bash functionality in a non bash shells"
    echo "Examples: dirs -c"
    echo "Returns:"
    echo "  0  success"
    exit 1
  fi
#[cf]
}
  function dirs {
    [[ "$1" = "-c" ]] && unset DIRSTACK
    echo "$(pwd) ${DIRSTACK[@]}"
  }
#[cf]
#[of]:  function cd {
function cd {
#[of]:  usage
  if false ; then
    echo "Usage: cd [dir]"
    echo "Error: none"
    echo "Description:"
    echo "  wraps cd in order to update the DIRSTACK array used by pushd/popd"
    echo "  this exist to emulate bash functionality in a non bash shells"
    echo "Examples: cd /tmp"
    echo "Returns:"
    echo "  result from cd command"
    exit 1
  fi
#[cf]
}
  function cd {
    command cd "$@" &&
      DIRSTACK[0]="$1"
  }
#[cf]
fi
#[of]:function filepath {
function filepath {
  typeset lc_filepath_relative lc_filepath_path
  if [[ "$1" = "-r" ]] ; then
    lc_filepath_relative=true
    shift
  fi
#[of]:  usage
  if [ -z "$2" ] ; then
    echo "Usage: filepath [-r] {var|-} {file}"
    echo "Error: must have at least 2 arguments"
    echo "Description:"
    echo "  return the filepath only"
    echo "Options"
    echo "  -r returns relative path"
    echo "Examples:"
    echo '  filepath lc_RotateFiles_path ${lc_RotateFiles_file}'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  ## if file has a path grab the path else use pwd
  if [[ -z "${2##*/*}" ]] ; then
    lc_filepath_path="${2%/*}"
    ##if relative != true, try to grab the absolute path - else just use what was given
    if ! ${lc_filepath_relative:-false} ; then
      lc_filepath_path="$(cd "${lc_filepath_path}" 2>/dev/null;pwd)"
    fi
  else
    lc_filepath_path="$(pwd)"
  fi

  if [[ "$1" = "-" ]] ; then
    echo "${lc_filepath_path}"
  else
    eval $1=\"\${lc_filepath_path}\"
  fi
  return 0
}
#[cf]
#[of]:function filename {
function filename {
#[of]:  usage
  if [ -z "$2" ] ; then
    echo "Usage: filename {var|-} {file}"
    echo "Error: must have at least 2 arguments"
    echo "Description:"
    echo "  return a filename without the path"
    echo "Examples:"
    echo '  filename lc_RotateFiles_name ${lc_RotateFiles_file}'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  if [[ "$1" = "-" ]] ; then
    echo "${2##*/}"
  else
    eval $1=\"\${2##*/}\"
  fi
  return 0
}
#[cf]
#[of]:function filebase {
function filebase {
#[of]:  usage
  if [ -z "$2" ] ; then
    echo "Usage: filebase {var|-} {file}"
    echo "Error: must have at least 2 arguments"
    echo "Description:"
    echo "  returns only the base of a filename"
    echo "Examples:"
    echo '  filebase lc_RotateFiles_name ${lc_RotateFiles_file}'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  typeset lc_filebase_name lc_filebase_base
  
  #chop off path
  lc_filebase_name="${2##*/}"
  
  ##chop off ext
  lc_filebase_base="${lc_filebase_name%.*}"

  ##if base is null, because it is a .dot file with no extention
  ##  base = name
  ##or if base != name chop .tar.*
  if [[ -z "${lc_filebase_base}" ]] ; then
    lc_filebase_base="${lc_filebase_name}"
  elif [[ "${lc_filebase_base}" != "${lc_filebase_name}" ]] ; then
    ##chop off .tar.* from base
    if [[ "${lc_filebase_base}" = @(*.tar) ]] ; then
      lc_filebase_base="${lc_filebase_base%.*}"
    fi
  fi

  if [[ "$1" = "-" ]] ; then
    echo "${lc_filebase_base}"
  else
    eval $1=\"\${lc_filebase_base}\"
  fi
  return 0
}
#[cf]
#[of]:function fileext {
function fileext {
#[of]:  usage
  if [ -z "$2" ] ; then
    echo "Usage: fileext {var|-} {file}"
    echo "Error: must have at least 2 arguments"
    echo "Description:"
    echo "  returns only the extention of a filename"
    echo "Examples:"
    echo '  fileext lc_RotateFiles_ext ${lc_RotateFiles_file}'
    echo "Returns:"
    echo "  0 success"
    exit 1
  fi
#[cf]
  typeset lc_fileext_name lc_fileext_ext
  
  #chop off path
  lc_fileext_name="${2##*/}"
  
  ##get filebase
  filebase lc_fileext_base "${lc_fileext_name}"
  
  ##chop base from name to get ext
  lc_fileext_ext="${lc_fileext_name#${lc_fileext_base}}"

  if [[ "$1" = "-" ]] ; then
    echo "${lc_fileext_ext#.}"
  else
    eval $1=\"\${lc_fileext_ext#.}\"
  fi
  unset lc_fileext_base
  return 0
}
#[cf]
