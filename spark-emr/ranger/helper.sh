#######################################
#######################################
# 
# EMR-Ranger Integration:
#
# Updates for CF-Stack:
#  i). Contacting simple AD (L-46, others later).
#  ii). Create usesr if not exists (L-52).
#  iii). Update mysql-connector jar reference (L-37 & L-38)
#
# References:
# 1). CF Stack: https://aws.amazon.com/blogs/big-data/implementing-authorization-and-auditing-using-apache-ranger-on-amazon-emr/
# 2). Ranger Install: https://cwiki.apache.org/confluence/display/RANGER/Apache+Ranger+0.5.0+Installation
#
#######################################
#######################################


'''

- Simple AD seemed fine
- Ranger server not, and 6080 connections refused as server is not running :(

domain name = corp.emr.local
domain pwd = *********
domain short name = EmrSimpleAD

bindUser pwd = *********
myUser pwd = *********


Simple AD IP: 192.168.3.54
Ranger IP: 192.168.2.174


Not online
Ranger admin IU: http://<ip address of the ranger server>:6080/login.jsp

'''


# Command ran
bash /home/ec2-user/install-ranger-admin-server.sh \
    myDirectoryIPAddress \
    myDirectoryBaseDN \
    myDirectoryBindUser \
    myDirectoryBindPassword \
    rangerVersion \
    s3artifactsRepoHttp \
    myDirectoryAdminPassword \
    myDirectoryBindPassword\
    myDirectoryDefaultUserPassword > create-ranger-server-output.log

'''

- Log ends with

You can start the MySQL daemon with:
cd /usr ; /usr/libexec/mysql55/mysqld_safe &

You can test the MySQL daemon with mysql-test-run.pl
cd /usr/mysql-test ; perl mysql-test-run.pl

Please report any problems at http://bugs.mysql.com/

[  OK  ]
Starting mysqld:  [  OK  ]

'''


# User data script
`
#!/bin/bash
cd /home/ec2-user/
wget https://s3.amazonaws.com/aws-bigdata-blog/artifacts/aws-blog-emr-ranger/scripts/install-ranger-admin-server.sh
yum update aws-cfn-bootstrap

# Install the files and packages from the metadata
/opt/aws/bin/cfn-init \
    --stack RangerServer-2\
    --resource myEC2\
    --configsets InstallRangerServer \
    --region eu-west-1

`

# Check logs: should really be &>>
less /var/log/cfn-init.log
bash /home/ec2-user/install-ranger-admin-server.sh \
    192.168.2.215 \
    dc=corp,dc=emr,dc=local binduser@corp.emr.local \
    '*********' \
    0.7 \
    https://s3.amazonaws.com/aws-bigdata-blog/artifacts/aws-blog-emr-ranger \
    '*********' \
    '*********' \
    '*********' > create-ranger-server-output-v6.log 

'''

- Failed with no clear error, guess is because of ! in passwords :c

2022-12-06 14:22:57,356 [ERROR] Error encountered during build of RangerServer: Command installrangerserver failed
Traceback (most recent call last):
  File "/usr/lib/python2.7/dist-packages/cfnbootstrap/construction.py", line 542, in run_config
    CloudFormationCarpenter(config, self._auth_config).build(worklog)
  File "/usr/lib/python2.7/dist-packages/cfnbootstrap/construction.py", line 260, in build
    changes['commands'] = CommandTool().apply(self._config.commands)
  File "/usr/lib/python2.7/dist-packages/cfnbootstrap/command_tool.py", line 117, in apply
    raise ToolError(u"Command %s failed" % name)
ToolError: Command installrangerserver failed


- ldapsearch for AD hangs
./create-users-using-ldap.sh 192.168.3.54 '*********' '*********' '*********'
ldapsearch -x -D Administrator@corp.emr.local -w '*********' -H ldap://192.168.3.54 -b CN=Users,DC=corp,DC=emr,DC=local
ldap_sasl_bind(SIMPLE): Cant contact LDAP server (-1)


- Can download ranger-admin & usersync, mysql connector fails

wget https://s3.amazonaws.com/aws-bigdata-blog/artifacts/aws-blog-emr-ranger/ranger/ranger-0.7.1/ranger-0.7.1-admin.tar.gz
wget https://s3.amazonaws.com/aws-bigdata-blog/artifacts/aws-blog-emr-ranger/ranger/ranger-0.7.1/ranger-0.7.1-usersync.tar.gz
wget https://s3.amazonaws.com/aws-bigdata-blog/artifacts/aws-blog-emr-ranger/ranger/ranger-0.7.1/mysql-connector-java-5.1.39.jar


'''

# Package renamed? Also updated
aws s3 ls s3://aws-bigdata-blog/artifacts/aws-blog-emr-ranger/ranger/ranger-0.7.1/

'''

2020-11-24 06:12:28     989497 mysql-connector-java-5.1.39-bin.jar
2020-11-24 06:12:29  158284641 ranger-0.7.1-admin.tar.gz
2020-11-24 06:12:29  159124956 ranger-0.7.1-admin.zip
2020-11-24 06:12:29   17305797 ranger-0.7.1-hbase-plugin.tar.gz
2020-11-24 06:12:29   17331689 ranger-0.7.1-hbase-plugin.zip
2020-11-24 06:12:30   17848319 ranger-0.7.1-hdfs-plugin.tar.gz
2020-11-24 06:12:30   17876806 ranger-0.7.1-hdfs-plugin.zip
2020-11-24 06:12:31   17272853 ranger-0.7.1-hive-plugin.tar.gz
2020-11-24 06:12:31   17302479 ranger-0.7.1-hive-plugin.zip
2020-11-24 06:12:32   13807205 ranger-0.7.1-usersync.tar.gz
2020-11-24 06:12:32   13826002 ranger-0.7.1-usersync.zip
2020-11-24 06:12:33     235520 solr_for_audit_setup.tar.gz

'''


# Post updates
curl -I http://192.168.2.174:6080/login.jsp

'''

- Tail output

+ sudo /usr/bin/ranger-admin stop
+ sudo /usr/bin/ranger-admin start
+ sudo /opt/solr/ranger_audit_server/scripts/start_solr.sh

- curl test

HTTP/1.1 200 OK
Server: Apache-Coyote/1.1
Set-Cookie: RANGERADMINSESSIONID=853418856F1F81196AF451067B9C39CD; Path=/; HttpOnly
X-Frame-Options: DENY
Content-Type: text/html;charset=ISO-8859-1
Content-Length: 3325
Date: Tue, 06 Dec 2022 16:17:50 GMT


- Message before patch

curl: (7) Failed to connect to 192.168.2.174 port 6080: Connection refused

'''


# Re-test 
ssh -v -i ~/.ssh/emrKey.pem -ND 8157 ec2-user@34.242.222.207
