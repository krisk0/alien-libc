# Copyright 1999-2016 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

inherit fat-gentoo

# On stage 0 build no 32-bit library

inherit eutils multilib-minimal fat-gentoo

DESCRIPTION="A library to solve int. lin. programming problem, needed to build GCC"
HOMEPAGE=http://isl.gforge.inria.fr
SRC_URI=$HOMEPAGE/$P.tar.xz

LICENSE=LGPL-2.1
SLOT="0/15"
KEYWORDS="*- amd64"

GMP=$CATEGORY/${PN/isl/gmp}
GCC=$CATEGORY/gcc-${PN#isl-}

# On stage 1 need compiler $GCC to build
DEPEND="$GMP
 $([ $stage == 0 ] || echo $GCC)
 app-arch/xz-utils
 virtual/pkgconfig
 "
RDEPEND="$GMP"
# TODO: don't create pkgconfig data on stage 0

DOCS=( )

src_prepare()
 {
  # m4/ax_create_pkgconfig_info.m4 is broken but avoid eautoreconf
  # https://groups.google.com/group/isl-development/t/37ad876557e50f2c
  sed -i -e '/Libs:/s:@LDFLAGS@ ::' configure || die #382737
 }

multilib_src_configure()
 {
  [ $stage == 0 ] &&
   local o='--disable-shared --enable-static' \
  ||
   local o='--enable-shared  --enable-static'
  ECONF_SOURCE="$S" econf $o \
   --with-gmp=system --with-gmp-prefix="$EPREFIX/$BASE_DIR/gmp" \
   --with-clang=no
 }

multilib_src_install_all()
 {
  [ $stage == 0 ] && 
   {
    find "$ED/usr" -name '*.la' -delete
    rm -r "$ED/usr/lib64/pkgconfig"
   }
  fat-gentoo-move_usr gmp
  unset BASE_DIR GMP GCC use_musl use_uclibc stage
 }
