#!/usr/bin/env bash
set -e

arch="$(dpkg --print-architecture)"
echo System Architecture: $arch

mkdir -p /run/defli-python
cd /run/defli-python

git clone --single-branch https://github.com/dbsoft42/adsb-data-collector-mongodb.git
pip3 install aiohttp motor pymongo python-dateutil dnspython
