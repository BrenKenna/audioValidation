##############################################
##############################################
# 
# Livy Private Hosted Zone
# 
# Links:
# 
# 1). https://dassum.medium.com/apache-livy-a-rest-interface-for-apache-spark-f435540e26a9
# 2). https://zpz.github.io/blog/talking-to-spark-from-python-via-livy/
# 3). http://livy.incubator.apache.org/examples/
# 4). https://itnext.io/building-real-time-interactions-with-apache-spark-through-apache-livy-53169d87d012
# 
##############################################
##############################################



sudo pip install requests

```{ python3 }

# Import modules
import json, pprint, requests, textwrap
host = 'http://active.emr-clusters.ie:8998'


# Start session
data = {
    'kind': 'spark'
}
headers = {
    'Content-Type': 'application/json'
}
req = requests.post(
    host + '/sessions',
    data=json.dumps(data),
    headers=headers
)
pprint.pprint(req.json())

"""

{
    'id': 0,
    'name': None,
    'appId': None,
    'owner': None,
    'proxyUser': None,
    'state': 'starting',
    'kind': 'spark',
    'appInfo': {
        'driverLogUrl': None,
        'sparkUiUrl': None
    },
    'log': [
        'stdout: ', 
        '\nstderr: ', 
        '\nYARN Diagnostics: '
    ]
}

"""

# Poll session
session_url = host + req.headers['location']
req = requests.get(session_url, headers = headers)
pprint.pprint(req.json())

"""
{
    'id': 0,
    'name': None,
    'appId': 'application_1672324281552_0001',
    'owner': None,
    'proxyUser': None,
    'state': 'idle',
    'kind': 'spark',
    'appInfo': {
        'driverLogUrl': 'http://ip-192-168-2-216.eu-west-1.compute.internal:8042/node/containerlogs/container_1672324281552_0001_01_000001/livy',
        'sparkUiUrl': 'http://ip-192-168-2-201.eu-west-1.compute.internal:20888/proxy/application_1672324281552_0001/'},
        'log': [
            '22/12/29 14:55:35 INFO BlockManager: external shuffle service port = '
         '7337',
         '22/12/29 14:55:35 INFO BlockManager: Initialized BlockManager: '
         'BlockManagerId(driver, ip-192-168-2-201.eu-west-1.compute.internal, '
         '44265, None)',
         '22/12/29 14:55:36 INFO YarnSchedulerBackend$YarnSchedulerEndpoint: '
         'ApplicationMaster registered as '
         'NettyRpcEndpointRef(spark-client://YarnAM)',
         '22/12/29 14:55:36 INFO JettyUtils: Adding filter '
         'org.apache.hadoop.yarn.server.webproxy.amfilter.AmIpFilter to '
         '/metrics/json.',
         '22/12/29 14:55:36 INFO EventLoggingListener: Logging events to '
         'hdfs:/var/log/spark/apps/application_1672324281552_0002',
         '22/12/29 14:55:36 INFO Utils: Using initial executors = 50, max of '
         'spark.dynamicAllocation.initialExecutors, '
         'spark.dynamicAllocation.minExecutors and spark.executor.instances',
         '22/12/29 14:55:36 INFO YarnClientSchedulerBackend: SchedulerBackend '
         'is ready for scheduling beginning after reached '
         'minRegisteredResourcesRatio: 0.0',
         '22/12/29 14:55:36 INFO SparkEntries: Spark context finished '
         'initialization in 18965ms',
         '22/12/29 14:55:36 INFO SparkEntries: Created Spark session (with '
         'Hive support).',
         '\nYARN Diagnostics: '
        ]
    }
}
"""


# Submit scala job
statements_url = session_url + '/statements'
data = {'code': '1 + 1'}
r = requests.post(statements_url, data = json.dumps(data), headers=headers)
pprint.pprint(r.json())

"""

{
    'id': 0,
    'code': '1 + 1',
    'state': 'waiting',
    'output': None,
    'progress': 0.0,
    'started': 0,
    'completed': 0
}

"""


# Poll related app
statement_url = host + r.headers['location']
r = requests.get(statement_url, headers=headers)
pprint.pprint(r.json())

"""

{
    'code': '1 + 1',
    'completed': 1672325196686,
    'id': 0,
    'output': {
            'data': {
                'text/plain': 'res0: Int = 2\n'
            },
            'execution_count': 0,
            'status': 'ok'},
    'progress': 1.0,
    'started': 1672325196423,
    'state': 'available'
}

"""


########################
########################
# 
# PySpark
# 
########################
########################


# Import modules
import json, pprint, requests, textwrap
host = 'http://active.emr-clusters.ie:8998'


# Start pyspark session
data = {
    'kind': 'pyspark'
}
headers = {
    'Content-Type': 'application/json'
}
req = requests.post(
    host + '/sessions',
    data = json.dumps(data),
    headers = headers
)
pprint.pprint(req.json())

'''

{
    'appId': None,
    'appInfo': {'driverLogUrl': None, 'sparkUiUrl': None},
    'id': 3,
    'kind': 'pyspark',
    'log': ['stdout: ', '\nstderr: ', '\nYARN Diagnostics: '],
    'name': None,
    'owner': None,
    'proxyUser': None,
    'state': 'starting'
}

'''

# Poll session before proceeding
session_url = host + req.headers['location']
req = requests.get(session_url, headers = headers)
pprint.pprint(req.json())


# Test importing audioValidator shtuff
data = {
    'code': textwrap.dedent("""
        import os
        os.environ["NUMBA_CACHE_DIR"] = "/tmp/NUMBA_CACHE_DIR/"
        from audioValidator.generator import generator
        msg = dir(generator)
        print(msg)
    """)
}


# Post & print response
statements_url = str( session_url + '/statements' )
req = requests.post(
    statements_url,
    data = json.dumps(data),
    headers = headers
)
pprint.pprint(req.json())

'''

{
    'code': '\n'
         'import os\n'
         'os.environ["NUMBA_CACHE_DIR"] = "/tmp/NUMBA_CACHE_DIR/"\n'
         'from audioValidator.generator import generator\n'
         'msg = dir(generator)\n'
         'print(msg)\n',
    'completed': 0,
    'id': 2,
    'output': None,
    'progress': 0.0,
    'started': 0,
    'state': 'waiting'
}
'''

# Get job & kill session
statement_url = host + req.headers['location']
req = requests.get(statement_url, headers = headers)
pprint.pprint(req.json())
requests.delete(
    session_url,
    headers = headers
)

'''

- Got expected moudle import error
    => But PySpark session still created
    => Python code still ran
    => audioValidator just needs to be installed 'better'
        => For "bandCloud" this allows:
            i). Angular Frontend to post an audio object.
           ii). Spring Backend to request its processing (just a request).
                => A user can have a session that their track posting appends work to.
                => Goal is close as many of these:
                    => Scan last job submission
                    => Model = abstract job, concrete request & response.
                    => Spring app talks to JobManager, as part of posting tracks.
                        => ToDo is a queue
                        => Polls do not delete until object exists on S3.
                        => Active queue has queryable info 
                        => Done queue, triggers last submission time for user above threshold session is killed

                => Fetch results stored in DynamoDB
                        => Valid audio left alone.
                        => Invalid audio/"malware" removed, and end-user emailed "naughty naughty"
                => Needs to manage to rate at which they come in per user (reduce spamming)
                        => Prevent misuse/abuse where someone can submit millions of jobs for one track, or nonsense
{
    'code': '\nimport os\nos.environ["NUMBA_CACHE_DIR"] = "/tmp/NUMBA_CACHE_DIR/"\nfrom audioValidator.generator import generator\nmsg = dir(generator)\nprint(msg)\n',
    'completed': 1672329321678,
    'id': 0,
    'output': {u'ename': u'ModuleNotFoundError',
             u'evalue': u"No module named 'audioValidator'",
             u'execution_count': 0,
             u'status': u'error',
             u'traceback': [u'Traceback (most recent call last):\n',
                            u"ModuleNotFoundError: No module named 'audioValidator'\n"]},
    'progress': 1.0,
    'started': 1672329321643,
    'state': u'available'
}

export PYTHONPATH="$PWD/pyspark.zip:$PWD/py4j-0.10.9.3-src.zip"
export PYSPARK_PYTHON="/usr/bin/python3"
aws emr add-steps \
    --region "eu-west-1" \
    --cluster-id "j-3P7LMVG1EUGTQ" \
    --steps file:///home/ec2-user/example-step.json

aws emr list-steps \
    --region "eu-west-1" \
    --cluster-id "j-3P7LMVG1EUGTQ" \
    --step-ids "s-32LNFNY2W77S5"

--> Worked fine, 5mins for 11 tracks => <30s per track
   => Dataset is 2,646,000 compared to 86M x ~4k rows
'''

```