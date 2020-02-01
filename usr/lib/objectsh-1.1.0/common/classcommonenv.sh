#!/bin/sh
##  c = class name {c}
##  o = object name {o}
##  m = method name {m}
##  cv = class var prefix {c}_cv_
##  ov = object var prefix {o}_ov_
##  mv = method var prefix {o}_mv_{m}_
##  cm = class meta data var prefix {c}_cm_
##  om = object meta data var prefix {o}_mv_
typeset q d b o om m ov mv
q='"'
d='$'
b='`'
o=$1
om="${o}_om_"
m="${FUNCNAME[1]##*.}"
ov="${o}_ov_"
mv="${o}_mv_${m}_"
eval "
  typeset c cm cv
  c=${d}{${om}objectclass}
  cm=${d}{c}_cm_
  cv=${d}{c}_cv_
"
shift
