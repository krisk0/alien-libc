#!/bin/sh -e

# ebuild_dir realm realm ...

d=`realpath $1`
shift

while : ; do
 realm=$1
 [ -z $realm ] && break
 shift
 t=`basename $d`-$realm
 mkdir -p $t ; rm -rf $t/* ; cd $t
 for x in `ls $d` ; do
  ln -s `realpath --relative-to . $d/$x`
  [ ${x%ebuild} == $x ] ||
   {
    PN=${x%%-*}
    mv $x ${PN}-${realm}${x#$PN}
   }
 done
 cd ..
done
