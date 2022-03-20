#!/bin/bash 

set -x

# Script should *not* be run as root.
echo '# Use user test'
useradd -s /bin/bash -m -p test test
su - test

export prefix=$HOME/local/irods

echo '# Download icommands-install.sh script'
wget https://raw.githubusercontent.com/mesocentre-mcia/mcia-irods-client-install/irods4/icommands-install.sh

echo "# Execute icommands-install.sh script (prefix=$prefix)"
chmod a+x icommands-install.sh
./icommands-install.sh --prefix $prefix
