#!/usr/bin/env bash

projectdir=$1
builddir=$2
outdir=$3
primary=$4
nworkers=$5
relaydir=$6
roimpl=$7

print_usage() {
    echo "Usage: $0 projectdir builddir outdir primary nworkers relaydir roimpl" >&2
    exit 1
}

if [[ $# -le 5 ]]; then
    print_usage
fi

scriptsdir="$projectdir/mysql_scripts"
srcdir="$projectdir/mysql-5.6"

case "${roimpl}" in
    "")
	mts_dependency_order_commits=off
	slave_checkpoint_period=100
	slave_checkpoint_group=4096
	;;
    fro)
	mts_dependency_order_commits=snapshot
	slave_checkpoint_period=100
	slave_checkpoint_group=4096
	;;
    kro)
	mts_dependency_order_commits=snapshot
	slave_checkpoint_period=100
	slave_checkpoint_group=4096
	;;
    co)
	mts_dependency_order_commits=snapshot
	slave_checkpoint_period=1
	slave_checkpoint_group=1
	;;
    *) print_usage ;;
esac

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
     stop slave;
     reset slave;

     change master to master_host='$primary', master_port=3306, master_user='root', master_log_file='$logfile', master_log_pos=$logpos;

     set @@global.slave_use_idempotent_for_recovery=yes;
     set @@global.mts_dependency_replication=stmt;
     set @@global.mts_dependency_order_commits=$mts_dependency_order_commits;
     set @@global.rpl_skip_tx_api=true;
     set @@global.mts_dependency_size=1000000;
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
      
