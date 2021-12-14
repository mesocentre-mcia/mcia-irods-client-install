# Introduction

[mcia-irods-client-install](https://github.com/mesocentre-mcia/mcia-irods-client-install) is a utility script for easy installation of [iRODS](http://www.irods.org) iCommands. It also performs installation of [mcia-irods-utils](https://github.com/mesocentre-mcia/mcia-irods-utils).

# Prerequisites

[mcia-irods-client-install](https://github.com/mesocentre-mcia/mcia-irods-client-install) is design to work on Linux.

You will need the following tools
* bash
* wget
* tar
* sed
* make
* perl
* gcc/g++


# Install clients

Choose the place where you want to install iRODS iCommands (call it `$HOME/local/irods`) and run:

```
# clients location
prefix=$HOME/local/irods

# get the script
wget https://raw.githubusercontent.com/mesocentre-mcia/mcia-irods-client-install/master/mcia-irods-client-install.sh
chmod a+x mcia-irods-client-install.sh

# run installation
./mcia-irods-client-install.sh --prefix $prefix
```

# Use

When installation is finished, you need to load iCommands into your shell environment:
```
# if running MacOs (with Zsh) you must run this first : 
#     autoload bashcompinit ; bashcompinit
source $prefix/bashrc
```

The first time you use iRODS clients on a particular Unix accoutn, you can also use a little helper script to configure your iRODS environment:
```
source $prefix/init.bash
```
