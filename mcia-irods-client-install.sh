#! /bin/bash

# Configuration

PREFIX=/usr/local

IRODS_VERSION=3.3.1
MCIA_IRODS_UTILS_VERSION=0.2

GSI_BUILD=no
GLOBUS_MAJOR=5
GLOBUS_MINOR=0
GLOBUS_MICRO=4

KRB5_BUILD=no

# Parse command line 

random_string_charlist () {
    charlist=$1
    tr -dc "$charlist" < /dev/urandom | head -c $2
}
random_filename() {
    random_string_charlist  "[:alnum:]" $1
}

BUILD_DIR=/tmp/`random_filename 12`
CLEANUP_BUILD_DIR=yes

while test $# -gt 0 ; do
    arg=$1
    shift

    case $arg in
        --irods-version)
            IRODS_VERSION=$1
            shift
            ;;
        --build-dir)
            BUILD_DIR=$1
            shift
            ;;
        --prefix)
            PREFIX=$1
            shift
            ;;
        --debug)
            echo debug mode
            set -x
            ;;
        --keep-build-dir)
            CLEANUP_BUILD_DIR=no
            ;;
        *)
          ;;
    esac
done

# some functions

cleanup_build_dir() {
    if test x$CLEANUP_BUILD_DIR = xyes ; then
        rm -rf $BUILD_DIR
    fi
}

check_ret() {
    if test x$? != x0 ; then
        cleanup_build_dir
        exit -1
    fi
}

# Do the job...

IRODS_TAR=irods-$IRODS_VERSION.tgz
IRODS_URL=https://github.com/irods/irods-legacy/archive/$IRODS_VERSION.tar.gz

# MCIA iRODS utilities
MCIA_IRODS_UTILS_URL=https://github.com/mesocentre-mcia/mcia-irods-utils/archive/$MCIA_IRODS_UTILS_VERSION.tar.gz
MCIA_IRODS_UTILS_BUILD=mcia-irods-utils-$MCIA_IRODS_UTILS_VERSION
MCIA_IRODS_UTILS_TAR=$MCIA_IRODS_UTILS_BUILD.tar.gz

# config GSI
GLOBUS_MM=$GLOBUS_MAJOR.$GLOBUS_MINOR
GLOBUS_VERSION=$GLOBUS_MM.$GLOBUS_MICRO
GLOBUS_FLAVOR=gcc64pthr
GLOBUS_INSTALLER=gt$GLOBUS_VERSION-all-source-installer
GLOBUS_TAR=$GLOBUS_INSTALLER.tar.bz2
GLOBUS_URL=http://www.globus.org/ftppub/gt$GLOBUS_MAJOR/$GLOBUS_MM/$GLOBUS_VERSION/installers/src/$GLOBUS_TAR

# config KERBEROS
KRB5_LOCATION=/usr

IRODS_HOME=$PREFIX/iRODS
IRODS_BINDIR=$IRODS_HOME/bin
IRODS_LIBDIR=$IRODS_HOME/lib
IRODS_DOCDIR=$IRODS_HOME/share/doc
IRODS_CLIENTS_BINDIR=$IRODS_HOME/clients/bin
IRODS_CLIENTS_LIBDIR=$IRODS_HOME/clients/lib
IRODS_CLIENTS_DOCDIR=$IRODS_HOME/clients/doc

GLOBUS_LOCATION=$BUILD_DIR/globus

mkdir -p $BUILD_DIR
if test x$? != x0 ; then
    cleanup_build_dir
    exit -1
fi

mkdir -p $PREFIX $IRODS_HOME $IRODS_BINDIR $IRODS_LIBDIR $IRODS_DOCDIR $IRODS_CLIENTS_BINDIR $IRODS_CLIENTS_LIBDIR $IRODS_CLIENTS_DOCDIR
check_ret

# download, compile and install Globus toolkit
if test x$GSI_BUILD = xyes -a ! -d $GLOBUS_LOCATION ; then
    echo "download and install globus toolkit"

    cd $BUILD_DIR

    if test ! -d $GLOBUS_INSTALLER ; then
        if test ! -f $GLOBUS_TAR ; then
            wget $GLOBUS_URL
        fi
        tar xvfj $GLOBUS_TAR
    fi
    cd $GLOBUS_INSTALLER

    ./configure --prefix=$GLOBUS_LOCATION --with-flavor=$GLOBUS_FLAVOR
    make globus-gsi && make install
    check_ret

    cd $GLOBUS_LOCATION
    if test ! -d lib64 ; then
        ln -s lib lib64
    fi
fi

if test ! -d $BUILD_DIR/iRODS ; then
    if test ! -f $BUILD_DIR/$IRODS_TAR ; then
        wget --no-check-certificate $IRODS_URL -O $BUILD_DIR/$IRODS_TAR
    fi

    cd $BUILD_DIR
    tar --strip-components=1 -xvf $BUILD_DIR/$IRODS_TAR
fi

cd $BUILD_DIR/iRODS

rm -f config/irods.config

# fix for irods3.0
mkdir -p installLogs

# fix for irods-3.0 3.1
for d in $/modules/*/microservices $BUILD_DIR/iRODS/lib/*/ $BUILD_DIR/iRODS/clients/*/ ; do
    mkdir -p $d/obj
done

# client install
if test x$GSI_BUILD = xyes ; then
ENABLE_GSI="--enable-gsi --globus-location=$GLOBUS_LOCATION \
--gsi-install-type=$GLOBUS_FLAVOR"
fi

perl scripts/perl/configure.pl --enable-parallel --enable-file64bit \
$ENABLE_GSI

# propagate KRB5 values to config.mk, if needed
if test x$KRB5_BUILD = xyes ; then
    sed -i -e "s/^#[ ]*KRB_AUTH[ ]*=[ ]*1$/KRB_AUTH = 1/g" -e "s/^KRB_LOC[ ]*=[ ]*.*/KRB_LOC=\/usr/g" config/config.mk
fi

pwd
make icommands GSI_SSL=ssl GSI_CRYPTO=crypto
check_ret

# move globus libraries to IRODS library path
if test x$GSI_BUILD = xyes ; then
    cp -dp $GLOBUS_LOCATION/lib64/lib* $IRODS_CLIENTS_LIBDIR/
fi
# Copy copyright licenses and other files
cp -p COPYRIGHT/Copyright.txt $IRODS_DOCDIR/
cp -p COPYRIGHT/Copyright_Addendum.txt $IRODS_DOCDIR/
cp -p LICENSE.txt $IRODS_DOCDIR/
cp -p README.txt $IRODS_DOCDIR/
cp -p config/irods.config.template $IRODS_DOCDIR/
cp -p -R $BUILD_DIR/iRODS/clients/icommands/test/rules3.0 $IRODS_DOCDIR/examples-rules3.0

# copy icommands binaries
irodsClientCommands=`find $BUILD_DIR/iRODS/clients/icommands/bin/ -maxdepth 1 -executable -type f`
for binary in $irodsClientCommands ; do
    cp -p $binary $IRODS_CLIENTS_BINDIR/
    check_ret
done

# completion files
for f in $BUILD_DIR/iRODS/irods_completion.* ; do
    cp -p $f $IRODS_CLIENTS_BINDIR/
done

# MCIA iRODS utils
if test ! -f $BUILD_DIR/$MCIA_IRODS_UTILS_TAR ; then
    wget --no-check-certificate $MCIA_IRODS_UTILS_URL -O $BUILD_DIR/$MCIA_IRODS_UTILS_TAR
    check_ret
fi

cd $BUILD_DIR
tar -xvf $BUILD_DIR/$MCIA_IRODS_UTILS_TAR
check_ret

cd $BUILD_DIR/$MCIA_IRODS_UTILS_BUILD
python setup.py install --prefix=$IRODS_HOME

cat > $PREFIX/init.bash <<EOF
#! /bin/bash

if test ! -d \$HOME/.irods ; then
    mkdir -p \$HOME/.irods
fi

# iRODS client config file
envfile=\$HOME/.irods/.irodsEnv

if test ! -f \$envfile ; then
    # create config file
    echo "Creating iRODS configuration file."

    icat=icat0.mcia.univ-bordeaux.fr
    port=1247
    zone=MCIA
    username=$USER
    defaultresource=siterg-ubx

    if test -n \$PS1 ; then
        echo "Please answer a few questions:"
        read -e -p " - iCat host? " -i \$icat icat
        read -e -p " - iRODS port? " -i \$port port
        read -e -p " - iRODS zone? " -i \$zone zone
        read -e -p " - User name? " -i \$username username
        read -e -p " - Default resource? " -i \$defaultresource defaultresource
    fi

    cat > \$envfile << EOF2
# iRODS@MCIA
irodsHost '\$icat'
irodsPort \$port
irodsZone '\$zone'
irodsUserName '\$username'
irodsDefResource \$defaultresource
irodsAuthScheme password
irodsAuthFileName \$HOME/.irods/.irods-mcia
EOF2

    echo "iRODS configuration file \$envfile created"
else
    echo "iRODS Configuration file \$envfile already configured"
fi
EOF
chmod a+x $PREFIX/init.bash

PYTHON_PKG_DIR_SUFFIX=$(python -c "import sys, os; print os.sep.join(['python' + sys.version[:3], 'site-packages'])")
IRODS_PYTHON_SITE_PKG_DIR=$IRODS_LIBDIR/$PYTHON_PKG_DIR_SUFFIX

cat > $PREFIX/bashrc <<EOF
#! /bin/bash

# iCommands environment
( echo \$PATH | grep -q $IRODS_CLIENTS_BINDIR ) || export PATH=$IRODS_BINDIR:$IRODS_CLIENTS_BINDIR:\$PATH
( echo \$LD_LIBRARY_PATH | grep -q $IRODS_CLIENTS_LIBDIR ) || export LD_LIBRARY_PATH=$IRODS_LIBDIR:$IRODS_CLIENTS_LIBDIR:\$LD_LIBRARY_PATH
( echo \$PYTHONPATH | grep -q $IRODS_PYTHON_SITE_PKG_DIR) || export PYTHONPATH=$IRODS_PYTHON_SITE_PKG_DIR:\$PYTHONPATH

# iCommands completion
[ -f $IRODS_CLIENTS_BINDIR/irods_completion.bash ] && source $IRODS_CLIENTS_BINDIR/irods_completion.bash
EOF

if test x$? != x0 ; then
    cleanup_build_dir
    exit -1
fi
chmod a+x $PREFIX/bashrc
if test x$? != x0 ; then
    cleanup_build_dir
    exit -1
fi

cat > $PREFIX/modulefile <<EOF
#%Module -*- tcl -*-
##
## modulefile
##
proc ModulesHelp { } {

  puts stderr "\tAdds iRODS clients to your environment variables,"
}

module-whatis "adds iRODS clients to your environment variables"

# need globus environment
module load globus

set              version              $IRODS_VERSION
set              root                 $PREFIX
set              bindir               \$root/iRODS/bin
set              libdir               \$root/iRODS/lib
set              pypkgdir             \$libdir/$PYTHON_PKG_DIR_SUFFIX 
set              clients_bindir       \$root/iRODS/clients/bin
set              clients_libdir       \$root/iRODS/clients/lib

setenv           IRODS_HOME           \$root/iRODS

prepend-path     PATH                 \$clients_bindir
prepend-path     LD_LIBRARY_PATH      \$clients_libdir

prepend-path     PATH                 \$bindir
prepend-path     LD_LIBRARY_PATH      \$libdir

prepend-path     PYTHONPATH           \$pypkgdir

EOF



cleanup_build_dir
exit 0
