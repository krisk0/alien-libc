# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v3

EAPI=5

HOMEPAGE=https://github.com/krisk0/$CATEGORY
KEYWORDS='-* x86 amd64'
SLOT=0
DESCRIPTION="Some directories and symbolic links for fat gentoo"
IUSE=i386

S="$WORKDIR"

do_it()
 {
  for i in musl uclibc ; do
   cd "$D" || die
   j=$1/x86_64-linux-$i/sysroot/usr
   mkdir -p $j $1/x86_64-linux-$i/{lib{32,64},include} \
               $1/x86_64-linux-$i/x86_64-pc-linux-$i
   (
    cd $1/x86_64-linux-$i/x86_64-pc-linux-$i || die
    for k in lib{32,64} lib include ; do
     ln -s ../$k $k
    done
   )
   (
    cd $j || die
    for k in include lib32 lib64 ; do
     ln -sf ../../$k
    done
    ln -s lib64 lib
   )
   ( use i386 || use x86 ) &&
    {
     j=${j/x86_64/i386}
     mkdir -p $j $1/i386-linux-$i/{include,gmp}
     cd $1/i386-linux-$i || die
     ln -s ../x86_64-linux-$i/lib32
     ln -s lib32 lib
     cd sysroot/usr || die
     for k in include lib32 ; do
      ln -sf ../../$k
     done
     cd "$D/$1/i386-linux-$i/gmp"
     ln -s ../../x86_64-linux-$i/gmp/lib32 lib
     ln -s ../../x86_64-linux-$i/gmp/lib32 lib32
    }
   cd "$D/$1/x86_64-linux-$i" && ln -s lib64 lib || die
  done
  unset i j k
 }

src_install()
 {
  do_it usr
  do_it system
 }
