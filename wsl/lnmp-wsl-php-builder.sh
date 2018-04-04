#！/bin/bash

#
# Build php in WSL(Debian Ubuntu)
#
# $ lnmp-wsl-php-builder.sh 5.6.35 [--skipbuild] [tar] [deb]
#

if [ -z "$1" ];then
  exec echo "

Build php in WSL Debian by shell script

Usage:

$ lnmp-wsl-php-builder.sh 7.2.4

$ lnmp-wsl-php-builder.sh 5.6.35 --skipbuild tar deb

"
else

PHP_VERSION=$1

fi

set -ex

################################################################################

PHP_TIMEZONE=PRC

PHP_URL=http://cn2.php.net/distributions

PHP_INSTALL_LOG=/tmp/php-builder/$(date +%s).install.log

################################################################################

PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
PHP_CPPFLAGS="$PHP_CFLAGS"
PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

export CFLAGS="$PHP_CFLAGS"
export CPPFLAGS="$PHP_CPPFLAGS"
export LDFLAGS="$PHP_LDFLAGS"

################################################################################

command -v wget || ( sudo apt update && sudo apt install wget -y)

mkdir -p /tmp/php-builder || echo

test "$PHP_VERSION" = 'apt' && PHP_VERSION=7.2.4

################################################################################

case "${PHP_VERSION}" in
  5.6.* )
    export PHP_NUM=56
    ;;

  7.0.* )
    export PHP_NUM=70
    ;;

  7.1.* )
    export PHP_NUM=71
    ;;

  7.2.* )
    export PHP_NUM=72
    ;;

  * )
    echo "ONLY SUPPORT 5.6 +"
    exit 1
esac

export PHP_PREFIX=/usr/local/php${PHP_NUM}

export PHP_INI_DIR=/usr/local/etc/php${PHP_NUM}

################################################################################

# verify os

. /etc/os-release

#
# ID=debian
# VERSION_ID="9"
#
# ID=ubuntu
# VERSION_ID="16.04"
#

if [ "$ID" = 'debian' ] && [ "$VERSION_ID" = "9" ] && [ $PHP_NUM = "56" ];then
  echo "debian9 notsupport php56"
  exit 1;
fi

################################################################################

# 1. download

sudo mkdir -p /usr/local/src || echo

if ! [ -d /usr/local/src/php-${PHP_VERSION} ];then

  echo -e "Download php src ...\n\n"

  cd /usr/local/src ; sudo chmod 777 /usr/local/src

  wget ${PHP_URL}/php-${PHP_VERSION}.tar.gz || wget http://php.net/distributions/php-${PHP_VERSION}.tar.gz

  echo -e "Untar ...\n\n"

  tar -zxvf php-${PHP_VERSION}.tar.gz > /dev/null 2>&1
fi

cd /usr/local/src/php-${PHP_VERSION}

################################################################################

# 2. install packages

# sudo apt update

sudo apt install -y libargon2-0-dev > /dev/null 2>&1 || export ARGON2=false

export PHP_DEP="libedit2 \
zlib1g \
libxml2 \
openssl \
libsqlite3-0 \
libxslt1.1 \
libpq5 \
libmemcached11 \
libsasl2-2 \
libfreetype6 \
libpng16-16 \
$( sudo apt install -y libjpeg62-turbo > /dev/null 2>&1 && echo libjpeg62-turbo ) \
$( sudo apt install -y libjpeg-turbo8 > /dev/null 2>&1 && echo libjpeg-turbo8 ) \
$( if [ $PHP_NUM = "72" ];then \
echo $( if ! [ "${ARGON2}" = 'false' ];then \
          echo "libargon2-0";
          fi ); \
echo "libsodium18 libzip4"; \
   fi ) \
libyaml-0-2 \
$( sudo apt install -y libtidy-0.99-0 > /dev/null 2>&1 && echo libtidy-0.99-0 ) \
$( sudo apt install -y libtidy5 > /dev/null 2>&1 && echo libtidy5 ) \
libxmlrpc-epi0 \
libbz2-1.0 \
libexif12 \
libgmp10 \
libc-client2007e \
libkrb5-3 \
libxpm4 \
$( sudo apt install -y libwebp6 > /dev/null 2>&1 && echo libwebp6 ) \
$( sudo apt install -y libwebp5 > /dev/null 2>&1 && echo libwebp5 ) \
libenchant1c2a \
libldap-2.4-2 \
libsnmp30 \
snmp"

sudo apt install -y $PHP_DEP

_apt(){

export DEP_SOFTS="autoconf \
                   lsb-release \
                   dpkg-dev \
                   file \
                   libc6-dev \
                   make \
                   pkg-config \
                   re2c \
                   gcc g++ \
                   libedit-dev \
                   zlib1g-dev \
                   libxml2-dev \
                   libssl-dev \
                   libsqlite3-dev \
                   libxslt1-dev \
                   libcurl4-openssl-dev \
                   libpq-dev \
                   libmemcached-dev \
                   libsasl2-dev \
                   libfreetype6-dev \
                   libpng-dev \
                   $( sudo apt install -y libjpeg62-turbo-dev > /dev/null 2>&1 && echo libjpeg62-turbo-dev ) \
                   $( sudo apt install -y libjpeg-turbo8-dev > /dev/null 2>&1 && echo libjpeg-turbo8-dev ) \
                   \
                   $( test $PHP_NUM = "56" && echo "" ) \
                   $( test $PHP_NUM = "70" && echo "" ) \
                   $( test $PHP_NUM = "71" && echo "" ) \
                   $( if [ $PHP_NUM = "72" ];then \
                        echo $( if ! [ "${ARGON2}" = 'false' ];then \
                                  echo "libargon2-0-dev";
                                fi ); \
                        echo "libsodium-dev libzip-dev"; \
                      fi ) \
                      \
                   libyaml-dev \
                   libtidy-dev \
                   libxmlrpc-epi-dev \
                   libbz2-dev \
                   libexif-dev \
                   libgmp3-dev \
                   libc-client2007e-dev \
                   libkrb5-dev \
                   \
                   libxpm-dev \
                   libwebp-dev \
                   libenchant-dev \
                   libldap2-dev \
                   libpspell-dev \
                   libsnmp-dev \
                   "

for soft in ${DEP_SOFTS}
do
    sudo echo $soft >> ${PHP_INSTALL_LOG}
done

sudo apt update ; sudo apt install -y --no-install-recommends ${DEP_SOFTS}
}

if [ "$1" = apt ];then _apt ; exit $?; fi

_apt

################################################################################


_builder(){

# 3. bug

debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"

# https://bugs.php.net/bug.php?id=74125
if [ ! -d /usr/include/curl ]; then
    sudo ln -sTf "/usr/include/$debMultiarch/curl" /usr/local/include/curl
fi

# https://stackoverflow.com/questions/34272444/compiling-php7-error
sudo ln -sf /usr/lib/libc-client.so.2007e.0 /usr/lib/x86_64-linux-gnu/libc-client.a

#
# debian 9 php56 configure: error: Unable to locate gmp.h
#

sudo ln -sf /usr/include/x86_64-linux-gnu/gmp.h /usr/include/gmp.h

#
# https://stackoverflow.com/questions/43617752/docker-php-and-freetds-cannot-find-freetds-in-know-installation-directories
#

# sudo ln -sf /usr/lib/x86_64-linux-gnu/libsybdb.so /usr/lib/

#
# configure: error: Cannot find ldap libraries in /usr/lib.
#
# @link https://blog.csdn.net/ei__nino/article/details/8598490

sudo cp -frp /usr/lib/x86_64-linux-gnu/libldap* /usr/lib/

################################################################################

# 4. configure

CONFIGURE="--prefix=${PHP_PREFIX} \
    --with-config-file-path=${PHP_INI_DIR} \
    --with-config-file-scan-dir=${PHP_INI_DIR}/conf.d \
    --disable-cgi \
    --enable-fpm \
    --with-fpm-user=nginx \
    --with-fpm-group=nginx \
    \
    --with-curl \
    --with-gettext \
    --with-kerberos \
    --with-libedit \
    --with-openssl \
        --with-system-ciphers \
    --with-pcre-regex \
    --with-pdo-mysql \
    --with-pdo-pgsql=shared \
    --with-xsl=shared \
    --with-zlib \
    --with-mhash \
    --with-gd \
        --with-freetype-dir=/usr/lib \
        --disable-gd-jis-conv \
        --with-jpeg-dir=/usr/lib \
        --with-png-dir=/usr/lib \
        --with-xpm-dir=/usr/lib \
    --enable-ftp \
    --enable-mysqlnd \
    --enable-bcmath \
    --enable-libxml \
    --enable-inline-optimization \
    --enable-mbregex \
    --enable-mbstring \
    --enable-pcntl=shared \
    --enable-shmop=shared \
    --enable-soap=shared \
    --enable-sockets=shared \
    --enable-sysvmsg=shared \
    --enable-sysvsem=shared \
    --enable-sysvshm=shared \
    --enable-xml \
    --enable-zip \
    --enable-calendar=shared \
    --enable-intl=shared \
    \
    $( test $PHP_NUM = "56" && echo "--enable-opcache --enable-gd-native-ttf" ) \
    $( test $PHP_NUM = "70" && echo "--enable-gd-native-ttf --with-webp-dir=/usr/lib" ) \
    $( test $PHP_NUM = "71" && echo "--enable-gd-native-ttf --with-webp-dir=/usr/lib" ) \
    \
    $( if [ $PHP_NUM = "72" ];then \
         echo $( if ! [ "${ARGON2}" = 'false' ];then \
                   echo "--with-password-argon2";
                 fi ); \
         echo "--with-sodium --with-libzip --with-webp-dir=/usr/lib --with-pcre-jit"; \
       fi ) \
    --enable-exif \
    --with-bz2 \
    --with-tidy \
    --with-gmp \
    --with-imap=shared \
        --with-imap-ssl \
    --with-xmlrpc \
    \
    --with-pic \
    --with-enchant=shared \
    --enable-fileinfo \
    --with-ldap=shared \
        --with-ldap-sasl \
    --enable-phar \
    --enable-posix=shared \
    --with-pspell=shared \
    --enable-shmop=shared \
    --with-snmp=shared \
    --enable-wddx=shared \
    "

for a in ${CONFIGURE}; do sudo echo $a >> ${PHP_INSTALL_LOG}; done

################################################################################

./configure ${CONFIGURE}

# 5. make

make -j "$(nproc)"

# 6. make install

sudo rm -rf ${PHP_PREFIX} || echo

sudo make install

# 7. install extension

if [ -d ${PHP_INI_DIR} ];then sudo mv ${PHP_INI_DIR} ${PHP_INI_DIR}.$( date +%s ).backup; fi

sudo mkdir -p ${PHP_INI_DIR}/conf.d

sudo cp /usr/local/src/php-${PHP_VERSION}/php.ini-development ${PHP_INI_DIR}/php.ini

# php5 not have php-fpm.d

cd ${PHP_PREFIX}/etc/

if ! [ -d php-fpm.d ]; then
  # php5
  sudo mkdir php-fpm.d
  sudo cp php-fpm.conf.default php-fpm.d/www.conf

  { \
    echo '[global]'; \
    echo "include=${PHP_PREFIX}/etc/php-fpm.d/*.conf"; \
  } | sudo tee php-fpm.conf

else
  sudo cp php-fpm.d/www.conf.default php-fpm.d/www.conf
  sudo cp php-fpm.conf.default php-fpm.conf
fi

${PHP_PREFIX}/bin/php -v

${PHP_PREFIX}/bin/php -i | grep ".ini"

${PHP_PREFIX}/sbin/php-fpm -v

# sudo ${PHP_PREFIX}/bin/pear config-set php_ini ${PHP_INI_DIR}/php.ini
# sudo ${PHP_PREFIX}/bin/pecl config-set php_ini ${PHP_INI_DIR}/php.ini

sudo ${PHP_PREFIX}/bin/pecl update-channels

# sudo ${PHP_PREFIX}/bin/pear config-show >> ${PHP_INSTALL_LOG}
# sudo ${PHP_PREFIX}/bin/pecl config-show >> ${PHP_INSTALL_LOG}

sudo ${PHP_PREFIX}/bin/php-config >> ${PHP_INSTALL_LOG} || echo > /dev/null 2>&1

PHP_EXTENSION="igbinary \
               redis \
               $( if [ $PHP_NUM = "56" ];then echo "memcached-2.2.0"; else echo "memcached"; fi ) \
               $( if [ $PHP_NUM = "56" ];then echo "xdebug-2.5.5"; else echo "xdebug"; fi ) \
               $( if [ $PHP_NUM = "56" ];then echo "yaml-1.3.1"; else echo "yaml"; fi ) \
               $( if ! [ $PHP_NUM = "56" ];then echo "swoole"; else echo ""; fi ) \
               mongodb"

for extension in ${PHP_EXTENSION}
do
  echo $extension >> ${PHP_INSTALL_LOG}
  sudo ${PHP_PREFIX}/bin/pecl install $extension || echo
done

# 8. enable extension

echo "date.timezone=${PHP_TIMEZONE:-PRC}" | sudo tee ${PHP_INI_DIR}/conf.d/date_timezone.ini
echo "error_log=/var/log/php${PHP_NUM}.error.log" | sudo tee ${PHP_INI_DIR}/conf.d/error_log.ini

wsl-php-ext-enable.sh pdo_pgsql \
                      xsl \
                      pcntl \
                      shmop \
                      soap \
                      sockets \
                      sysvmsg \
                      sysvsem \
                      sysvshm \
                      calendar \
                      intl \
                      imap \
                      enchant \
                      ldap \
                      posix \
                      pspell \
                      shmop \
                      snmp \
                      wddx \
                      \
                      mongodb \
                      igbinary \
                      redis \
                      memcached \
                      xdebug \
                      $( test $PHP_NUM != "56" && echo "swoole" ) \
                      yaml \
                      opcache


echo "
[global]

pid = /var/run/php${PHP_NUM}-fpm.pid

error_log = /var/log/php${PHP_NUM}-fpm.error.log

[www]

access.log = /var/log/php${PHP_NUM}-fpm.access.log

user = nginx
group = nginx

request_slowlog_timeout = 5
slowlog = /var/log/php${PHP_NUM}-fpm.slow.log

; listen 9000
; env[APP_ENV] = development

;
; wsl
;

listen = /var/run/php-fpm${PHP_NUM}.sock
listen.owner = nginx
listen.group = nginx
listen.mode = 0660
env[APP_ENV] = wsl

" | sudo tee ${PHP_PREFIX}/etc/php-fpm.d/zz-$( . /etc/os-release ; echo $ID ).conf

cd /var/log

if ! [ -f php${PHP_NUM}-fpm.error.log ];then sudo touch php${PHP_NUM}-fpm.error.log ; fi
if ! [ -f php${PHP_NUM}-fpm.access.log ];then sudo touch php${PHP_NUM}-fpm.access.log ; fi
if ! [ -f php${PHP_NUM}-fpm.slow.log ];then sudo touch php${PHP_NUM}-fpm.slow.log; fi

sudo chmod 777 php${PHP_NUM}-*

# Change php ini

sudo sed -i 's#^extension="xdebug.so".*#zend_extension=xdebug#g' ${PHP_INI_DIR}/php.ini
}

################################################################################

_test(){

${PHP_PREFIX}/bin/php -v

${PHP_PREFIX}/bin/php -i | grep .ini

${PHP_PREFIX}/sbin/php-fpm -v

set +x

for ext in `ls /usr/local/src/php-${PHP_VERSION}/ext`; \
do echo '*' $( ${PHP_PREFIX}/bin/php -r "if(extension_loaded('$ext')){echo '[x] $ext';}else{echo '[ ] $ext';}" ); done
}

################################################################################

_write_version(){
echo "\`\`\`bash" | sudo tee -a ${PHP_PREFIX}/README.md

${PHP_PREFIX}/bin/php -v | sudo tee -a ${PHP_PREFIX}/README.md

echo "\`\`\`" | sudo tee -a ${PHP_PREFIX}/README.md

echo "\`\`\`bash" | sudo tee -a ${PHP_PREFIX}/README.md

${PHP_PREFIX}/bin/php -i | grep .ini | sudo tee -a ${PHP_PREFIX}/README.md

echo "\`\`\`" | sudo tee -a ${PHP_PREFIX}/README.md

echo "\`\`\`bash" | sudo tee -a ${PHP_PREFIX}/README.md

${PHP_PREFIX}/sbin/php-fpm -v | sudo tee -a ${PHP_PREFIX}/README.md

echo "\`\`\`" | sudo tee -a ${PHP_PREFIX}/README.md

echo "\`\`\`bash" | sudo tee -a ${PHP_PREFIX}/README.md

cat ${PHP_INSTALL_LOG} | sudo tee -a ${PHP_PREFIX}/README.md

echo "\`\`\`" | sudo tee -a ${PHP_PREFIX}/README.md

for ext in `ls /usr/local/src/php-${PHP_VERSION}/ext`; \
do echo '*' $( ${PHP_PREFIX}/bin/php -r "if(extension_loaded('$ext')){echo '[x] $ext';}else{echo '[ ] $ext';}" ) | sudo tee -a ${PHP_PREFIX}/README.md ; done

cat ${PHP_PREFIX}/README.md

set -x

}

################################################################################

for command in "$@"
do
  test $command = '--skipbuild' && export SKIP_BUILD=1
done

test "${SKIP_BUILD}" != 1 &&  ( _builder ; _test ; _write_version )

################################################################################

_tar(){
  cd /usr/local ; sudo tar -zcvf php${PHP_NUM}.tar.gz php${PHP_NUM}

  cd etc ; sudo tar -zcvf php${PHP_NUM}-etc.tar.gz php${PHP_NUM}

  sudo mv ${PHP_PREFIX}.tar.gz /

  sudo mv ${PHP_INI_DIR}-etc.tar.gz /
}

################################################################################

_deb(){

cd /tmp; sudo rm -rf khs1994-wsl-php-${PHP_VERSION} || echo ; mkdir -p khs1994-wsl-php-${PHP_VERSION}/DEBIAN ; cd khs1994-wsl-php-${PHP_VERSION}

################################################################################

echo "Package: khs1994-wsl-php
Version: ${PHP_VERSION}
Prioritt: optional
Section: php
Architecture: amd64
Maintainer: khs1994 <khs1994@khs1994.com>
Bugs: https://github.com/khs1994-docker/lnmp/issues
Depends: $( echo ${PHP_DEP} | sed "s# #, #g" )
Homepage: https://lnmp.khs1994.com
Description: server-side, HTML-embedded scripting language (default)
 PHP (recursive acronym for PHP: Hypertext Preprocessor) is a widely-used
 open source general-purpose scripting language that is especially suited
 for web development and can be embedded into HTML.

" > DEBIAN/control

echo "#!/bin/bash

# log

cd /var/log

if ! [ -f php${PHP_NUM}.error.log ];then sudo touch php${PHP_NUM}.error.log ; fi
if ! [ -f php${PHP_NUM}-fpm.error.log ];then sudo touch php${PHP_NUM}-fpm.error.log ; fi
if ! [ -f php${PHP_NUM}-fpm.access.log ];then sudo touch php${PHP_NUM}-fpm.access.log ; fi
if ! [ -f php${PHP_NUM}-fpm.slow.log ];then sudo touch php${PHP_NUM}-fpm.slow.log; fi

sudo chmod 777 php${PHP_NUM}*

# bin sbin

for file in \$( ls ${PHP_PREFIX}/bin ); do sudo ln -sf ${PHP_PREFIX}/bin/\$file /usr/local/bin/ ; done

sudo ln -sf ${PHP_PREFIX}/sbin/php-fpm /usr/local/sbin/
" > DEBIAN/postinst

echo "#!/bin/bash
echo
echo \"Meet issue? Please see https://github.com/khs1994-docker/lnmp/issues \"
echo
" > DEBIAN/postrm

echo "#!/bin/bash

if [ -d ${PHP_INI_DIR} ];then
  sudo mv ${PHP_INI_DIR} ${PHP_INI_DIR}.\$( date +%s ).backup
fi

echo -e \"

----------------------------------------------------------------------

Thanks for using khs1994-wsl-php !

Please find the official documentation for khs1994-wsl-php here:
* https://github.com/khs1994-docker/lnmp/tree/master/wsl

Meet issue? please see:
* https://github.com/khs1994-docker/lnmp/issues

----------------------------------------------------------------------

\"
" > DEBIAN/preinst

################################################################################

chmod -R 755 DEBIAN

mkdir -p usr/local/etc

sudo cp -a ${PHP_PREFIX} usr/local/php${PHP_NUM}

sudo cp -a ${PHP_INI_DIR} usr/local/etc/

cd ..

DEB_NAME=khs1994-wsl-php_${PHP_VERSION}-${ID}-$( lsb_release -cs )_amd64.deb

sudo dpkg-deb -b khs1994-wsl-php-${PHP_VERSION} $DEB_NAME

sudo cp -a /tmp/${DEB_NAME} /

echo "$ sudo dpkg -i ${DEB_NAME}"

sudo rm -rf $PHP_PREFIX

sudo rm -rf $PHP_INI_DIR

sudo dpkg -i /${DEB_NAME}

# test

_test

}

################################################################################

for command in "$@"
do
  test $command = 'tar' && _tar
  test $command = 'deb' && _deb
done

ls -la /*.tar.gz

ls -la /*.deb
