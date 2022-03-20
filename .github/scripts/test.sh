#!/bin/bash

set -x

echo "# Source $prefix/share/irods/bashrc"
export prefix=$HOME/local/irods
source $prefix/share/irods/bashrc

echo '# Release:'
cat /etc/lsb-release /etc/redhat-release

echo '# ils -h | grep Version'
ils -h | grep 'Version'
