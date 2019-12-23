#!/usr/bin/env bash

projectdir=$1
builddir=$2
outdir=$3

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 projectdir builddir outdir" >&2
    exit 1
fi

scriptsdir="$projectdir/mysql_scripts"
srcdir="$projectdir/mysql-5.6"

# Setup log dir
test -e $builddir/data || (sudo mkdir -p $builddir/data && sudo chown -R $USER:$USER $builddir/data)
if [[ $(df -T $builddir/data | tr -s "\n" " " | cut -d' ' -f10) != "tmpfs" ]]; then
    sudo rm -rf $builddir/data/*
    sudo mount -t tmpfs -o size=16g tmpfs $builddir/data
fi
rm -rf $builddir/data/*

cd $builddir

read -r -d '' setup_primary <<- EOF
     drop database if exists fdr;
     create database fdr;

     GRANT ALL PRIVILEGES ON *.* to 'root'@'%' identified by '' WITH GRANT OPTION;
     FLUSH PRIVILEGES;

     SET global max_connections=1024;

     flush tables with read lock;

     unlock tables;
EOF

export LD_LIBRARY_PATH="$builddir/cityhash/lib:$builddir/tbb_cmake_build/tbb_cmake_build_subdir_release"

cnf="$scriptsdir/tools/master.cnf"

perl ./scripts/mysql_install_db --defaults-file=$cnf --force > $outdir/primary.install.log 2>&1

./bin/mysqld --defaults-file=$cnf > $outdir/primary.log 2>&1 &

while ! ./bin/mysqladmin --defaults-file=$cnf ping &> /dev/null; do
    sleep 1
done

echo "$setup_primary" | ./bin/mysql --defaults-file=$cnf

$scriptsdir/tools/read_status.sh $builddir $cnf master > $outdir/primary_log_pos.txt

./bin/mysqldump --defaults-file=$cnf --all-databases > $outdir/primary.dump

cd -
