#! /bin/bash

# following instructions: https://groups.google.com/g/irod-chat/c/uOdt3pwOO7Y/m/_zPY_76zAQAJ

irods_version=4.3.1
install_prefix=$HOME/.local

lsb_release -si | grep -qi Rocky && os=RedHat && variant=el$(lsb_release -sr | cut -d"." -f1)
lsb_release -si | grep -qi ubuntu && os=ubuntu && variant=$(lsb_release -sc)

module_dir=/no-module

cleanup_dirs=yes

while test $# -gt 0 ; do
    i=$1
    shift

    case $i in
        --irods-version=*)
            irods_version="${i#*=}"
            ;;
        --irods-version)
            irods_version="$1"
            shift
            ;;
        --prefix=*)
            install_prefix="${i#*=}"
            ;;
        --prefix)
            install_prefix="$1"
            shift
            ;;
        --ubuntu)
            os=ubuntu
            ;;
        --el8)
            os=el8
            ;;
        --el9)
            os=el9
            ;;
        --debug)
            echo debug mode
            set -x
            ;;
        --keep-build-dir)
            cleanup_dirs=no
            ;;
        *)
            echo Unknown option "$i"
            exit 1
            ;;
    esac
done

function pkg_url() {
    local url=$1
    local suffix=$2

    for i in $(seq 0 10) ; do
        #echo trying $url-$i$suffix
        if curl -s -I $url$i$suffix | grep "HTTP/1.1 200" > /dev/null ; then
            echo $url$i$suffix
            return
        fi
    done

    echo $url
}

if [ "$variant" = noble ] ; then
    #irods_version=4.3.3
    variant=jammy
fi

rpm_repo=https://packages.irods.org/yum/pool/${variant}/x86_64
deb_repo=https://packages.irods.org/apt/pool/${variant}/main/i

icommands_rpm=$(pkg_url "$rpm_repo/irods-icommands-$irods_version-" ".${variant}.x86_64.rpm")
runtime_rpm=$(pkg_url "$rpm_repo/irods-runtime-$irods_version-" ".${variant}.x86_64.rpm")

externals_rpms="\
$rpm_repo/irods-externals-avro-libcxx1.11.0-3-1.0-0.${variant}.x86_64.rpm \
$rpm_repo/irods-externals-boost-libcxx1.81.0-1-1.0-0.${variant}.x86_64.rpm \
$rpm_repo/irods-externals-clang-runtime13.0.0-0-1.0-1.x86_64.rpm \
$rpm_repo/irods-externals-fmt8.1.1-0-1.0-1.x86_64.rpm \
$rpm_repo/irods-externals-zeromq4-1-libcxx4.1.8-1-1.0-0.${variant}.x86_64.rpm \
"

icommands_deb=$(pkg_url "$deb_repo/irods-icommands/irods-icommands_${irods_version}-" "~${variant}_amd64.deb")
runtime_deb=$(pkg_url "$deb_repo/irods-runtime/irods-runtime_${irods_version}-" "~${variant}_amd64.deb")

if [ "$variant" = noble ] ; then
    externals_debs="\
    $deb_repo/irods-externals-avro-libcxx1.11.0-3/irods-externals-avro-libcxx1.11.0-3_1.0-1~${variant}_amd64.deb \
    $deb_repo/irods-externals-boost-libcxx1.81.0-1/irods-externals-boost-libcxx1.81.0-1_1.0-1~${variant}_amd64.deb \
    $deb_repo/irods-externals-clang-runtime13.0.1-0/irods-externals-clang-runtime13.0.1-0_1.0-1~${variant}_amd64.deb \
    $deb_repo/irods-externals-fmt8.1.1-1/irods-externals-fmt8.1.1-1_1.0-1~${variant}_amd64.deb \
    $deb_repo/irods-externals-zeromq4-1-libcxx4.1.8-1/irods-externals-zeromq4-1-libcxx4.1.8-1_1.0-2~${variant}_amd64.deb \
    "
else
    externals_debs="\
    $deb_repo/irods-externals-avro-libcxx1.11.0-3/irods-externals-avro-libcxx1.11.0-3_1.0-0~${variant}_amd64.deb \
    $deb_repo/irods-externals-boost-libcxx1.81.0-1/irods-externals-boost-libcxx1.81.0-1_1.0-0~${variant}_amd64.deb \
    $deb_repo/irods-externals-clang-runtime13.0.0-0/irods-externals-clang-runtime13.0.0-0_1.0~${variant}_amd64.deb \
    $deb_repo/irods-externals-fmt8.1.1-0/irods-externals-fmt8.1.1-0_1.0~${variant}_amd64.deb \
    $deb_repo/irods-externals-zeromq4-1-libcxx4.1.8-1/irods-externals-zeromq4-1-libcxx4.1.8-1_1.0-0~${variant}_amd64.deb
    "
fi

function rpm_extract() {
    rpm2cpio $1 | cpio -idm
}

function deb_extract() {
    dpkg-deb --extract $1 ./
}


icommands_pkg=$icommands_rpm
runtime_pkg=$runtime_rpm
externals_pkgs=$externals_rpms
pkg_extract=rpm_extract
pkg_suffix=rpm

if [ x"$os" = xubuntu ] ; then
    icommands_pkg=$icommands_deb
    runtime_pkg=$runtime_deb
    externals_pkgs=$externals_debs
    pkg_suffix=deb
    pkg_extract=deb_extract
fi

mkdir -p download

cd download
for pkg in $icommands_pkg $runtime_pkg $externals_pkgs ; do
    pkgfile=$(basename $pkg)
    if test ! -f $pkgfile ; then
        wget -O $pkgfile $pkg
    fi
done
cd ..

rm -rf dist
mkdir -p dist/lib
mkdir -p dist/bin

rm -rf extract
mkdir -p extract

cd extract

for pkg in ../download/*.$pkg_suffix ; do
    $pkg_extract $pkg
done

cp -R usr/bin ../dist
cp -R usr/lib ../dist
cp -R opt/irods-externals/*/lib ../dist

cd ..

# clean some unneeded files
find dist/lib/ -name "*.a" -delete
#rm -f dist/lib/libclang.so* dist/lib/libLTO.so* lib/clang lib/cmake

mkdir -p dist/share/irods

curl -o dist/share/irods/irods_completion.bash https://raw.githubusercontent.com/irods/irods-legacy/master/iRODS/irods_completion.bash

cat > dist/share/irods/init.bash <<EOF
#! /bin/bash

if test ! -d \$HOME/.irods ; then
    mkdir -p \$HOME/.irods
fi

# iRODS client config file
envfile=\$HOME/.irods/irods_environment.json

if test ! -f \$envfile ; then
    # create config file
    echo "Creating iRODS configuration file."

    icat=icat1.mcia.fr
    port=1247
    zone=MCIA
    username=`whoami`

    if test -n "\$PS1" ; then
        echo "Please answer a few questions:"
        read -e -p " - iCat host? " -i \$icat icat
        read -e -p " - iRODS port? " -i \$port port
        read -e -p " - iRODS zone? " -i \$zone zone
        read -e -p " - User name? " -i \$username username
    fi

    cat > \$envfile << EOF2
{
  "irods_host": "\$icat",
  "irods_port": \$port,
  "irods_user_name": "\$username",
  "irods_zone_name": "\$zone",
  "irods_encryption_algorithm": "AES-256-CBC",
  "irods_encryption_key_size": 32,
  "irods_encryption_num_hash_rounds": 16,
  "irods_encryption_salt_size": 8,
  "irods_client_server_negotiation": "request_server_negotiation",
  "irods_client_server_policy": "CS_NEG_REQUIRE"
}
EOF2

    echo "iRODS configuration file \$envfile created"
else
    echo "iRODS Configuration file \$envfile already configured"
fi

EOF

cat > dist/share/irods/relocate.sh <<EOF
#! /bin/bash

install_prefix=\$1

cat > \$install_prefix/share/irods/bashrc <<EOF2
#! /bin/bash

# iCommands environment
( echo \\\$PATH | grep -q \$install_prefix/bin ) || \
export PATH=\$install_prefix/bin:\\\$PATH

( echo \\\$LD_LIBRARY_PATH | grep -q \$install_prefix/lib ) || \
export LD_LIBRARY_PATH=\$install_prefix/lib:\\\$LD_LIBRARY_PATH

# iCommands completion
[ -f \$install_prefix/share/irods/irods_completion.bash ] && \
source \$install_prefix/share/irods/irods_completion.bash

EOF2

cat > \$install_prefix/share/irods/modulefile <<EOF2
#%Module -*- tcl -*-
##
## modulefile
##
proc ModulesHelp { } {

puts stderr "\tAdds iRODS $irods_version icommands to your environment variables,"
}

module-whatis "adds iRODS $irods_version icommands to your environment variables"

# load globus environment
# not needed

set              version              $irods_version
set              root                 \$install_prefix
set              bindir               \\\$root/bin
set              libdir               \\\$root/lib

prepend-path     PATH                 \\\$bindir
prepend-path     LD_LIBRARY_PATH      \\\$libdir

EOF2

EOF

chmod a+x dist/share/irods/relocate.sh

mkdir -p $install_prefix

cp -R dist/* $install_prefix
dist/share/irods/relocate.sh $install_prefix


if [ x"$cleanup_dirs" = xyes ] ; then
  rm -rf download dist extract
fi
