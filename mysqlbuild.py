#!/usr/bin/python

import os
import sys
import argparse

install_dir_fmt= '_build-5.6-{0}'

os.environ["WITH_LZ4"]='/usr/lib/x86_64-linux-gnu'

cmake_debug= "cmake . -DCMAKE_BUILD_TYPE=Debug -DWITH_SSL=system  -DMYSQL_MAINTAINER_MODE=1 -DENABLE_DTRACE=0 -DWITH_ZSTD=/usr "

cmake_release= "cmake . -DCMAKE_BUILD_TYPE=RelWithDebInfo -DWITH_SSL=system -DWITH_ZLIB=bundled -DWITH_LZ4=/usr/lib/x86_64-linux-gnu -DWITH_ZSTD=system -DMYSQL_MAINTAINER_MODE=0 -DENABLED_LOCAL_INFILE=1 -DENABLE_DTRACE=0 -DCMAKE_CXX_FLAGS=\"-march=native\" "

parser= argparse.ArgumentParser()
parser.add_argument('--clean', action= 'store_true')
parser.add_argument('--release', action= 'store_true')
args= parser.parse_args()

if args.release:
  install_dir= install_dir_fmt.format("Release")
  cmake_cmd= cmake_release + "-DCMAKE_INSTALL_PREFIX=" + install_dir
else:
   install_dir= install_dir_fmt.format("Debug") 
   cmake_cmd= cmake_debug + "-DCMAKE_INSTALL_PREFIX=" + install_dir

if args.clean:
  os.system("rm CMakeCache.txt")
  os.system(cmake_cmd)
os.system("make -j8 -Otarget && make install")
