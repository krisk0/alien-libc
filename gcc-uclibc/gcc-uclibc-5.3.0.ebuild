# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v3

EAPI=5

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
DEPEND="$RDEPEND 
|| ( $CATEGORY/mpc $CATEGORY/mpc-$REALM )
|| ( $CATEGORY/isl $CATEGORY/isl-$REALM )
>=app-shells/bash-4
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
  [ $REALM == musl ] &&
   {
    # Take ld-musl-*.so.1 away from /lib. Patch musl-cross patch
    local lib32=$BASE_DIR/lib32
    local lib64=$BASE_DIR/lib64
    sed \
     -e "s:/lib/ld-musl-i386:$lib32/ld-musl-i386:g" \
     -e "s:/lib/ld-musl-x86_64:$lib64/ld-musl-x86_64:g" \
     -i $WORKDIR/patch/* || die
    sed -e s://:/:g -i $WORKDIR/patch/*
   }
  # TODO: move ld64-uClibc.so.0 away from /lib. Must change this file and 
  #  uclibc ebuild
  
  # apply crosstool-ng or musl-cross patches.
  # Die here if WORKDIR has spaces inside
  for x in $WORKDIR/patch/* ; do 
   epatch $x
  done
  # further patch gcc.c
  EPATCH_SOURCE="$FILESDIR" EPATCH_FORCE=yes EPATCH_SUFFIX=patch epatch

  # don't build or install gcc-{ar,nm,ranlib} executables
  cd gcc || die
  sed -i Makefile.in \
   -e 's:gcc-ar$(exeext) gcc-nm$(exeext) gcc-ranlib$(exeext)::' \
   -e 's: install-gcc-ar::' || die
  # remove gcc-ar.c so error triggers earlier, if the hack above fails
  rm gcc-ar.c || die

  # direct exec tool wrapper to pre-installed executables
  local cpu=${CHOST%%-*}
  p=$BASE_DIR
  usr=`dirname $p|sed s:/::g`
  local bin=${EPREFIX}$p/bin/$(basename $p)-
  # EPREFIX with spaces not supported
  for x in as ld nm ; do
   sed -i exec-tool.in -e s:@ORIGINAL_${x^^}_FOR_TARGET@:${bin}$x: || die
  done
  for x in bfd gold ; do
   sed -i exec-tool.in -e s:@ORIGINAL_LD_${x^^}_FOR_TARGET@:${bin}ld.$x: || die
  done
  sed -i exec-tool.in -e s:@ORIGINAL_PLUGIN_LD_FOR_TARGET@:${bin}ld: || die
  
  # sanitize library search directory
  sed -i $S/gcc/gcc.c -e 's:"/lib/":"":g' -e 's:"/usr/lib/":"":g' || die
 }

src_configure()
 {
  einfo "Mode of operation: $mode stage=$stage CC=$CC CXX=$CXX"
  local -a o
  local c="--target=$(basename $p)"
  
  # Native compiler created with this .ebuild does not work, disabling it
  #  with imposssible condition $stage == 111
  [ $stage == 111 ] && 
   {
    c+=" --host=$(basename $p)"
    PATH=${EPREFIX}$p/bin:$PATH
   }
  local sysroot=$S/sysroot
  [ $mode == 0 ] &&
   {
    # gcc for uClibc needs uClibc headers
    [ $REALM == uclibc ] && 
     {
      fat-gentoo-copy_sysroot $sysroot temp.headers include
      # xgcc executable will try to find libc.so and other libraries in
      #  $S/uclibc/./gcc/ rather than sysroot/...
      mkdir -p $S/uclibc/gcc/
      cp $sysroot/$usr/lib/* $S/uclibc/gcc/ || die
     }
    # for musl just need kernel headers
    [ $REALM == musl ] && sysroot=${EPREFIX}$p/sysroot
   }
  [ $mode == 1 ] && 
   {
    sysroot=${EPREFIX}$p/sysroot
    [ -f $sysroot/usr/lib/libc.so ] || die
   }
  c="$c --with-sysroot=$sysroot"
  [ $mode == 0 ] && c="$c --prefix=${EPREFIX}$p" ||
                    c="$c --prefix=${EPREFIX}/$usr"
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
  local ep=${EPREFIX}$p
  for x in gmp mpfr mpc ; do
   # use dynamic library in $p/lib{32,64}/lib${x}*.so* if available
   [ -f $ep/include/$x.h ] && o+=(--with-$x=$ep) || o+=(--with-$x=$ep/gmp)
  done
  # use dynamic library $p/lib{32,64}libisl*.so* if availbale
  [ -d $ep/include/isl ] && o+=(--with-isl=$ep) || o+=(--with-isl=$ep/gmp)
  [ $mode == 1 ] && 
   {
    o+=(--enable-lto)
    o+=(--enable-gold)
    # native-system-header-dir is relative to sysroot
    o+=(--with-native-system-header-dir=/$usr/include)
    c="$c --enable-languages=c,c++"
   } ||
   {
    c="$c --enable-languages=c"
    o+=(--disable-lto)
    o+=(--disable-plugins)
   }
  for x in ld ar as ranlib ld strip; do
   local y=$ep/bin/x86_64-linux-$REALM-$x
   [ -f $y ] || die "no such file $y"
   c="$c ${x^^}_FOR_TARGET=$y"
  done
  [ $REALM == uclibc ] &&
   {
    local -a fl
    fl+=("-static-libgcc")
    fl+=("-Wl,-Bstatic,-lstdc++,-Bdynamic")
    fl+=("-lm")
    o+=("--with-host-libstdcxx=${fl[*]}")
   }
  mkdir -p $REALM ; cd $REALM
  einfo "configure c=$c"
  einfo "configure o=${o[@]}"
  ../configure $c "${o[@]}" || die
 }

src_compile()
 {
  # Set path to binutils
  export PATH=${EPREFIX}$p/bin:$PATH
  local e=''
  #[ $stage == 1 ] && e="BOOT_CFLAGS=-g"
  emake -C $REALM $e
 }

src_install()
 {
  b=$(basename $p)
  emake -C $REALM DESTDIR="$ED" install
  [ $mode == 1 ] &&
   {
    # move usr/x -> usr/$b/x
    local usr=${p#/} ; usr=${usr%%/*}
    cd $ED && mv $usr u && mkdir -p $usr/$b && cd u && mv `ls` ..$p/ &&
     cd .. && rmdir u || die
    local compiler_is_native=

    # fix broken .la
    cd ${ED}$p/$b/lib64 &&
     {
      # Compiler installs its libraries into ${EPREFIX}$p/$b/lib64/
      i=${EPREFIX}$p/$b/lib64/libstdc++.la
     }\
    ||
     {
      cd ${ED}$p/lib64 || die
      # Compiler installs its libraries into ${EPREFIX}$p/lib64/
      i=${EPREFIX}$p/lib64/libstdc++.la
      compiler_is_native=1
     }
    sed -i libcilkrts.la -e \
     "s|dependency_libs=.*|dependency_libs=' -ldl -lpthread $i'|" || die
    [ $compiler_is_native ] ||
     {
      # help gcc/g++ find libgcc_s.so and other libraries
      i="$(ls *.so*) $(ls *.a)"
      cd ${ED}$p/lib/gcc/$b/$PV || die
      for j in $i ; do
       ln -s ../../../../x86_64-linux-$REALM/lib64/$j
      done
     }
    
    # help compiled code find libstdc++.so
    cd ${ED}$p/lib64 || die
    for j in $i ; do
     ln -s ../x86_64-linux-$REALM/lib64/$j
    done
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
   ln -s ${b}-gcc x86_64-pc-linux-${REALM}-gcc &&
   ln -s ${b}-gcc          x86_64-${REALM}-gcc &&
   [ $mode == 0 ] || 
    (
     ln -s ${b}-g++ x86_64-pc-linux-${REALM}-g++ &&
     ln -s ${b}-g++          x86_64-${REALM}-g++
    )
  ) \
  || die

  cd $ED

  einfo "removing empty directories"
  find . -type d -empty -exec rmdir {} \;

  # Help gcc find its tools
  g=${CPU}-linux-${REALM}
  cd $ED/$p/libexec/gcc/$g/${PV} || die
  for x in cpp gcov gcov-tool ; do
   i=../../../../bin/${g}-$x
   [ -f $i ] && ln -s $i $x || die
  done

  unset p mode x i j b g mu usr
  unset use_musl use_uclibc stage BITS BASE_DIR LIBRARY_PATH
 }
