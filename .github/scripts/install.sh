#!/bin/bash 

set -x

# Script should *not* be run as root.
# Use user test
useradd -s /bin/bash -m -p test test
su - test

# Download icommands-install.sh script
wget https://raw.githubusercontent.com/mesocentre-mcia/mcia-irods-client-install/irods4/icommands-install.sh

# Execute icommands-install.sh script with prefix
export prefix=$HOME/local/irods
chmod a+x icommands-install.sh
./icommands-install.sh --prefix $prefix
