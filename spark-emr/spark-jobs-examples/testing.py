#
import pyspark, sys, os

# Ex/internally
sc = pyspark.SparkContext.getOrCreate()
#sc = pyspark.SparkContext('local[*]')

# sc.stop()
print(os.getcwd()) # file object is not callable
txt = sc.textFile('file:////usr/share/doc/python34-3.4.3/LICENSE')
print(txt.count())

python_lines = txt.filter(lambda line: 'python' in line.lower())
print(python_lines.count())


#
# with open('file:////mnt/s3/results.txt', 'w') as file_obj:
#    file_obj.write("Number of lines: %s\n" % (txt.count()))
#    file_obj.write("Number of lines with python: %s\n" % (python_lines.count()))
#file_obj.close()
#

# Example that app needs to connect to cluster
#conf = pyspark.SparkConf()
#conf.setMaster('spark://head_node:56887')
#conf.set('spark.authenticate', True)
#conf.set('spark.authenticate.secret', 'secret-key')
#sc = SparkContext(conf=conf)
