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
 }

src_configure()
 {
  mkdir $BITS ; cd $BITS
  local h=${CPU}-pc-linux-gnu
  t=${CPU}-pc-linux-$REALM
  # This ebuild does not support EPREFIX with spaces
  local o="--build=$h --host=$h --target=$t --prefix=$EPREFIX/$BASE_DIR"
  o="$o --disable-werror --enable-ld=default --enable-gold=yes --enable-threads"
  o="$o --enable-plugins --enable-lto --with-pkgversion=$CATEGORY"
  o="$o --disable-multilib --disable-sim -disable-gdb --disable-nls"
  o="$o --with-sysroot=$EPREFIX/$BASE_DIR/sysroot"
  o="$o --with-bugurl=https://github.com/krisk0/$CATEGORY"
  einfo "Configuring..."
  ../configure $o || die "configure failed"
 }

src_compile()
 {
  emake -C $BITS
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
  echo "BITS=$BITS BASE_DIR=$BASE_DIR"

  # share/info is a collision point
  { cd "$ED/$BASE_DIR" && rm -r share/info ; } || die
  use doc || rm -r share

  unset BASE_DIR use_musl use_uclibc stage x y t cpu BITS
 }
