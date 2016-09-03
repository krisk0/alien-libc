# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v3

EAPI=5

IUSE='doc'
inherit fat-gentoo

HOMEPAGE=http://sourceware.org/binutils
DESCRIPTION="Binary code creation/manipulation utilities"
LICENSE="|| ( GPL-3 LGPL-3 )"
# Will take patches from crosstool-ng repository
sha=d7339f50a2e83a5a267551c2b798f0f53a545f08
ct=crosstool-ng
SRC_URI="mirror://gnu/binutils/binutils-$PV.tar.bz2
 https://github.com/$ct/$ct/archive/$sha.zip -> ct-ng-20160310.zip"
KEYWORDS="*- amd64"
SLOT=0
# construct DEPEND="$( [ $BITS == 32 ] && echo $CATEGORY/sysroot[i386?]" does
#  not work when BITS is set via CPU variable depending on CHOST. Therefore
#  use i386 flag to set 32-bit mode
DEPEND=" $CATEGORY/sysroot[i386?] "

S="$WORKDIR/binutils-$PV"

src_unpack()
 {
  default
  (
   mkdir patch &&
   mv `find $ct-* -type d -wholename */binutils/$PV`/* patch/ &&
   rm -r $ct-*
  ) \
  || die
 }

src_prepare()
 {
  for x in `ls $WORKDIR/patch/` ; do
   patch -p1 < "$WORKDIR/patch/$x" || die
  done

  # build system is broken: it adds /usr/local/lib /lib /usr/lib to library
  #  search path even when cross-compiling
  sed -e 's:NATIVE_LIB_DIRS=$9:NATIVE_LIB_DIRS=:' -i ld/genscripts.sh || die
  
  # don't read glibc'ish /etc/ld.so.cache
  for x in ltmain.sh libtool.m4 elf32.em* ; do
   sed -e s:ld.so.conf:${REALM}_ld_so_conf:g -i `find . -type f -name $x` || die
  done
 }

src_configure()
 {
  mkdir $BITS ; cd $BITS
  local h=${CPU}-pc-linux-gnu
  t=${CPU}-pc-linux-$REALM
  # This ebuild does not support EPREFIX with spaces
  local o="--build=$h --host=$h --target=$t --prefix=${EPREFIX}$BASE_DIR"
  o="$o --disable-werror --enable-ld=default --enable-gold=yes --enable-threads"
  o="$o --enable-plugins --enable-lto --with-pkgversion=$CATEGORY"
  o="$o --disable-multilib --disable-sim -disable-gdb --disable-nls"
  o="$o --with-sysroot=/"
  o="$o --with-bugurl=https://github.com/krisk0/$CATEGORY"
  einfo "Configuring..."
  ../configure $o || die "configure failed"
  sed s:/x86_64-pc-linux-$REALM::g -i Makefile || die
 }

src_compile()
 {
  cd $BITS
  emake
  # fix and remake ld
  rm ld/*.o ld/ld-new || die
  cd ld || die
  local true=`which true`
  # I don't understand how to fix genscripts.h, fix .c files instead
  sed -e 's:GENSCRIPTS = .*:GENSCRIPTS = $true:g' -i Makefile || die
  local usr=`dirname $BASE_DIR`
  local nice=$usr/x86_64-linux-$REALM
  local c_files=`find . -name '*.c'`
  sed -e s:=$nice/x86_64-pc-linux-$REALM/lib:$nice/lib:g -i $c_files || die
  # =/usr gets transformed to /usr/usr, so remove = completely
  sed -e s:=$usr/:$usr:g -i $c_files || die
  cd ..
  einfo 're-making ld' 
  emake 
 }

src_install()
 {
  emake -C $BITS DESTDIR="$ED" install
  
  # Create convenience symbolic links
  cd $ED/$BASE_DIR/bin || die
  y=0
  for x in ${t}* ; do
   ln -s $x ${x/pc-/} && y=$((y+1))
  done
  [ $y == 0 ] || einfo "Created $y symbolic links"

  # share/info is a collision point
  { cd "$ED/$BASE_DIR" && rm -r share/info ; } || die
  use doc || rm -r share

  unset BASE_DIR use_musl use_uclibc stage x y t cpu BITS
 }
