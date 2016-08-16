# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v3

EAPI=5

HOMEPAGE=https://github.com/krisk0/$CATEGORY
KEYWORDS='-* x86 amd64'
SLOT=0
DESCRIPTION="Some directories and symbolic links for fat gentoo"
IUSE=i386

S="$WORKDIR"

src_install()
 {
  for i in musl uclibc ; do
   cd "$ED" || die
   j=usr/x86_64-linux-$i/sysroot/usr
   mkdir -p $j usr/x86_64-linux-$i/{lib{32,64},include}
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
     mkdir -p $j usr/i386-linux-$i/include
     cd usr/i386-linux-$i || die
     ln -s ../x86_64-linux-$i/lib32
     ln -s lib32 lib
     cd sysroot/usr || die
     for k in include lib32 ; do
      ln -sf ../../$k
     done
    }
   cd "$ED/usr/x86_64-linux-$i" && ln -s lib64 lib || die
  done
  unset i j k
 }
