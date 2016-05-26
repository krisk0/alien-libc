# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v2

EAPI=5

HOMEPAGE=https://github.com/krisk0/$CATEGORY
KEYWORDS='-* amd64'
SLOT=0

DESCRIPTION="2 shell scripts that act like gcc compiler targeting musl/uclibc"

m=musl-1.1.14
SRC_URI=http://www.musl-libc.org/releases/$m.tar.gz

d='=sys-devel/gcc-4.9.3'
DEPEND="$d"
S="$WORKDIR/$m"

src_unpack()
 {
  default
  cd $m
  rm -r `ls|fgrep -v tools`
 }

src_install()
 {
  local spec_sh=tools/musl-gcc.specs.sh
  [ -s $spec_sh ] || die "i am at `pwd`"
  local base=/usr/x86_64-linux-
  local gcc=`equery f $d|egrep -- -gcc$|head -1`
  for x in musl uclibc ; do
   mkdir -p $ED/${base}$x/{bin,share}
   [ $x == musl ] && y=ld-musl-x86_64.so.1 || y=ld64-uClibc.so.0
   sh $spec_sh ${base}$x/include ${base}$x/lib64 \
    $EPREFIX/lib/$y > $ED/${base}$x/share/gcc.spec
   local w=$ED/${base}$x/bin/$x-gcc
   printf "#!/bin/sh\nexec $gcc %s -specs $EPREFIX/${base}$x/share/gcc.spec" \
    '"$@"' | sed s://:/: > $w
   chmod +x $w
  done
  unset x y d m
 }
