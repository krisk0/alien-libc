# Copyright 1999-2015 Gentoo Foundation
# Copyright      2016 Крыськов Денис
# Distributed under the terms of the GNU General Public License v2

EAPI=4

IUSE="static-libs"
inherit fat-gentoo

inherit eutils libtool multilib multilib-minimal

MY_PV=${PV/_p*}
MY_P=mpfr-${MY_PV}
PLEVEL=${PV/*p}
DESCRIPTION="Arbitary-precision rational numbers library, required to build GCC"
HOMEPAGE=http://www.mpfr.org
SRC_URI=$HOMEPAGE/mpfr-${MY_PV}/${MY_P}.tar.xz

LICENSE=LGPL-2.1
SLOT=0
KEYWORDS="-* amd64"

DEPEND="$CATEGORY/${PN/mpfr/gmp}[${MULTILIB_USEDEP}]"
RDEPEND="$DEPEND"

S=${WORKDIR}/${MY_P}

src_prepare() 
 {
  [ $stage == 1 ] && einfo "REALM=$REALM stage=1" || einfo "stage=0"
  einfo "CHOST=$CHOST"
  # On stage 0 use glibc-targeting GCC
  [ $stage == 0 ] && tc-export CC || fat-gentoo-export_CC
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
   {
    local o='--disable-shared --enable-static' 
    g=gmp
   } \
  ||
   {
    local o='--enable-shared  --enable-static'
    unset g
   }
  # Make sure mpfr doesn't go probing toolchains it shouldn't #476336#19
  ECONF_SOURCE=${S} \
  user_redefine_cc=yes \
  econf \
   --with-gmp="$EPREFIX/$BASE_DIR/$g" \
   --docdir="\$(datarootdir)/doc/${PF}" \
   $o
 }

multilib_src_install_all() 
 {
  [ $stage == 0 ] && find "$ED/usr" -name '*.la' -delete
  fat-gentoo-move_usr $g
  
  unset g
  unset use_musl use_uclibc stage BITS BASE_DIR LIBRARY_PATH
 }
