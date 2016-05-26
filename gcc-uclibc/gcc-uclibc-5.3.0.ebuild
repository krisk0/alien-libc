# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v2

EAPI=5
REALM=${PN#*-}

# To take patches from crosstool-ng repository, inherit crosstool-meets-uclibc
inherit fat-gentoo toolchain-funcs check-reqs crosstool-meets-uclibc

HOMEPAGE=http://gcc.gnu.org
LICENSE=GPL-3
sha=18d3b936f47efe36c0a314f1ce75ac6013e059de
g=mirror://gnu/gcc/gcc-$PV/gcc-$PV.tar.bz2
mu=musl-cross
[ $REALM == uclibc ] && SRC_URI="$SRC_URI $g"
[ $REALM == musl ] && SRC_URI="$g
 https://github.com/GregorR/$mu/archive/$sha.tar.gz -> ${mu}-20160103.tar.gz
"

KEYWORDS='-* amd64'
SLOT=$PV

CHECKREQS_DISK_BUILD=1000M

RDEPEND="$CATEGORY/binutils-$REALM $CATEGORY/sysroot"

# Bash >= 4 required for ${x^^} uppercasing to work

# There is no circular dependency around this package. If emerge thinks
#  otherwise, issue command
#    emerge alien-libc/uclibc-pass0
#  before emerging this package
p=|| ( $CATEGORY/uclibc $CATEGORY/uclibc-pass0 )
DEPEND="$RDEPEND $CATEGORY/mpc $CATEGORY/isl >=app-shells/bash-4
 $( [ $REALM == uclibc ] && echo $p )"

S="$WORKDIR/gcc-$PV"

src_unpack()
 {
  default
  mkdir patch || die

  # Will fail if $S has spaces inside
  [ $REALM == musl ] ||
  (
   einfo 'Moving uclibc patches' &&
   mv crosstool-ng-* ct && [ -d ct ] &&
   mv `find ct -type d -wholename */gcc/$PV`/* patch/ &&
   rm -r ct
  ) \
  || die

  [ $REALM == uclibc ] ||
   (
    einfo 'Moving musl patches' &&
    mv ${mu}-* mu && [ -d mu ] &&
    mv `find mu -type f -name gcc-${PV}-musl.diff` patch/ &&
    rm -r mu
   ) \
  || die

  # select mode of operation: 0 or 1
  mode=0
  has_version $CATEGORY/$REALM && mode=1
 }

src_prepare()
 {
  # apply crosstool-ng or musl-cross patches.
  # Die here if WORKDIR has spaces inside
  for x in $WORKDIR/patch/* ; do
   patch -p1 < $x || die
  done

  # don't build or install gcc-{ar,nm,ranlib} executables
  cd gcc || die
  sed -i Makefile.in \
   -e 's:gcc-ar$(exeext) gcc-nm$(exeext) gcc-ranlib$(exeext)::' \
   -e 's: install-gcc-ar::' || die
  # remove gcc-ar.c so error triggers earlier, if the hack above fails
  rm gcc-ar.c || die

  # direct exec tool wrapper to pre-installed executables
  p=/usr/x86_64-linux-$REALM
  local bin=${EPREFIX}$p/bin/$(basename $p)-
  # EPREFIX with spaces not supported
  for x in as ld nm ; do
   sed -i exec-tool.in -e s:@ORIGINAL_${x^^}_FOR_TARGET@:${bin}$x: || die
  done
  for x in bfd gold ; do
   sed -i exec-tool.in -e s:@ORIGINAL_LD_${x^^}_FOR_TARGET@:${bin}ld.$x: || die
  done
  sed -i exec-tool.in -e s:@ORIGINAL_PLUGIN_LD_FOR_TARGET@:${bin}ld: || die
 }

src_configure()
 {
  einfo "Mode of operation: $mode"
  local -a o
  local c="--target=$(basename $p)"
  local sysroot=$S/sysroot
  [ $mode == 0 ] &&
   {
    # gcc for uClibc needs uClibc headers
    [ $REALM == musl ] || fat-gentoo-copy_sysroot $sysroot temp.headers include
    # for musl just needs kernel headers
    [ $REALM == musl ] && sysroot=${EPREFIX}$p/sysroot
   }
  [ $mode == 1 ] && sysroot=${EPREFIX}$p/sysroot
  c="$c --with-sysroot=$sysroot"
  [ $mode == 0 ] && c="$c --prefix=${EPREFIX}$p" ||
                    c="$c --prefix=${EPREFIX}/usr"
  [ $mode == 0 ] && c="$c --with-local-prefix=$sysroot"
  [ $mode == 0 ] && [ $REALM == musl ] &&
   {
    o+=(--with-newlib)
    o+=(--disable-decimal-float)
    o+=(--disable-shared)
   } \
  ||
   o+=(--enable-shared)
  [ $mode == 0 ] && o+=(--enable-threads=no) || o+=(--enable-threads=posix)
  #[ $mode == 0 ] && o+=(--disable-shared) || o+=(--enable-shared)
  o+=(--with-pkgversion=$CATEGORY)
  [ $REALM == uclibc ] &&
   {
    o+=(--enable-__cxa_atexit)
    o+=(--enable-target-optspace)
   }
  for x in werror multilib nls lib{mudflap,gomp,ssp,sanitizer} \
    libquadmath{,-support} ; do
   einfo "disabling support for $x"
   o+=(--disable-$x)
  done
  [ $mode == 0 ] && o+=(--disable-libatomic)
  for x in gmp mpfr isl mpc ; do
   o+=(--with-$x=$p/gmp)
  done
  [ $mode == 1 ] && o+=(--enable-lto) || o+=(--disable-lto)
  [ $mode == 1 ] && o+=(--enable-gold)
  [ $mode == 1 ] && c="$c --enable-languages=c,c++" ||
   {
    tc-export CC CXX
    c="$c CC_FOR_BUILD=$CC"
    c="$c CXX_FOR_BUILD=$CXX"
    c="$c --enable-languages=c"
    o+=(--disable-lto)
    o+=(--disable-plugins)
    for x in ar as ranlib ld strip; do
     local y=$($CC -print-prog-name=$x|xargs realpath)
     c="$c ${x^^}=$y"
    done
   }
  [ $REALM == uclibc ] &&
   {
    local -a fl
    fl+=("-static-libgcc")
    fl+=("-Wl,-Bstatic,-lstdc++,-Bdynamic")
    fl+=("-lm")
    o+=("--with-host-libstdcxx=${fl[*]}")
   }
  mkdir -p $REALM ; cd $REALM
  ../configure $c "${o[@]}" || die
 }

src_compile()
 {
  # GCC fails to find x86_64-linux-uclibc-ar which is in $prefix/bin
  export PATH=${EPREFIX}$p/bin:$PATH
  emake -C $REALM
 }

src_install()
 {
  b=$(basename $p)
  emake -C $REALM DESTDIR="$ED" install
  [ $mode == 1 ] &&
   {
    # move usr/x -> usr/$b/x
    cd $ED && mv usr u && mkdir -p usr/$b && cd u && mv `ls` ..$p/ || die

    # fix broken .la
    i=${EPREFIX}$p/$b/lib64/libstdc++.la
    sed -i ${ED}$p/$b/lib64/libcilkrts.la -e \
     "s|dependency_libs=.*|dependency_libs=' -ldl -lpthread $i'|" || die

    # help gcc find libgcc_s.so
    cd ${ED}$p/lib/gcc/$b/$PV || die
    ln -s ../../../../x86_64-linux-$REALM/lib64/libgcc_s.so
    [ -f libgcc_s.so ] || die
   }

  # share/info is a file collision point. man7 aint not interesting
  einfo "cleaning share/"
  ( cd $ED/$p/share && rm -r man/man7 info ) || die

  # link tools so GCC will find them
  einfo "creating links for binutils and gcc frontend"
  cd $ED/$p/libexec/gcc/$b/$PV || die
  for x in as ar nm ranlib strip ld ld.bfd ld.gold ; do
   ln -sf ../../../../bin/x86_64-pc-linux-${REALM}-$x $x || die
  done

  # link x86_64-*uclibc-gcc -> x86_64-linux-uclibc-gcc
  (
   cd $ED/$p/bin &&
   ln -s ${b}-gcc x86_64-pc-linux-uclibc-gcc &&
   ln -s ${b}-gcc          x86_64-uclibc-gcc &&
   ( [ $mode == 0 ] || ln -s ${b}-g++ x86_64-pc-linux-uclibc-g++ ) &&
   ( [ $mode == 0 ] || ln -s ${b}-g++          x86_64-uclibc-g++ )
  ) \
  || die

  # musl-cross/ has no stddef.h installed by GCC, and it is able to compile
  #  zlib. Compiler just installed cannot compile zlib, error message:
  #   error: conflicting types for 'wchar_t'
  # We solve the problem by removing the legacy header
  [ $mode == 0 ] || find . -type f -name stddef.h -exec rm {} \; || die

  einfo "removing empty directories"
  cd $ED && find . -type d -empty -exec rmdir {} \;

  unset p BASE_DIR use_musl use_uclibc stage mode x i j b g mu
 }
