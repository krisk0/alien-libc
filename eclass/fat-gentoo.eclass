unset use_musl
BASE_DIR=/usr/x86_64-linux-musl
[ .${PN%musl} == .$PN ] || { use_musl=1; use_uclibc=0; }
[ .${PN%uclibc} == .$PN ] ||
 {
  use_musl=0; use_uclibc=1;
  BASE_DIR=${BASE_DIR%musl}uclibc
 }
[ -z $use_musl ] && { use_musl=1; use_uclibc=1; }
stage=0

fat-gentoo-move_usr_subr()
 {
  local d=x86_64-linux-$1/$2
  mkdir -p $d
  local i
  for i in lib64 lib32 include bin ; do
   [ -d $i ] || continue
   echo "moving $i to $d"
   cp -r $i $d/
  done
  # glibc has link lib -> lib64, we follow the suit
  ( cd $d ; [ -d lib64 ] && ln -s lib64 lib 2>/dev/null )
 }

fat-gentoo-move_usr()
# move all files in usr into usr/x86_64-linux-LIBC/$1, or remove them
 {
  cd "$ED/usr" || return
  local to_remove=`ls|egrep -v 'include|lib|lib64|lib32|bin'`
  [ -z $to_remove ] ||
   {
    einfo "removing $to_remove"
    rm -rf $to_remove
   }
  [ -d lib ] &&
   {
    einfo "lib -> lib64"
    mkdir -p lib64
    ( cd lib; cp -r . ../lib64 )
    rm -rf lib
   }
  [ $use_musl == 1 ] && fat-gentoo-move_usr_subr musl $1
  [ $use_uclibc == 1 ] && fat-gentoo-move_usr_subr uclibc $1
  rm -rf `ls|egrep -v ^x86_64-linux-`
 }

fat-gentoo-export_CC()
 {
  die 'this subroutine should export CC: either musl- or uclibc- targeting'
 }

# replace smth/some-musl/more with smth/some-uclibc/more
# die if the latter directory does not exist
#fat-gentoo-musl_not_uclibc()
# {
#  local more=$(basename $1)
#  local smth=$(dirname $1)
#  local some_musl=
# }

# Copy $base/$2 to $1 
# Copy headers from base/$3 to $1/usr/include/
fat-gentoo-copy_sysroot()
 {
  mkdir -p $1 || die
  local base=${EPREFIX}$BASE_DIR
  [ -d $base ] || die "REALM unset or wrong"
  local d=$base/$2
  #[ -d $d ] || d=$(fat-gentoo-musl_not_uclibc $d)
  einfo "copying dir $d"
  cp -rd $d/* $1 || die
  cd $base/$3 || die
  einfo "copying headers from $base/$3"
  for i in `find . -type f -name '*.h'` ; do
   j=$1/usr/include/`dirname $i`
   mkdir -p $j
   cp $i $j || die
  done
  cd $S
 }
