# Copyright 1999-2016 Gentoo Foundation
# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v2

EAPI=5
REALM=${PN##*-}

K_NOUSENAME=yes
K_NOSETEXTRAVERSION=yes
K_DEBLOB_AVAILABLE=0
ETYPE=sources
inherit kernel-2
detect_version

DESCRIPTION="Linux kernel for musl or uclibc"
HOMEPAGE=https://www.kernel.org
SRC_URI="$KERNEL_URI"

KEYWORDS="-* amd64"

src_install()
 {
  local t=$ED/usr/x86_64-linux-$REALM
  emake ARCH=x86 INSTALL_HDR_PATH="$t" V=0 headers_install
  
  ( cd $t && find . -type f -name '.*' -delete) || die
 }

pkg_postinst()
 {
  :
 }
