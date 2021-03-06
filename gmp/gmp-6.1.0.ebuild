# Copyright 1999-2015 Gentoo Foundation
# Copyright      2016 Крыськов Денис
# Distributed under the terms of the GNU General Public License v2

EAPI=5

IUSE="+asm"
inherit fat-gentoo flag-o-matic eutils libtool multilib-minimal

# This ebuild works in one of 2 modes, governed by stage variable.
#  The variable is set by fat-gentoo.eclass

MY_PV=${PV/_p*}
MY_PV=${MY_PV/_/-}
MY_P=gmp-${MY_PV}
PLEVEL=${PV/*p}
DESCRIPTION="Big number library, required to properly build GCC and openssl"
HOMEPAGE=http://gmplib.org
SRC_URI="ftp://ftp.gmplib.org/pub/${MY_P}/${MY_P}.tar.xz
 mirror://gnu/${PN}/${MY_P}.tar.xz"

LICENSE="|| ( LGPL-3+ GPL-2+ )"
# The subslot reflects the C & C++ SONAMEs
SLOT="0/10.4"
KEYWORDS="-* amd64"      # -* suggested by multilib-build documentation

DEPEND="sys-devel/m4 app-arch/xz-utils"

S=$WORKDIR/${MY_P%a}

DOCS=( )
MULTILIB_WRAPPED_HEADERS=( /usr/include/gmp.h )

src_prepare()
 {
  [ $stage == 1 ] && einfo "REALM=$REALM stage=1" || einfo "stage=0"
  einfo "CHOST=$CHOST"

  # On stage 0 use glibc-targeting GCC
  [ $stage == 0 ] && tc-export CC || fat-gentoo-export_CC

  # elibtoolize only patches ltmain.sh
  elibtoolize

  epatch "${FILESDIR}"/gmp-6.1.0-noexecstack-detect.patch

  # GMP and Gentoo share "ABI" variable but it might have different value. Small
  #  wrapper script below handles this
  mv configure configure.wrapped || die
  printf '#!/bin/sh\nexec env ABI=$GMPABI "$0.wrapped" "$@"' > configure
  chmod a+rx configure

  # multilib_src_configure() clobbers config.guess, so run it here
  export build_alias=`/bin/sh $S/config.guess` ||
   die "failed to run config.guess"
  [ -z $build_alias ] && die "empty result from config.guess"
  einfo "guessed processor type: $build_alias"
 }

multilib_src_configure()
 {
  einfo "CHOST=$CHOST"
  # ABI mappings (needs all architectures supported)
  case ${ABI} in
   32|x86)       GMPABI=32;;
   64|amd64|n64) GMPABI=64;;
   [onx]32)      GMPABI=${ABI};;
  esac
  export GMPABI

  export ac_cv_host=$build_alias
  export ac_build_alias=$ac_cv_host
  # On stage 0 only build static C library
  [ $stage == 0 ] &&
   local o='--disable-shared --disable-cxx --enable-static' \
  ||
   local o='--enable-shared  --enable-cxx  --enable-static'
  # localstatedir is only found in Makefile's. Hopefully it is not inserted into
  #  object files
  ECONF_SOURCE="$S" econf \
   --localstatedir="$EPREFIX"/no.such.dir \
   $(use_enable asm assembly) \
   $o
  # econf above inserts --localstatedir= directive twice. This also happens with
  #  official dev-libs/gmp-6.1.0.ebuild. Is this a bug or feature?
 }

multilib_src_test()
 {
  emake check
 }

multilib_src_install()
 {
  emake DESTDIR="$D" install

  # libgmp should be a standalone lib
  rm -f "$D"/usr/$(get_libdir)/libgmp.la
  # libgmpxx requires libgmp
  local la="$D/usr/$(get_libdir)/libgmpxx.la"
  [ -s "$la" ] && sed -i 's:/[^ ]*/libgmp.la:-lgmp:' "$la"
 }

multilib_src_install_all()
 {
  unset g
  [ $stage == 0 ] && g=gmp
  fat-gentoo-move_usr $g

  unset g extra_depend ac_cv_host ac_build_alias build_alias
  unset use_musl use_uclibc stage BITS BASE_DIR LIBRARY_PATH
 }
