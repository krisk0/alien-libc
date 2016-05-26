# Copyright      2016 Денис Крыськов
# Distributed under the terms of the GNU General Public License v2

# Not exporting functions because uclibc-* is not the only user of the eclass
#EXPORT_FUNCTIONS src_unpack src_configure src_prepare

inherit toolchain-funcs

S="$WORKDIR/uClibc"
sha=d7339f50a2e83a5a267551c2b798f0f53a545f08
ct=crosstool-ng
SRC_URI="https://github.com/$ct/$ct/archive/$sha.zip -> ct-ng-20160310.zip"
unset ct sha

crosstool-meets-uclibc_src_unpack()
 {
  default
  ( mv uClibc-* uClibc && mv crosstool-ng-* ct-ng ) || die
  mv ct-ng/contrib/uClibc-defconfigs/uClibc-ng.config uClibc/.config || die
  rm -r ct-ng || die
 }

config()
 {
  sed -i .config -e "s:${1}=.*:${1}=\"${2}\":" || die
 }

yes_to()
 {
  for x in $* ; do
   echo "$x=y" >> .config
  done
  unset x
 }

crosstool-meets-uclibc_src_configure()
 {
  # Error messages
  #  make: x86_64-pc-linux-uclibc-gcc: Command not found
  # are harmless and should be ignored
  tc-export CC
  local base=$EPREFIX/usr/x86_64-linux-uclibc
  config RUNTIME_PREFIX $base
  config KERNEL_HEADERS $base/temp.headers/usr/include

  # crosstool-ng builds uClibc without SSP, however unpacked .config turns it on
  sed -i .config -e /UCLIBC_HAS_SSP/d

  yes_to TARGET_x86_64 UCLIBC_HAS_THREADS UCLIBC_HAS_THREADS_NATIVE \
   UCLIBC_HAS_FENV UCLIBC_HAS_WCHAR
  # no uClibc shared libraries in /lib. Turn off LDSO_SEARCH_INTERP_PATH
  echo '# LDSO_SEARCH_INTERP_PATH is not set' >> .config
  CROSS_COMPILER_PREFIX=x86_64-pc-linux-uclibc-
  uclibc_likes_it="
   CROSS_COMPILE=$CROSS_COMPILER_PREFIX
   UCLIBC_EXTRA_CFLAGS=-pipe
   STRIPTOOL=true
   LOCALE_DATA_FILENAME=uClibc-locale-030818.tgz
  "
  ( /bin/yes "" || true ) | emake $uclibc_likes_it oldconfig
 }
