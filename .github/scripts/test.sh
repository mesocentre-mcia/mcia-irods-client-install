#!/bin/bash

set -x

# Source $prefix/share/irods/bashrc
export prefix=$HOME/local/irods
source $prefix/share/irods/bashrc

# Release:
cat /etc/lsb-release /etc/redhat-release

# Check ils version
ils -h | grep 'Version'
