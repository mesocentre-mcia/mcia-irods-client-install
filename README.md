# Introduction

[mcia-irods-client-install](https://github.com/mesocentre-mcia/mcia-irods-client-install) is a utility script for easy installation of [iRODS](http://www.irods.org) iCommands. It also performs installation of [mcia-irods-utils](https://github.com/mesocentre-mcia/mcia-irods-utils).

# Prerequisites

[mcia-irods-client-install](https://github.com/mesocentre-mcia/mcia-irods-client-install) is design to work on Linux.

Systems supported are CentOS 7 and Ubuntu 18.04 (later Ubuntu distributions may also work)

You will need the following tools
* bash
* wget

On CentOS, you will also need:
* cpio
* rpm2cpio

On Ubuntu, you wil need instead:
* dpkg-dev


# Install clients

Choose the place where you want to install iRODS iCommands (e.g. `$HOME/local/irods`) and run:

```
# clients location
prefix=$HOME/local/irods

# get the script
wget https://raw.githubusercontent.com/mesocentre-mcia/mcia-irods-client-install/irods4/icommands-install.sh
chmod a+x icommands-install.sh

# run installation
./icommands-install.sh --prefix $prefix
```

# Use

When installation is finished, you need to load iCommands into your shell environment:
```
# if running MacOs (with Zsh) you must run this first : 
#     autoload bashcompinit ; bashcompinit
source $prefix/share/irods/bashrc
```

As a MCIA user, you can also use a little helper script to configure your iRODS environment the first time you use iRODS clients on a particular Unix account:
```
source $prefix/share/irods/init.bash
```
