# REALM: uclibc or musl or android
unset use_musl
BASE_DIR=/usr/x86_64-linux-musl
[ $CATEGORY == bionic-core ] && REALM=android || REALM=${PN##*-}
[ $REALM == uclibc ] || [ $REALM == musl ] || unset REALM
[ .$REALM == .musl ] && { use_musl=1; use_uclibc=0; }
[ .$REALM == .uclibc ] && { use_uclibc=1; use_musl=0; }
[ -z $REALM ] || BASE_DIR=/usr/x86_64-linux-$REALM
[ -z $use_musl ] && { use_musl=1; use_uclibc=1; }
unset stage
[ -z "$FAT_GENTOO_STAGE" ] &&
 {
  # FAT_GENTOO_STAGE unset, will auto-select stage: 0 or 1
  stage=0
  unset fat_gentoo_GCC_PACKAGE
   
  # if REALM is set and valid C++ compiler is installed, set stage=1
  [ -z $REALM ] ||
   {
    local b=x86_64-linux-$REALM
    local c=$EPREFIX/usr/$b/bin/${b}-g++
    [ -f $c ] &&
     {
      fat_gentoo_GCC_PACKAGE=$(equery b $c 2>/dev/null)
      [ -z $fat_gentoo_GCC_PACKAGE ] || 
       {
        stage=1
        export CHOST=${CHOST%%-*}-pc-linux-$REALM
       }
     }
   }
 }
[ -z $stage ] && stage=$FAT_GENTOO_STAGE
 
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
  [ ${use_musl}$use_uclibc == 11 ] && 
   {
    fat-gentoo-move_usr_subr musl $1
    fat-gentoo-move_usr_subr uclibc $1
   } \
  ||
   fat-gentoo-move_usr_subr $REALM $1
  rm -rf `ls|egrep -v ^x86_64-linux-`
 }

fat-gentoo-export_CC()
 {
  local b=x86_64-linux-$REALM
  # try short name
  CC=$EPREFIX/usr/$b/bin/${b}-gcc
  [ -f $CC ] ||
   CC=$(equery f $fat_gentoo_GCC_PACKAGE|fgrep $b/bin|fgrep -- -gcc|head -1)
  CXX=$EPREFIX/usr/$b/bin/${b}-g++
  [ -f $CXX ] ||
   CXX=$(equery f $fat_gentoo_GCC_PACKAGE|fgrep $b/bin|fgrep -- -g++|head -1)
 }

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
