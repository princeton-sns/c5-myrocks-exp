#!/usr/bin/env bash

projectdir=$1
builddir=$2
outdir=$3
primary=$4
nworkers=$5
relaydir=$6
roimpl=$7
snapinterval=$8

print_usage() {
    echo "Usage: $0 projectdir builddir outdir primary nworkers relaydir roimpl snapinterval" >&2
    exit 1
}

if [[ $# -le 5 ]]; then
    print_usage
fi

scriptsdir="$projectdir/mysql_scripts"
srcdir="$projectdir/mysql-5.6"

if [[ -z "$snapinterval" ]]; then
    snapinterval=10000
fi

case "${roimpl}" in
    "")
	mts_dependency_order_commits=off
	slave_checkpoint_period=10000
	slave_checkpoint_group=4096
	;;
    fro)
	mts_dependency_order_commits=snapshot
	slave_checkpoint_period=$snapinterval
	slave_checkpoint_group=4096
	;;
    kro)
	mts_dependency_order_commits=snapshot
	slave_checkpoint_period=10000
	slave_checkpoint_group=4096
	;;
    co)
	mts_dependency_order_commits=snapshot
	slave_checkpoint_period=1000
	slave_checkpoint_group=1
	;;
    *) print_usage ;;
esac

echo "Checkpoint period: $slave_checkpoint_period"

# Setup log dir
test -e $builddir/data || (sudo mkdir -p $builddir/data && sudo chown -R $USER:$USER $builddir/data)
if [[ $(df -T $builddir/data | tr -s "\n" " " | cut -d' ' -f10) != "tmpfs" ]]; then
    sudo rm -rf $builddir/data/*
    sudo mount -t tmpfs -o size=16g tmpfs $builddir/data
fi
rm -rf $builddir/data/*

# Setup relay dir
test -e $relaydir || (sudo mkdir -p $relaydir && sudo chown -R $USER:$USER $relaydir)
if [[ $(df -T $relaydir | tr -s "\n" " " | cut -d' ' -f10) != "tmpfs" ]]; then
    sudo mount -t tmpfs -o size=16g tmpfs $relaydir
fi
rm -rf $relaydir/*

cd $builddir

logfile=$(cat $outdir/primary_log_pos.txt | tr "\n" "\t" | cut -f6)
logpos=$(cat $outdir/primary_log_pos.txt | tr "\n" "\t" | cut -f7)

read -r -d '' setup_backup <<- EOF
     GRANT ALL PRIVILEGES ON *.* to 'root'@'%' identified by '' WITH GRANT OPTION;
     FLUSH PRIVILEGES;

     SET global max_connections=1024;

     stop slave;
     reset slave;

     change master to master_host='$primary', master_port=3306, master_user='root', master_log_file='$logfile', master_log_pos=$logpos;

     set @@global.mts_dependency_order_commits=$mts_dependency_order_commits;
     set @@global.slave_checkpoint_period=$slave_checkpoint_period;
     set @@global.slave_checkpoint_group=$slave_checkpoint_group;
     set @@global.slave_parallel_workers=$nworkers;

     start slave;
EOF

export LD_LIBRARY_PATH="$builddir/cityhash/lib:$builddir/tbb_cmake_build/tbb_cmake_build_subdir_release"

cnf="$scriptsdir/tools/slave.cnf"

perl ./scripts/mysql_install_db --defaults-file=$cnf --force > $outdir/backup.install.log 2>&1

./bin/mysqld --defaults-file=$cnf --skip-slave-start \
	     --master-info-repository=table > $outdir/backup.log 2>&1 &

while ! ./bin/mysqladmin --defaults-file=$cnf ping &> /dev/null; do
    sleep 1
done

./bin/mysql --defaults-file=$cnf < $outdir/primary.dump

echo "$setup_backup" | ./bin/mysql --defaults-file=$cnf

cd -
      
