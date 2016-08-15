# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v3

EAPI=5

HOMEPAGE=https://github.com/krisk0/$CATEGORY
KEYWORDS='-* x86 amd64'
SLOT=0
DESCRIPTION="Some useful directories and symbolic links"
IUSE='i386'

S="$WORKDIR"

src_install()
 {
  for i in musl uclibc ; do
   cd "$ED"
   j=usr/x86_64-linux-$i/sysroot/usr
   mkdir -p $j usr/x86_64-linux-$i/lib32
   (
    cd $j
    for k in include lib32 lib64 ; do
     ln -sf ../../$k
    done
    ln -s lib64 lib
   )
   use i386 && 
    (
     mkdir -p usr/i386-linux-$i
     cd usr/i386-linux-$i
     ln -s ../x86_64-linux-$i/lib32
     ln -s lib32 lib
    )
   cd $ED/usr/x86_64-linux-$i && mkdir lib64 && ln -s lib64 lib || die
  done
  
  unset i j k
 }
