#!/usr/bin/python

import math 

def times(input_file, output_file):
  prev= 0
  vals= []
  index= 0
  with open(input_file) as f:
    for l in f.readlines():
      cur= int(l.split()[1])
      if index != 0:
        vals.append([index, cur - prev])
      prev= cur
      index+= 1

  with open(output_file, 'w') as f:
    for i, v in vals:
      f.write(str(i) + ' ' + str(v) + '\n')

  return vals 

def times_diffs(master_file, slave_file, output_file):
  lag= []
  prev= 0
  mf= open(master_file)
  sf= open(slave_file)
  mlines= mf.readlines()
  slines= sf.readlines()

  start_diff= 0
  with open(output_file, 'w') as f:
    for i in range(0, len(mlines)):
      temp= (int(mlines[i].split()[1]) - int(slines[i].split()[1]))
      if i == 0:
        start_diff= temp
      f.write(str(i) + ' ' + str(temp - start_diff) + '\n')

  mf.close()
  sf.close()

def times_total(input_file, output_file):
  prev= 0
  vals= []
  index= 0
  with open(input_file) as f:
    for l in f.readlines():
      cur= int(l)
      vals.append([index, cur])
      prev+= cur
      index+= 1

  with open(output_file, 'w') as f:
    for i, v in vals:
      f.write(str(i) + ' ' + str(v) + '\n')

  return vals 


def diffs_old(input_file):
  prev = 0
  vals = []
  index= 0
  start= True
  with open(input_file) as f:
    for l in f.readlines():
      cur = int(l)
       
      if start == True:
        if index > 0 and cur-prev != 0:
          start= False
      elif start == False and cur-prev == 0:
        break
      else:
        vals.append(cur-prev)

      index+= 1
      prev = cur

  mean= 1.0*sum(vals)/len(vals)
  std_dev= 0
  for v in vals:
    std_dev+= (v - mean)*(v - mean)
  std_dev = 1.0*std_dev / len(vals)
  return [mean, mean-math.sqrt(std_dev), mean+math.sqrt(std_dev)]

def diffs(input_file):
  prev = 0
  vals = []
  index= 0
  start= True
  with open(input_file) as f:
    for l in f.readlines():
      cur = int(l.split()[1])
       
      if start == True:
        if index > 0 and cur-prev != 0:
          start= False
      elif start == False and cur-prev == 0:
        break
      else:
        vals.append(cur-prev)

      index+= 1
      prev = cur

# vals= vals[5:]
  mean= 1.0*sum(vals)/len(vals)
  std_dev= 0
  for v in vals:
    std_dev+= (v - mean)*(v - mean)
  std_dev = 1.0*std_dev / len(vals)
  return [mean, mean-math.sqrt(std_dev), mean+math.sqrt(std_dev)]

def read_err_file(input_file):
  pairs = []
  with open(input_file) as f:
    for l in f.readlines():
      parts = l.split()
      count = int(parts[1][:-1])
      time = float(parts[5][:-1])
      pairs.append([count, time])

  results = open(input_file + '.out', 'w')
  for p in pairs:
    results.write(str(p[0]) + ' ' + str(p[1]) + '\n')
  results.close()
      

def producer_diffs(prod_file):
  vals= []
  times= 0
  prev= 0
  with open(prod_file) as f:
    for l in f.readlines():
      count= float(l.split()[1][:-1])
      time= float(l.split()[5][:-1])
      times+= time
      vals.append(1*float(count - prev) / time)
      prev= count
  temp= vals
  mean= 1.0*sum(temp)/len(temp)
  std_dev= 0
  for v in vals:
    std_dev+= (v - mean)*(v - mean)
  std_dev = 1.0*std_dev / len(temp)
  
  print times
  return [mean, mean-math.sqrt(std_dev), mean+math.sqrt(std_dev)]

def main():
  thread_counts = [1,2, 4, 8, 16, 32, 64, 128, 256]
  master_fmt = "jemalloc/master.{0}"

  master_results = open('jemalloc/master.out', 'w')
  for t in thread_counts:
    exp_result = diffs(master_fmt.format(str(t)))
    master_results.write(str(t) + ' ' + str(exp_result[0]) + ' ' + str(exp_result[1]) + ' ' + str(exp_result[2]) + '\n')
  master_results.close() 
 
  slave_fmt = "jemalloc/slave.{0}"
  slave_results = open('jemalloc/slave.out', 'w')
  for t in thread_counts:
    exp_result = diffs(slave_fmt.format(str(t)))
    slave_results.write(str(t) + ' ' + str(exp_result[0]) + ' ' + str(exp_result[1]) + ' ' + str(exp_result[2]) + '\n')
  slave_results.close()

 
  producer_fmt = "jemalloc/slave.err.{0}"
  producer_results= open('jemalloc/producer.out', 'w')
  for t in thread_counts:
    exp_result= producer_diffs(producer_fmt.format(str(t)))
    producer_results.write(str(t) + ' ' + str(exp_result[0]) + ' ' + str(exp_result[1]) + ' ' + str(exp_result[2])+ '\n')
  producer_results.close()


if __name__ == "__main__":
    main()
