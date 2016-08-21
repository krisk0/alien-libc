# Copyright 1999-2015 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit fat-gentoo

inherit eutils libtool multilib-minimal

DESCRIPTION="An arithmetic library, required to build GMP"
HOMEPAGE=http://mpc.multiprecision.org
SRC_URI=http://www.multiprecision.org/mpc/download/mpc-$PV.tar.gz
S=$WORKDIR/mpc-$PV

LICENSE=LGPL-2.1
SLOT=0
KEYWORDS="*- amd64"

MPFR="$CATEGORY/${PN/mpc/mpfr}[${MULTILIB_USEDEP}]"

RDEPEND="$MPFR"
DEPEND="$RDEPEND"

src_prepare() 
 {
  [ $stage == 1 ] && einfo "REALM=$REALM stage=1" || einfo "stage=0"
  einfo "CHOST=$CHOST"
  # On stage 0 use glibc-targeting GCC
  [ $stage == 0 ] && tc-export CC || fat-gentoo-export_CC

  elibtoolize #347317
 }

multilib_src_configure() 
 {
  [ $stage == 0 ] &&
   {
    local o='--disable-shared --enable-static' 
    g=gmp
   } \
  ||
   {
    local o='--enable-shared  --enable-static'
    unset g
   }
  ECONF_SOURCE="$S" econf $o \
   --with-gmp="$EPREFIX/$BASE_DIR/$g" \
   --with-mpfr="$EPREFIX/$BASE_DIR/$g" 
 }

multilib_src_install_all() 
 {
  [ $stage == 0 ] && find "$ED/usr" -name '*.la' -delete
  fat-gentoo-move_usr $g
  unset g
  unset use_musl use_uclibc stage BITS BASE_DIR LIBRARY_PATH
 }
