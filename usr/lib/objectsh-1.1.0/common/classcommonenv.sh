#!/bin/sh
##  c = class name {c}
##  o = object name {o}
##  m = method(current function) name {m}
##  cv = class  var prefix {c}_cv_
##  ov = object var prefix {o}_ov_
##  cmv = class  method var prefix {c}_mv_{m}_
##  omv = object method var prefix {o}_mv_{m}_
##  cm = class meta data var prefix {c}_cm_
##  om = object meta data var prefix {o}_om_
##  smc = static method class (the class of the current static method) {smc}
typeset q d b m o om ov omv c cm cv cmv smc
q='"'
d='$'
b='`'

## bug/feature? -- bash ${FUNCNAME[0]} returns "source" if the codeblock is imported with . or source
if [[ "${FUNCNAME[0]}" != "source" ]] ; then
  m="${FUNCNAME[0]##*.}"
  smc="${FUNCNAME[1]%%.*}"
else
  m="${FUNCNAME[1]##*.}"
  smc="${FUNCNAME[2]%%.*}"
fi

o=$1
om="${o}_om_"
ov="${o}_ov_"
omv="${o}_mv_${m}_"

eval "c=${d}{${om}objectclass}"
cm="${c}_cm_"
cv="${c}_cv_"
cmv="${c}_mv_${m}_"
shift
