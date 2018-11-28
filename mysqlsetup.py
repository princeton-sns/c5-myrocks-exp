#!/usr/bin/python

import os 
import sys
import subprocess
import time
import argparse

def parse_args():
  top_dir_fmt= "_build-5.6-{0}/"
  master_dir= "data/mysqld.1/"
  slave_dir= "data/mysqld.2/"

  parser= argparse.ArgumentParser()
  parser.add_argument('--release', action= 'store_true')
  parser.add_argument('--connect')
  parser.add_argument('--measure', action= 'store_true')
  args= parser.parse_args()

  arg_dict= {}
  arg_dict['release']= False
  arg_dict['debug']= False
  arg_dict['cmd']= 'setup'

  if args.connect:
    arg_dict['cmd']= 'connect'
    arg_dict['connect']= args.connect
  elif args.measure:
    arg_dict['cmd']= 'measure'

  if not arg_dict['cmd'] == 'setup': 
    arg_dict['release']= is_release()
    arg_dict['debug']= is_debug()
  elif arg_dict['cmd'] == 'setup':
    arg_dict['release']= args.release
    arg_dict['debug']= not args.release
    
  assert(arg_dict['release'] != arg_dict['debug'])

  if arg_dict['release']:
    top_dir= top_dir_fmt.format("Release")
  else:
    top_dir= top_dir_fmt.format("Debug")

  arg_dict['master_dir']= os.path.join(top_dir, master_dir)
  arg_dict['slave_dir']= os.path.join(top_dir, slave_dir)
  arg_dict['top_dir']= top_dir
  return arg_dict

def reset_exp_state():
  os.system("rm .release")
  os.system("rm .debug")

def set_release():
  os.system("touch .release")

def is_release():
  return os.path.isfile(".release")

def set_debug():
  os.system("touch .debug")

def is_debug():
  return os.path.isfile(".debug")

def set_exp_state(arg_dict):
  if arg_dict['release']:
    os.system('touch .release')
  elif arg_dict['debug']:
    os.system('touch .debug')
  else:
    assert(False)

def setup_msyql_test():
  arg_dict= parse_args()
  
  if arg_dict['cmd'] == 'setup':
    setup_expt(arg_dict)
  elif arg_dict['cmd'] == 'connect':
    connect(arg_dict)
  elif arg_dict['cmd'] == 'measure':
    measure(arg_dict)
  else:
    assert(False)

def connect(arg_dict):
  os.chdir(arg_dict['top_dir'])

  if arg_dict['connect'] == 'master':
    os.system('bin/mysql --defaults-file=master.cnf')
  elif arg_dict['connect'] == 'slave':
    os.system('bin/mysql --defaults-file=slave.cnf')
  else:
    assert(False)

def com_commit_count(lines):
  commit_count= ''
  for l in lines:
    if l.startswith('| Com_commit'):
      commit_count= l
      break
  return int(filter(lambda x: x != '|', commit_count.split())[1])

def scheduled_count(lines):
  scheduled_count= ''
  for l in lines:
    if l.startswith('| Slave_scheduled_trxs'): 
      scheduled_count= l
      break
  return int(filter(lambda x: x!= '|', scheduled_count.split())[1])

def waiting_count(lines):
  waiting_count= ''
  for l in lines:
    if l.startswith('| Slave_waiting_workers'):
      waiting_count= l
      break
  return int (filter(lambda x: x != '|', waiting_count.split())[1])

def measure(arg_dict):
  os.chdir(arg_dict['top_dir'])
  master_cnf= 'master.cnf' 
  slave_cnf= 'slave.cnf' 

  admin_cmd_fmt= 'mysqladmin --defaults-file={0} extended-status'
  master_cmd= admin_cmd_fmt.format(master_cnf).split()
  slave_cmd= admin_cmd_fmt.format(slave_cnf).split()

  master_total= 0
  slave_total= 0
  scheduled_total= 0

  prev_master= -1
  prev_slave= -1
  prev_scheduled= -1
  while True:
    master_output= com_commit_count(subprocess.check_output(master_cmd).splitlines())

    slave_lines= subprocess.check_output(slave_cmd).splitlines()
    slave_output= com_commit_count(slave_lines)
    slave_scheduled= scheduled_count(slave_lines)
    slave_waiting= waiting_count(slave_lines)

    if prev_master >= 0: 
      cur_master= master_output - prev_master
      cur_slave= slave_output - prev_slave
      cur_scheduled= slave_scheduled - prev_scheduled

      master_total+= cur_master
      slave_total+= cur_slave
      scheduled_total+= cur_scheduled

      print 'Master: ' + str(cur_master) + ' ' + str(master_total) + ' ' + str(master_output)
      print 'Slave: ' + str(cur_slave) + ' ' + str(slave_total) + ' ' + str(slave_output) + ' ' + str(cur_scheduled) + ' ' + str(slave_waiting)
      print '================================================='

    prev_master= master_output
    prev_slave= slave_output
    prev_scheduled= slave_scheduled

    time.sleep(1) 

def setup_configs(arg_dict):
  cp_cmd_fmt= "cp {0} {1}"
  master_cnf, slave_cnf, setup_slave= "~/configs/master.cnf", "~/configs/slave.cnf", "~/configs/setup_slave"
  os.system(cp_cmd_fmt.format(master_cnf, arg_dict['top_dir']))
  os.system(cp_cmd_fmt.format(slave_cnf, arg_dict['top_dir']))
  os.system(cp_cmd_fmt.format(setup_slave, arg_dict['top_dir']))

def setup_expt(arg_dict):
  kill_mysqld_procs(arg_dict['master_dir'], arg_dict['slave_dir'])
  reset_exp_state()
  setup_configs(arg_dict)
  log_file, log_pos= setup_master(arg_dict)
  setup_slave(arg_dict, log_file, log_pos)
  set_exp_state(arg_dict)

def setup_master(arg_dict):
  parent_dir= os.getcwd()
  os.chdir(arg_dict['top_dir'])
  os.system("scripts/mysql_install_db --defaults-file=master.cnf --force")

  subprocess.Popen(['numactl', '--cpunodebind=0,1,2,3', '--membind=0,1,2,3', 'bin/mysqld', '--defaults-file=master.cnf'], 
                   cwd= '.',
                   stdout= subprocess.PIPE,
                   stderr= subprocess.STDOUT)

  while True:
    if os.path.exists("data/mysqld.1/mysqld.1.sock"):
      break

  time.sleep(5)

  os.system("bin/mysql --defaults-file=master.cnf < master_log_pos > log_pos_out")
  os.system("bin/mysqldump --defaults-file=master.cnf --all-databases > master.dump")
  os.system("bin/mysql --defaults-file=master.cnf -e \"unlock tables\"")
  log_file, log_pos= get_log_pos()
  os.chdir(parent_dir)
  return log_file, log_pos

def setup_slave(arg_dict, log_file, log_pos):
  master_change_fmt= "change master to master_host=\'localhost\', master_port=3306, master_user=\'root\', master_log_file=\'{0}\', master_log_pos={1};" 

  parent_dir= os.getcwd()
  os.chdir(arg_dict['top_dir'])
  os.system("scripts/mysql_install_db --defaults-file=slave.cnf --force")
  subprocess.Popen(['numactl', '--cpunodebind=4,5,6,7', '--membind=4,5,6,7', 'bin/mysqld', '--defaults-file=slave.cnf', '--skip-slave-start'], 
                   cwd= '.',
                   stdout= subprocess.PIPE,
                   stderr= subprocess.STDOUT)
  while True:
    if os.path.exists("data/mysqld.2/mysqld.2.sock"):
      break

  time.sleep(1)

  os.system("bin/mysql --defaults-file=slave.cnf < master.dump")
  master_change_str= master_change_fmt.format(log_file, log_pos)
  os.system("bin/mysql --defaults-file=slave.cnf -e \" "+ master_change_str + "\";")
  os.system("bin/mysql --defaults-file=slave.cnf -e \"start slave;\" ")
  os.system("bin/mysql --defaults-file=slave.cnf < setup_slave")

  os.chdir(parent_dir)
 
def setup_mysql():
  master_dir_fmt= "_build-5.6-{0}/data/mysqld.1/"
  slave_dir_fmt= "_build-5.6-{0}/data/mysqld.2/"

  parser= argparse.ArgumentParser()
  parser.add_argument('--release', action= 'store_true')
  args= parser.parse_args()

  if args.release:
    master_dir= master_dir_fmt.format("Release")
    slave_dir= slave_dir_fmt.format("Release")
  else:
    master_dir= master_dir_fmt.format("Debug")
    slave_dir= slave_dir_fmt.format("Debug")

  kill_mysqld_procs()
  reset_exp_state()

  os.chdir("_build-5.6-Release")
  os.system("cp ~/configs/* .")
  os.system("rm -rf data/*")

  # Setup the master 
  os.system("scripts/mysql_install_db --defaults-file=master.cnf --force")
  subprocess.Popen(['bin/mysqld', '--defaults-file=master.cnf'], 
                   cwd= '.',
                   stdout= subprocess.PIPE,
                   stderr= subprocess.STDOUT)

  while True:
    if os.path.exists("data/mysqld.1/mysqld.1.sock"):
      break

  os.system("bin/mysql --defaults-file=master.cnf < master_log_pos > log_pos_out")
  os.system("bin/mysqldump --defaults-file=master.cnf --all-databases > master.dump")
  os.system("bin/mysql --defaults-file=master.cnf -e \"unlock tables\"")

  log_file, log_pos= get_log_pos()

  # Setup the slave 
  os.system("scripts/mysql_install_db --defaults-file=slave.cnf --force")

  subprocess.Popen(['bin/mysqld', '--defaults-file=slave.cnf', '--skip-slave-start'], 
                   cwd= '.',
                   stdout= subprocess.PIPE,
                   stderr= subprocess.STDOUT)
  while True:
    if os.path.exists("data/mysqld.2/mysqld.2.sock"):
      break

  os.system("bin/mysql --defaults-file=slave.cnf < master.dump")
  master_change_str= master_change_fmt.format(log_file, log_pos)
  print master_change_str
  os.system("bin/mysql --defaults-file=slave.cnf -e \" "+ master_change_str + "\";")
  os.system("bin/mysql --defaults-file=slave.cnf -e \"start slave;\" ")


# Gets pids corresponding to master and slave mysqld instances.
def get_pids(master_dir, slave_dir):
  master_pid_file= os.path.join(master_dir, "mysqld.1.pid")
  slave_pid_file= os.path.join(slave_dir, "mysqld.2.pid")

  pid_list= []

  if os.path.exists(master_pid_file):
    with open(master_pid_file) as f: 
      lines= f.readlines()
    master_pid= int(lines[0].split()[0])
    pid_list.append(master_pid)
  
  if os.path.exists(slave_pid_file):
    with open(slave_pid_file) as f:
      lines= f.readlines()
    slave_pid= int(lines[0].split()[0])
    pid_list.append(slave_pid)

  return pid_list 

# Kills master and slave mysqld processes.
def kill_mysqld_procs(master_dir, slave_dir):
  pid_list= get_pids(master_dir, slave_dir)
  for pid in pid_list:
    while check_pid(pid):
      os.system("kill -9 " + str(pid))
  os.system("rm -rf " + master_dir)
  os.system("rm -rf " + slave_dir)

# Determine whether or not the given process exists.
def check_pid(pid):
  try:
    os.kill(pid, 0)
  except OSError:
    return False
  else:
    return True

# Parse out log coordinates from the master. 
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

if __name__ == "__main__":
  setup_msyql_test()
