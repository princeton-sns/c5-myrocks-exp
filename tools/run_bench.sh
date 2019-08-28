#!/usr/bin/env bash

config=""
outdir=""

print_usage() {
    echo "Usage: $0 -c config -o outdir"
    exit 1
}

while getopts 'c:o:' flag; do
    case "${flag}" in
	c) config="${OPTARG}" ;;
	o) outdir="${OPTARG}" ;;
	*) print_usage ;;
    esac
done

if [[ -z $config || -z $outdir ]]; then
    print_usage
fi

projectdir=$(awk -F' ' '/projectdir/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
builddir=$(awk -F' ' '/builddir/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
clients=$(awk -F' ' '/clients/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
primary=$(awk -F' ' '/primary/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
backup=$(awk -F' ' '/backup/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
nworkers=$(awk -F' ' '/nworkers/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
relaydir=$(awk -F' ' '/relaydir/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
benchmark=$(awk -F' ' '/benchmark/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)
asyncprocessing=$(awk -F' ' '/asyncprocessing/{ $1=""; sub(/^[ \t\r\n]+/, "", $0); print }' $config)

scriptsdir="$projectdir/mysql_scripts"
srcdir="$projectdir/mysql-5.6"
mastercnf="$scriptsdir/tools/master.cnf"
slavecnf="$scriptsdir/tools/slave.cnf"

echo "Configuration:"
echo
echo "Config file: $config"
echo "Scripts dir: $scriptsdir"
echo "MySQL src dir: $srcdir"
echo "MySQL build dir: $builddir"
echo "Clients: $clients"
echo "Primary: $primary"
echo "Backup: $backup"
echo "Backup workers: $nworkers"
echo "Benchmark: $benchmark"
echo "Async: $asyncprocessing"
echo
echo "Out dir: $outdir"
echo

trap '{
    echo "Stopping monitors"
    ssh $primary "$scriptsdir/tools/stop_monitor.sh $pid1"
    ssh $backup "$scriptsdir/tools/stop_monitor.sh $pid2"

    echo "Stopping backup"
    ssh $backup "$scriptsdir/tools/stop_backup.sh $builddir"

    echo "Stopping primary"
    ssh $primary "$scriptsdir/tools/stop_primary.sh $builddir"
    
    exit 1
}' INT

# Create outdir
test -e $outdir || mkdir -p $outdir
outdir=$(realpath $outdir)

echo "Setting up configs"
$scriptsdir/tools/setup_configs.sh $projectdir $config $benchmark $outdir

echo "Starting primary"
ssh $primary "$scriptsdir/tools/start_primary.sh $projectdir $builddir $outdir"

echo "Starting backup"
ssh -t $backup "$scriptsdir/tools/start_backup.sh $projectdir $builddir $outdir $primary $nworkers $relaydir"

echo "Loading data"
ssh ${clients[0]} "$scriptsdir/tools/load_data.sh $projectdir $outdir $benchmark 0"
sleep 2
ssh ${clients[0]} "$scriptsdir/tools/wait_client.sh"

echo "Reading primary log position"
out=$(ssh $primary "$scriptsdir/tools/read_status.sh $builddir $mastercnf master")

logfile=$(echo "$out" | tr "\n" "\t" | cut -f6)
logpos=$(echo "$out" | tr "\n" "\t" | cut -f7)

echo "Reading primary ncommits"
mastercommits=$(ssh $primary "$scriptsdir/tools/read_ncommits.sh $builddir $mastercnf")

echo "Waiting for binlog transfer"
ssh $backup "$scriptsdir/tools/wait_transfer.sh $projectdir $builddir $slavecnf $logfile $logpos"

echo "Waiting for replication to finish"
ssh $backup "$scriptsdir/tools/wait_replication.sh $projectdir $builddir $slavecnf $mastercommits"

if [[ $asyncprocessing == "true" ]]; then
    echo "Stopping replication"
    ssh $backup "$scriptsdir/tools/stop_replication.sh $projectdir $builddir"
fi

echo "Starting clients"
i=0
for c in ${clients[@]}; do
    ssh $c "$scriptsdir/tools/start_client.sh $projectdir $outdir $benchmark $i"
    let i=$i+1
done

echo "Starting monitors"
pid1=$(ssh $primary "$scriptsdir/tools/start_monitor.sh $projectdir $builddir $outdir $mastercnf primary")

if [[ $asyncprocessing != "true" ]]; then
    pid2=$(ssh $backup "$scriptsdir/tools/start_monitor.sh $projectdir $builddir $outdir $slavecnf backup")
fi

echo "Letting clients start up"
sleep 2

echo "Waiting for clients to finish"
for c in ${clients[@]}; do
    ssh $c "$scriptsdir/tools/wait_client.sh"
done

echo "Stopping primary monitor"
ssh $primary "$scriptsdir/tools/stop_monitor.sh $pid1"

if [[ $asyncprocessing == "true" ]]; then
    echo "Reading primary log position"
    out=$(ssh $primary "$scriptsdir/tools/read_status.sh $builddir $mastercnf master")

    logfile=$(echo "$out" | tr "\n" "\t" | cut -f6)
    logpos=$(echo "$out" | tr "\n" "\t" | cut -f7)
    
    echo "Reading primary ncommits"
    mastercommits=$(ssh $primary "$scriptsdir/tools/read_ncommits.sh $builddir $mastercnf")

    echo "Waiting for binlog transfer"
    ssh $backup "$scriptsdir/tools/wait_transfer.sh $projectdir $builddir $slavecnf $logfile $logpos"

    echo "Starting backup monitor"
    pid2=$(ssh $backup "$scriptsdir/tools/start_monitor.sh $projectdir $builddir $outdir $slavecnf backup")

    echo "Starting replication"
    ssh $backup "$scriptsdir/tools/start_replication.sh $projectdir $builddir"

    echo "Waiting for replication to finish"
    ssh $backup "$scriptsdir/tools/wait_replication.sh $projectdir $builddir $slavecnf $mastercommits"
fi

echo "Stopping backup monitor"
ssh $backup "$scriptsdir/tools/stop_monitor.sh $pid2"

echo "Stopping backup"
ssh $backup "$scriptsdir/tools/stop_backup.sh $builddir"

echo "Stopping primary"
ssh $primary "$scriptsdir/tools/stop_primary.sh $builddir"

echo "Processing monitor logs"
$scriptsdir/tools/process_monitor_log.py -s primary -i $outdir/monitor.primary.csv -o $outdir

$scriptsdir/tools/process_monitor_log.py -s backup -i $outdir/monitor.backup.csv -o $outdir

