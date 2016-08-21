# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit fat-gentoo

inherit eutils multilib-minimal fat-gentoo

DESCRIPTION="A library to solve int. lin. programming problem, needed to build GCC"
HOMEPAGE=http://isl.gforge.inria.fr
SRC_URI=$HOMEPAGE/isl-$PV.tar.xz
S=$WORKDIR/isl-$PV

LICENSE=LGPL-2.1
SLOT="0/15"
KEYWORDS="*- amd64"

GMP="$CATEGORY/${PN/isl/gmp}[${MULTILIB_USEDEP}]"

# On stage 1 need special compiler
DEPEND="$GMP
 app-arch/xz-utils
 virtual/pkgconfig
 "
RDEPEND="$GMP"
# TODO: don't create pkgconfig data on stage 0

DOCS=( )

src_prepare()
 {
  [ $stage == 1 ] && einfo "REALM=$REALM stage=1" || einfo "stage=0"
  einfo "CHOST=$CHOST"
  # On stage 0 use glibc-targeting GCC
  [ $stage == 0 ] && tc-export CC || fat-gentoo-export_CC

  # m4/ax_create_pkgconfig_info.m4 is broken but avoid eautoreconf
  # https://groups.google.com/group/isl-development/t/37ad876557e50f2c
  sed -i -e '/Libs:/s:@LDFLAGS@ ::' configure || die #382737
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
   --with-gmp=system --with-gmp-prefix="$EPREFIX/$BASE_DIR/$g" \
   --with-clang=no
 }

multilib_src_install_all()
 {
  [ $stage == 0 ] && 
   {
    find "$ED/usr" -name '*.la' -delete
    rm -fr "$ED/usr/lib64/pkgconfig"
   }
  fat-gentoo-move_usr $g

  unset g
  unset use_musl use_uclibc stage BITS BASE_DIR LIBRARY_PATH
 }
