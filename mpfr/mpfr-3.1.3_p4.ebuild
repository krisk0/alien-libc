# Copyright 1999-2015 Gentoo Foundation
# Copyright      2016 Крыськов Денис
# Distributed under the terms of the GNU General Public License v2

EAPI=4

inherit fat-gentoo

# On stage 0 build no 32-bit library
MULTILIB_COMPAT=( abi_x86_64 $( [ $stage == 0 ] || echo abi_x86_32) )

inherit eutils libtool multilib multilib-minimal

MY_PV=${PV/_p*}
MY_P=${PN}-${MY_PV}
PLEVEL=${PV/*p}
DESCRIPTION="Arbitary-precision rational numbers library, required to build GCC"
HOMEPAGE=http://www.mpfr.org
SRC_URI=$HOMEPAGE/mpfr-${MY_PV}/${MY_P}.tar.xz

LICENSE=LGPL-2.1
SLOT=0
KEYWORDS="-* amd64"
IUSE="static-libs"

GMP=$CATEGORY/${PN/mpfr/gmp}
GCC=$CATEGORY/gcc-${PN#mpfr-}

# On stage 1 need compiler $GCC to build
DEPEND="$GMP $([ $stage == 0 ] || echo $GCC)"
RDEPEND="$GMP"

S=${WORKDIR}/${MY_P}

src_prepare() 
 {
  # Guess 6-line construct below applies 4 patches
  if [[ ${PLEVEL} != ${PV} ]] ; then
   local i
   for (( i = 1; i <= PLEVEL; ++i )) ; do
    epatch "${FILESDIR}"/${MY_PV}/patch$(printf '%02d' ${i})
   done
  fi
  find . -type f -exec touch -r configure {} +
  elibtoolize
 }

multilib_src_configure() 
 {
  [ $stage == 0 ] &&
   local o='--disable-shared --enable-static' \
  ||
   local o='--enable-shared  --enable-static'
  # Make sure mpfr doesn't go probing toolchains it shouldn't #476336#19
  ECONF_SOURCE=${S} \
  user_redefine_cc=yes \
  econf \
   --with-gmp="$EPREFIX/$BASE_DIR/gmp" \
   --docdir="\$(datarootdir)/doc/${PF}" \
   $o
 }

multilib_src_install_all() 
 {
  [ $stage == 0 ] && find "$ED/usr" -name '*.la' -delete
  fat-gentoo-move_usr gmp
  unset BASE_DIR GMP GCC use_musl use_uclibc stage
 }
