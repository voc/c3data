#!/bin/bash

apt-get update
apt-get install curl ca-certificates gcc make autoconf python-dev libpython-dev autotools-dev automake libevent-dev -y
cd /tmp
git clone https://github.com/facebook/watchman.git
cd watchman
git checkout v4.7.0
./autogen.sh
./configure --enable-statedir=/tmp
make
make install
mv watchman /usr/local/bin/watchman
