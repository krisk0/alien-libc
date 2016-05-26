# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v2

EAPI=5

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
  local p
  for p in `ls $WORKDIR/patch/` ; do
   patch -p1 < "$WORKDIR/patch/$p" || die
  done
 }

src_configure()
 {
  mkdir $CATEGORY ; cd $CATEGORY
  local h=x86_64-pc-linux-gnu
  local t=x86_64-pc-linux-${PN#*-}
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
  emake -C $CATEGORY
 }

src_install()
 {
  emake -C $CATEGORY DESTDIR="$ED" install
  cd $ED/$BASE_DIR/bin || die
  local y=0
  for x in x86_64-pc-linux-${PN#*-}* ; do
   ln -s $x ${x/pc-/} && y=$((y+1))
  done
  [ $y == 0 ] || einfo "Created $y symbolic links"
  # share/info is a collision point
  ( cd "$ED/$BASE_DIR" && mv lib lib64 && rm -r share/info ) || die

  unset BASE_DIR use_musl use_uclibc stage x
 }
