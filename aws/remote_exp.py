#!/usr/bin/python

import boto
import boto.ec2
from boto.ec2 import EC2Connection
from boto.vpc import VPCConnection
import fabric

import os
import sys
import subprocess
import time
from multiprocessing import Process

# Default settings for starting new instances.
# XXX Should probably go into a config file.
SUBNET_ID = 'subnet-95bce7b8'
SECURITY_GROUP = 'sg-1d531961'
IMAGE_ID='ami-040435bd4ab1b69de' 
EC2_USER='ubuntu@'
KEYFILE = '~/.ssh/jmfaleiro.pem'
REGION = 'us-east-1'
SERVER_INSTANCE_TYPE = 'c5.18xlarge'
CLIENT_INSTANCE_TYPE = 'c4.2xlarge'
LIB_PATHS='export LD_LIBRARY_PATH=/home/ubuntu/mysql-5.6/jemalloc/lib:/home/ubuntu/mysql-5.6/sql/tbb_cmake_build/tbb_cmake_build_subdir_release:/home/ubuntu/mysql-5.6/cityhash/src/.libs; ' 

def launch_instances(n_instances, region, image_id=IMAGE_ID, 
                    instance_type=SERVER_INSTANCE_TYPE, 
                    subnet_id=SUBNET_ID, 
                    security_group=SECURITY_GROUP):

  ec2 = boto.ec2.connect_to_region(region)
  r = ec2.run_instances(image_id=image_id, min_count=n_instances, max_count=n_instances, 
                                  instance_type=instance_type,
                                  subnet_id=subnet_id,
                                  security_group_ids=[security_group])

  assert(len(r.instances) == n_instances)
  
  while True:
    for i in r.instances:
      i.update()
      if i.state != 'running':
        started = False
    if started == False:
      started = True
      time.sleep(5)
    else:
      break

  time.sleep(60)
  ping_test(r.instances)
  return r.instances

# Returns a list of stopped instance ids.
def get_stopped_instances(region):
  ec2 = boto.ec2.connect_to_region(region)
  reservations = ec2.get_all_reservations()
  stopped = []
  for r in reservations:
    for i in r.instances:
      if i.state == 'stopped':
        stopped.append(i.id)
  return stopped

def get_private_key_path():
  return os.path.expanduser('~/.ssh/jmfaleiro.pem')
    
def ping_test(instances):

  # Test that we're able to connect and do *something* on 
  # a list of instances.
  for i in instances:
    while True:
      conx = fabric.Connection(
                   host=i.public_dns_name,
                   user="ubuntu",
                   connect_kwargs={
                     "key_filename": get_private_key_path(),
                   },
              )
      result = conx.run('ls')
      if not result.ok:
        time.sleep(5)
      else:
        break # while True:

def start_instances(region, instance_ids):
  ec2 = boto.ec2.connect_to_region(region)
  instances = ec2.start_instances(instance_ids=instance_ids)
  started = True
  while True:
    for i in instances:
      i.update()
      if i.state != 'running':
        started = False
    if started == False:
      started = True
      time.sleep(5)
    else:
      break
  return instances

def start_mysql_instances(region):
  ec2 = botol.ec2.connection_to_region(region)
  reservations = ec2.get_all_reservations()
     
def dump_mysql_master(instance):
  conx = fabric.Connection(
                host=instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  conx.run(LIB_PATHS + 'cd mysql-5.6/_build-5.6-Release/; ~/mysql_scripts/dump_master.py')
  conx.close()


def create_relay_dir(instance):
  conx = fabric.Connection(
                host=instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  relay_dir = "~/relay"
  cmd1 = "if [[ ! -e {0} ]]; then mkdir {0}; fi".format(relay_dir)
  cmd2 = ("if [[ $(! mount -l | grep {0}) != *{0}* ]]; "
         "then sudo mount -t tmpfs -o size=32g tmpfs {0}; fi").format(relay_dir)
  conx.run("{0}; {1};".format(cmd1, cmd2))
  
  conx.close()


def setup_mysql_master(instance):
  conx = fabric.Connection(
                host=instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  try:
    conx.run('kill -9 `ps aux | pgrep mysqld`')
  except Exception:
    sys.exc_clear()

  conx.run(LIB_PATHS + 'cd mysql-5.6; rm -rf _build-5.6-Release/data/mysqld.*; ~/mysql_scripts/setup_master.py')
  conx.close()

def get_log_pos():
  with open('log_pos_out') as f:
    lines= f.readlines()
    for l in lines:
      parts= l.split()
      if parts[0] == "File:":
        log_file= parts[1]
      elif parts[0] == "Position:":
        log_pos= parts[1]
  return (log_file, log_pos)

def get_master_metadata(m_instance, s_instance):
  conx = fabric.Connection(
                host=s_instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  copy_cmd_fmt= 'scp -i ~/.ssh/jmfaleiro.pem ubuntu@{0}:~/mysql-5.6/_build-5.6-Release/{1} .' 
  dump_cmd= copy_cmd_fmt.format(m_instance.private_ip_address, 'master.dump')
  log_pos_cmd= copy_cmd_fmt.format(m_instance.private_ip_address, 'log_pos_out')
  conx.run(LIB_PATHS + 'cd mysql-5.6/_build-5.6-Release; ' + dump_cmd)
  conx.run(LIB_PATHS + 'cd mysql-5.6/_build-5.6-Release; ' + log_pos_cmd)
  conx.close()

def push_master_data(instance, debug):
  filepath_fmt= '~/mysql-5.6/_build-5.6-{0}/'
  if debug:
    filepath= filepath_fmt.format('Debug')
  else:
    filepath= filepath_fmt.format('Release')

  host = 'ubuntu@' + instance.public_dns_name + ':'
  os.system('scp -i ' + get_private_key_path() + ' -o StrictHostKeyChecking=no ' + ' master.dump ' + host + filepath) 

def get_error_file(instance):
  filepath= '~/mysql-5.6/_build-5.6-Release/data/mysqld.2/mysql_error.log'
  host = 'ubuntu@' + instance.public_dns_name + ':'
  os.system('scp -i ' + get_private_key_path() + ' ' + host + filepath + ' .')

def get_result_file(instance, instance_type):
  filepath = os.path.join('~/mysql-5.6/_build-5.6-Release', instance_type + '.out')
  host = 'ubuntu@' + instance.public_dns_name + ':'
  os.system('scp -i ' + get_private_key_path() + ' ' + host + filepath + ' .')


def setup_mysql_slave(m_instance, s_instance, debug):
  create_relay_dir(m_instance)
  create_relay_dir(s_instance)
  dump_mysql_master(m_instance)
  get_master_metadata(m_instance, s_instance)
  conx = fabric.Connection(
                host=s_instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  arg_fmt = " --master {0}"
  # logfile, logpos = get_log_pos()
  arg_str = arg_fmt.format(m_instance.private_ip_address)

  exp_dir_fmt= '_build-5.6-{0}'
  if debug:
    arg_str= arg_str + ' --debug'
    exp_dir= exp_dir_fmt.format('Debug')
  else:
    exp_dir= exp_dir_fmt.format('Release')

  try:
    conx.run('kill -9 `ps aux | pgrep mysqld`')
  except Exception:
    sys.exc_clear()

  conx.run(LIB_PATHS + ' cd mysql-5.6; rm -rf ' + exp_dir + '/data/mysqld.*; ~/mysql_scripts/setup_slave.py' + arg_str)
  conx.close()


def setup_mysql_slave_debug(m_instance, s_instance):
  get_master_metadata(m_instance)
  push_master_data(s_instance)
  conx = fabric.Connection(
                host=s_instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  arg_fmt = " --master {0} --logfile {1} --logpos {2}"
  logfile, logpos = get_log_pos()
  arg_str = arg_fmt.format(m_instance.private_ip_address, str(logfile), str(logpos))

  try:
    conx.run('kill -9 `ps aux | pgrep mysqld`')
  except Exception:
    sys.exc_clear()

  conx.run(LIB_PATHS + ' cd mysql-5.6; rm -rf _build-5.6-Debug/data/mysqld.*; ~/mysql_scripts/setup_slave_debug.py' + arg_str)
  conx.close()



def stop_slave_sql(instance, debug):
  conx = fabric.Connection(
                host=instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )
  cmd_prefix_fmt= 'cd mysql-5.6/_build-5.6-{0}/; '
  if debug:
    cmd_prefix= cmd_prefix_fmt.format('Debug')
  else:
    cmd_prefix= cmd_prefix_fmt.format('Release')

  conx.run(LIB_PATHS + cmd_prefix + ' bin/mysql --defaults-file=slave.cnf -e \" stop slave sql_thread;\"')
  conx.close()

def setup_mts_slave(instance, debug):
  conx = fabric.Connection(
                host=instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  cmd_prefix_fmt= 'cd mysql-5.6/_build-5.6-{0}/; '
  if debug:
    cmd_prefix= cmd_prefix_fmt.format('Debug')
  else:
    cmd_prefix= cmd_prefix_fmt.format('Release')


  conx.run(LIB_PATHS + cmd_prefix + ' bin/mysql --defaults-file=slave.cnf < setup_slave') 
  conx.close()

def start_slave_sql(instance, debug):
  conx = fabric.Connection(
                host=instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  cmd_prefix_fmt= 'cd mysql-5.6/_build-5.6-{0}/; '
  if debug:
    cmd_prefix= cmd_prefix_fmt.format('Debug')
  else:
    cmd_prefix= cmd_prefix_fmt.format('Release')

  conx.run(LIB_PATHS + cmd_prefix + ' bin/mysql --defaults-file=slave.cnf -e \" start slave sql_thread;\"')
  conx.close()

def run_downloaded_multi(instances, nqueries, setups, duration, interval):
  for s in setups:
    run_downloaded_exp(instances, nqueries, s, duration, interval, False)

def setup_downloaded_exp(instances, nqueries, concurrency, duration, interval, debug):
  setup_mysql_master(instances[0])
  print 'Done setting up master....'

  setup_mysql_slave(instances[0], instances[1], debug)
  stop_slave_sql(instances[1], debug)

  client_proc = Process(target=run_client, args=(instances[0], instances[2], nqueries, concurrency))
  master_measure = Process(target=measure_mysql_instance, args=('master', instances[0], duration, interval))

  client_proc.start()
  master_measure.start()
 
  client_proc.join()
  master_measure.join()

  print "Sleeping..."
  time.sleep(60)
  print "Running slave..."

def run_downloaded_exp(instances, nqueries, concurrency, duration, interval, debug):
  setup_downloaded_exp(instances, nqueries, concurrency, duration, interval, debug)

  if not debug:
    slave_measure = Process(target=measure_mysql_instance, args=('slave', instances[1], duration, interval))

  stop_slave(instances[1], debug)
  setup_mts_slave(instances[1], debug)
  set_slave_threads(instances[1], concurrency, debug)
  start_slave(instances[1], debug)

  if not debug:
    slave_measure.start()
    slave_measure.join()

    get_result_file(instances[0], 'master')
    get_result_file(instances[1], 'slave')
    get_result_file(instances[1], 'producer')
    get_result_file(instances[1], 'next_waits')
    get_error_file(instances[1])

    os.system('mv master.out master.' + str(concurrency))
    os.system('mv slave.out slave.' + str(concurrency))
    os.system('mv producer.out producer.' + str(concurrency))
    os.system('mv next_waits.out next_waits.' + str(concurrency))
    os.system('grep \"Wakeups:\" mysql_error.log > slave.err.' + str(concurrency))

def run_multi(instances, nqueries, conc_list, duration, interval):
  for c in conc_list:
    run_mysql_exp(instances, nqueries, c, duration, interval)


def setup_master_slave(m_instance, s_instance, concurrency, debug):
#  setup_mysql_master(m_instance)
  setup_mysql_slave(m_instance, s_instance, debug)
  stop_slave(s_instance, debug)
  setup_mts_slave(s_instance, debug)
  set_slave_threads(s_instance, concurrency, debug)
  start_slave(s_instance, debug)

def set_slave_threads_again(s_instance, concurrency):
  stop_slave(s_instance, False)
  setup_mts_slave(s_instance, False)
  set_slave_threads(s_instance, concurrency, False)
  start_slave(s_instance, False)
 

def run_mysql_exp(instances, nqueries, concurrency, duration, interval):
#  setup_mysql_master(instances[0])
#  setup_mysql_slave(instances[0], instances[1], False)
 
#  stop_slave(instances[1], False)
#  setup_mts_slave(instances[1], False)
#  set_slave_threads(instances[1], concurrency, False)
#  start_slave(instances[1], False)

  client_proc = Process(target=run_client, args=(instances[0], instances[2], nqueries, 256))
  master_measure = Process(target=measure_mysql_instance, args=('master', instances[0], duration, interval))
  slave_measure = Process(target=measure_mysql_instance, args=('slave', instances[1], duration, interval))

  client_proc.start()
  master_measure.start()
  slave_measure.start()

  client_proc.join()
  master_measure.join()
  slave_measure.join()

  get_result_file(instances[0], 'master')
  get_result_file(instances[1], 'slave')
  get_result_file(instances[1], 'producer')

  os.system('mv master.out master.' + str(concurrency))
  os.system('mv slave.out slave.' + str(concurrency))
  os.system('mv producer.out producer.' + str(concurrency))

def stop_slave(instance, debug):
  cmd_prefix_fmt= 'cd mysql-5.6/_build-5.6-{0}/; '
  if debug:
    cmd_prefix= cmd_prefix_fmt.format('Debug')
  else:
    cmd_prefix= cmd_prefix_fmt.format('Release')

  cmd = cmd_prefix + ' bin/mysql --defaults-file=slave.cnf -e \"stop slave;\" '
  conx = fabric.Connection(host=instance.public_dns_name, 
                           user="ubuntu",
                           connect_kwargs={
                            "key_filename": get_private_key_path(),
                           },
                        )
  conx.run(cmd)
  conx.close()

def start_slave(instance, debug):
  cmd_prefix_fmt= 'cd mysql-5.6/_build-5.6-{0}/; '
  if debug:
    cmd_prefix= cmd_prefix_fmt.format('Debug')
  else:
    cmd_prefix= cmd_prefix_fmt.format('Release')

  cmd = cmd_prefix + ' bin/mysql --defaults-file=slave.cnf -e \"start slave;\" '
  conx = fabric.Connection(host=instance.public_dns_name, 
                           user="ubuntu",
                           connect_kwargs={
                            "key_filename": get_private_key_path(),
                           },
                        )
  conx.run(cmd)
  conx.close()

def set_slave_threads(instance, thread_count, debug):
  cmd_prefix_fmt= 'cd mysql-5.6/_build-5.6-{0}/; '
  if debug:
    cmd_prefix= cmd_prefix_fmt.format('Debug')
  else:
    cmd_prefix= cmd_prefix_fmt.format('Release')

  cmd_fmt = cmd_prefix + ' bin/mysql --defaults-file=slave.cnf -e \"set @@global.slave_parallel_workers={0};\" '
  
  conx = fabric.Connection(host=instance.public_dns_name, 
                           user="ubuntu",
                           connect_kwargs={
                            "key_filename": get_private_key_path(),
                           },
                        )
  conx.run(cmd_fmt.format(str(thread_count)))
  conx.close()

def run_local_client(m_instance, nqueries, concurrency):
  conx = fabric.Connection(
                host=m_instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  chdir_cmd = 'cd mysql-5.6/_build-5.6-Release/'
  exp_cmd_fmt = './bin/mysqlslap --socket=data/mysqld.1/mysqld.1.sock --auto-generate-sql --number-of-queries={0} --concurrency={1} --auto-generate-sql-add-autoincrement --auto-generate-sql-load-type=insert --user=root  --commit=1'

  conx.run(LIB_PATHS + chdir_cmd + ';' + exp_cmd_fmt.format(str(nqueries), str(concurrency)))
  conx.close()

def run_client(m_instance, e_instance, nqueries, concurrency):
  conx = fabric.Connection(
                host=e_instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  chdir_cmd = 'cd mysql-5.6/_build-5.6-Release/bin'
  exp_cmd_fmt = './mysqlslap --host={0} --port=3306  --auto-generate-sql --number-of-queries={1} --concurrency={2} --auto-generate-sql-add-autoincrement --auto-generate-sql-load-type=write --user=root  --commit=1'

  master_host = m_instance.private_ip_address
  conx.run(LIB_PATHS + chdir_cmd + ';' + exp_cmd_fmt.format(master_host, str(nqueries), str(concurrency)))
  conx.close()


def measure_mysql_instance(instance_type, instance, duration, interval):
  conx = fabric.Connection(
                host=instance.public_dns_name,
                user="ubuntu",
                connect_kwargs={
                  "key_filename": get_private_key_path(),
                },
        )

  chdir_cmd = 'cd mysql-5.6'
  config = '{0}.cnf'.format(instance_type)
  output = '{0}.out'.format(instance_type)

  measure_cmd_fmt = '~/mysql_scripts/measure.py --config {0} --duration {1} --interval {2} --output {3}'
  measure_cmd = measure_cmd_fmt.format(config, str(duration), str(interval), output) 
  conx.run(LIB_PATHS + chdir_cmd + ';' + measure_cmd)
  conx.close()

def do_mysql_measurements(ins):
  assert(False)
  blah()

# Returns a list of running instances.
def get_running_instances(region):
	ec2 = boto.ec2.connect_to_region(region)
	reservations = ec2.get_all_reservations()
	running = []
	for r in reservations:
		for i in r.instances:
			if i.state == 'running':
				running.append(i)
	return running

# Stop the specified list of instances.
def stop_instances(region, instance_list):
	ec2 = boto.ec2.connect_to_region(region)
	instance_ids = list(map(lambda x: x.id, instance_list))
	stopped = ec2.stop_instances(instance_ids=instance_ids)
	while True:
		try_again = False
		for inst in stopped:
			inst.update()
			if inst.state != 'stopped':
				try_again = True
		if try_again == True:
			time.sleep(2)
		else:
			break

def terminate_instances(region, instance_list):
	ec2 = boto.ec2.connect_to_region(region)
	instance_ids = list(map(lambda x: x.id, instance_list))
	terminated = ec2.terminate_instances(instance_ids=instance_ids)
	while True:
		try_again = False
		for inst in terminated:
			inst.update()
			if inst.state != 'terminated':
				try_again = True
		if try_again == True:
			time.sleep(2)
		else:
			break

def terminate_all_running_instances(region):
	instance_list = get_running_instances(region)
	terminate_instances(region, instance_list)

def stop_all_running_instances(region):
	instance_list = get_running_instances(region)
	stop_instances(region, instance_list)

def launch_client_controller(fabhost, keyfile, head_logaddr, tail_logaddr, start_clients, num_clients, window_sz, duration, total_clients,
			     low_throughput,
			     high_throughput,
			     spike_start,
			     spike_duration):
	launch_str = 'run_crdt_clients:' + head_logaddr + ',' + tail_logaddr + ',' + str(start_clients) + ',' + str(num_clients) + ',' + str(window_sz) + ',' + str(duration) + ',' + str(total_clients) + ',' + str(low_throughput) + ',' + str(high_throughput) + ',' + str(spike_start) + ',' + str(spike_duration)
	return subprocess.Popen(['fab', '-D', '-i', keyfile, '-H', fabhost, launch_str])

# Launch a CRDT applicatino process.
def launch_crdt(fabhost, keyfile, head_logaddr, tail_logaddr, duration, exp_range, server_id, sync_duration,
		num_clients, window_sz, num_rqs, sample_interval):
	launch_str = 'crdt_proc:' + head_logaddr + ',' + tail_logaddr + ',' + str(duration)
	launch_str += ',' + str(exp_range)
	launch_str += ',' + str(server_id)
	launch_str += ',' + str(sync_duration)
	launch_str += ',' + str(num_clients)
	launch_str += ',' + str(window_sz)
	launch_str += ',' + str(num_rqs)
	launch_str += ',' + str(sample_interval)
	return subprocess.Popen(['fab', '-D', '-i', keyfile, '-H', fabhost, launch_str])

def netstat_proc(ip, keyfile, filehandle):
	login = 'ubuntu@' + ip
	proc = subprocess.Popen(['fab', '-D', '-i', keyfile, '-H', login, 'check_network_statistics'], stdout=filehandle, stderr=filehandle)
	return proc

def check_statistics(server_ips, keyfile):
	os.system('mkdir -p stats')
	logfile_fmt = 's{0}_{1}'
	logfiles = []
	for i in range(0, len(server_ips)):
		filename = logfile_fmt.format(str(len(server_ips)), str(i))
		filehandle = open(os.path.join('stats', filename), 'a')
		logfiles.append(filehandle)

	procs = []
	for server, handle in zip(server_ips, logfiles):
		netstat_proc(server, keyfile, handle)

	for p in procs:
		p.wait()

# Launch fuzzy log.
def launch_fuzzylog_head(fabhost, keyfile, port, server_index, numservers, down_proc):
	launch_str = 'fuzzylog_proc_head:' + str(port) + ',' + str(server_index) + ',' + str(numservers) + ',' + down_proc
	proc = subprocess.Popen(['fab', '-D', '-i', keyfile, '-H', fabhost, launch_str])
	return proc

def launch_fuzzylog_tail(fabhost, keyfile, port, server_index, numservers, up_proc):
	launch_str = 'fuzzylog_proc_tail:' + str(port) + ',' + str(server_index) + ',' + str(numservers) + ',' + up_proc
	proc = subprocess.Popen(['fab', '-D', '-i', keyfile, '-H', fabhost, launch_str])
	return proc

def zip_logfiles(fabhost, keyfile):
	os.system('fab -D -i ' + keyfile + ' -H ' + fabhost + ' compress_log_files')

# Run CRDT experiment on specified instances. First instance hosts the log,
# every other instance hosts clients.
#
# Fabric only supports synchronous calls to hosts. Create a process per-remote call,
# either corresponding to a client or server. Manage clients and servers by joining/killing
# these processes.
def fuzzylog_exp(head_server_instances, tail_server_instances, client_instances, clients_per_instance, window_sz, duration, low_throughput, high_throughput,
		 spike_start, spike_duration):

	if len(head_server_instances) != len(tail_server_instances):
		assert False

	sync_duration = 300
	exp_range = 1000000
	num_rqs = 30000000
	sample_interval = 1

	head_logaddr = ''
	for i in range(0, len(head_server_instances)):
		head_logaddr += head_server_instances[i]['private']+':3333'
		if i < len(head_server_instances)-1:
			head_logaddr += '\\,'

	tail_logaddr = ''
	for i in range(0, len(tail_server_instances)):
		tail_logaddr += tail_server_instances[i]['private']+':3333'
		if i < len(tail_server_instances)-1:
			tail_logaddr += '\\,'

	down_args = list(map(lambda x: x['private'], tail_server_instances))
	up_args = list(map(lambda x: x['private']+':3333', head_server_instances))

	fabhost_prefix = 'ubuntu@'
	keyfile = '~/.ssh/jmfaleiro.pem'

	for i in range(0, len(head_server_instances)):
		os.system('fab -D -i ' + keyfile + ' -H ' + fabhost_prefix + head_server_instances[i]['public'] + ' kill_fuzzylog')

	for i in range(0, len(tail_server_instances)):
		os.system('fab -D -i ' + keyfile + ' -H ' + fabhost_prefix + tail_server_instances[i]['public'] + ' kill_fuzzylog')

	for i in range(0, len(client_instances)):
		os.system('fab -D -i ' + keyfile + ' -H ' + fabhost_prefix + client_instances[i]['public'] + ' clean_crdt')
		os.system('fab -D -i ' + keyfile + ' -H ' + fabhost_prefix + client_instances[i]['public'] + ' kill_crdts')
		os.system('fab -D -i ' + keyfile + ' -H ' + fabhost_prefix + client_instances[i]['public'] + ' enable_logging')

	log_procs = []
	for i in range(0, len(head_server_instances)):
		log_procs.append(launch_fuzzylog_head(fabhost_prefix+head_server_instances[i]['public'], keyfile, 3333, i, len(head_server_instances), down_args[i]))

#	for i in range(0, len(tail_server_instances)):
#		log_procs.append(launch_fuzzylog_tail(fabhost_prefix+tail_server_instances[i]['public'], keyfile, 3333, i, len(tail_server_instances), up_args[i]))

	time.sleep(10)
	client_procs = []
	for i in range(0, len(client_instances) - 1):
		start_c = i * clients_per_instance
		client_proc = launch_client_controller(fabhost_prefix+client_instances[i]['public'], keyfile, head_logaddr, tail_logaddr, start_c, clients_per_instance, window_sz, duration, clients_per_instance * (len(client_instances) - 1), low_throughput, high_throughput, spike_start, spike_duration)
		client_procs.append(client_proc)

	last_client = len(client_instances)-1
	getter_proc = launch_crdt(fabhost_prefix+client_instances[last_client]['public'], keyfile, head_logaddr, tail_logaddr, duration, 1000, 							len(client_procs)*clients_per_instance, 500, len(client_procs)*clients_per_instance,
				  window_sz, 0, 1)
	client_procs.append(getter_proc)

#	for i in range(0, duration):
#		time.sleep(1)
#		check_statistics(server_ips, keyfile)

	for c in client_procs:
		c.wait()


	for p in log_procs:
		p.kill()

	for i in range(0, len(client_instances)):
		zip_logfiles(fabhost_prefix+client_instances[i]['public'], keyfile)

# Start stopped instances.
def wakeup_instances(region):
	instance_ids = get_stopped_instances(region)
	return start_instances(region, instance_ids)

def test_proc(ipaddr, keyfile):
	login = 'ubuntu@' + ipaddr
	proc = subprocess.Popen(['fab', '-D', '-i', keyfile, '-H', login, 'ls_test'])
	return proc

def test_iteration(instance_list, keyfile):
	procs = []
	for inst in instance_list:
		procs.append(test_proc(inst['public'], keyfile))

	for p in procs:
		p.wait()

	for p in procs:
		if p.returncode != 0:
			return False
	return True

def start_single_client_instance():
	client_instances = launch_instances(1, CLIENT_INSTANCE_TYPE, REGION)
	client_instance_ips = list(map(lambda x: {'public' : x.public_dns_name, 'private' : x.private_ip_address}, client_instances))
	test_instances(client_instance_ips, KEYFILE)


def do_expt():
	# Start up instances for experiment.
	client_instances = launch_instances(5, CLIENT_INSTANCE_TYPE, REGION)
	server_head_instances = launch_instances(5, SERVER_INSTANCE_TYPE, REGION)
	# server_tail_instances = launch_instances(1, SERVER_INSTANCE_TYPE, REGION)
	server_tail_instances = server_head_instances

	client_instance_ips = list(map(lambda x: {'public' : x.public_dns_name, 'private' : x.private_ip_address}, client_instances))
	server_head_ips = list(map(lambda x: {'public' : x.public_dns_name, 'private' : x.private_ip_address}, server_head_instances))
	server_tail_ips = list(map(lambda x: {'public' : x.public_dns_name, 'private' : x.private_ip_address}, server_tail_instances))

	test_instances(client_instance_ips, KEYFILE)
	test_instances(server_head_ips, KEYFILE)
	test_instances(server_tail_ips, KEYFILE)

	os.system('mkdir results')
	log_fmt = '{0}_logs.tar.gz'


	low_throughput = 10000
	high_throughput = 60000
	spike_start = 45
	spike_duration  = 10
	num_clients = 4
	window_sz = 48
	duration = 100

	g = len(client_instance_ips)-1

	for i in range(4, 5):
		fuzzylog_exp(server_head_ips[0:i+1], server_tail_ips[0:i+1], client_instance_ips, num_clients, window_sz, duration,
			     low_throughput,
			     high_throughput,
			     spike_start,
			     spike_duration)

		result_dir = 'c' + str(num_clients) + '_s' + str(i+1) + '_w' + str(window_sz)
		os.system('mkdir ' + result_dir)
		indices = range(0, len(client_instance_ips))
		zipped = zip(indices, client_instance_ips)
		for i, c in zipped:
			os.system('scp -r -i ~/.ssh/jmfaleiro.pem -o StrictHostKeyChecking=no ubuntu@' + c['public'] + ':~/fuzzylog/FuzzyLog-apps/examples/or-set/*.txt ' + result_dir)
			logfile = log_fmt.format(str(i))
			os.system('scp -r -i ~/.ssh/jmfaleiro.pem -o StrictHostKeyChecking=no ubuntu@' + c['public'] + ':~/fuzzylog/FuzzyLog-apps/examples/or-set/logs.tar.gz ' + os.path.join(result_dir, logfile))


	instances = client_instances + server_head_instances + server_tail_instances
	terminate_instances(REGION, instances)
	clean.crdt_expt(len(client_instances), num_clients, window_sz, len(server_head_instances))

def main():
  instances = start_instances('us-east-1', get_stopped_instances('us-east-1'))
  ping_test(instances)
  assert(len(instances) == 3)
  setup_mysql_master(instances[0])
  setup_mysql_slave(instances[0], instances[1])
  run_mysql_expt(instances[0], instances[2], 1000000, 256)
  stop_instances('us-east-1', instances)

if __name__ == "__main__":
    main()
