#### 安装slurm

1 安装epel 

EPEL (Extra Packages for Enterprise [Linux](https://so.csdn.net/so/search?q=Linux))是基于Fedora的一个项目，为“红帽系”的操作系统提供额外的软件包，适用于RHEL、CentOS和Scientific Linux.

epel的安装方法见

https://docs.fedoraproject.org/en-US/epel

对于Centos 9 安装代码如下

```
dnf config-manager --set-enabled crb
dnf install \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm
```



 ```
 dnf install pssh
 ```



##### 安装munge

munge是认证服务，用于生成和验证证书。应用于大规模的HPC集群中。它允许进程在【具有公用的用户和组的】主机组中，对另外一个【本地或者远程的】进程的UID和GID进行身份验证。这些主机构成由共享密钥定义的安全领域。在此领域中的客户端能够在不使用root权限，不保留端口，或其他特定平台下进行创建凭据和验证.

```
dnf install munge munge-devel
pssh -h ~/pssh.hosts "dnf install -y munge munge-devel"
```

munge  安装完成后会自动创建munge用户和组

###### 产生munge.key 文件

```
create-munge-key
新版64
pssh -h ~/pssh.hosts "rm -f /etc/munge/munge.key"
mungekey -c -f -b 512
cat /etc/munge/munge.key   # check if munge.key file is generated here

for i in node01 node02 node03 node04 node05 node06
do
scp /etc/munge/munge.key ${i}:/etc/munge/munge.key
done
pssh -h ~/pssh.hosts "chown munge:munge /etc/munge/munge.key"
pssh -H "node02 node06" "chown munge:munge /etc/munge/munge.key"
```

###### 本机启动munge

```
chown munge:munge /etc/munge/munge.key
systemctl enable munge
systemctl start munge
```

远程启动munge

```
pssh -h ~/pssh.hosts "systemctl enable munge"
pssh -h ~/pssh.hosts "systemctl restart munge"
```

```
Unable to access /var/run/munge/munge.socket.2: no such file or directory (远程未启动)
```

```


```







测试munge

```
munge -s xyz
munge -s xyz | unmunge
munge -s xyz | ssh node02 unmunge
```



时间同步

sudo dnf install chrony

timedatectl

timedatectl set-timezone Asia/Shanghai

sudo timedatectl set-ntp yes

#### 安装slurm

```
pssh -h  ~/pssh.hosts dnf install  hwloc hwloc-devel dbus-devel numactl numactl-devel rrdtool rrdtool-devel gtk2 gtk2-devel freeipmi freeipmi-devel lua lua-devel mysql mysql-devel readline readline-devel hdf5 hdf5-devel man2html lz4 http-parser-devel json-parser-devel libyaml-devel lz4 lz4-devel pmix pmix-devel
```

- hwloc 帮助slurm掌握硬件资源的信息, 有了这个才slurm才会使用cgroup去管理硬件资源

- numactl 帮助slurm利用非一致性内存访问(NUMA)构架的特性, 使得/task/affinity 插件可以支持numa

- rddtool (round-robin database tool) 处理温度,cpu负载等信息随时间变化的数据

- freeimpi 统计能耗

- lua 提供lua API 

- mysql 数据库用来记账

- readline 支持在scontrol和sacctmgr的交互模式中使用交互式命令行编辑模式

- gtk2 图形界面开发工具, 产生sview命令

- PAM 可以控制用户访问计算节点的权限

- pmix 

goto

https://dev.mysql.com/downloads/repo/yum/ 

 sudo dnf install mysql80-community-release-fc37-1.noarch.rpm

```
sudo dnf install mysql-community-server
```

```
sudo systemctl start mysqld
sudo systemctl enable mysqld
sudo grep 'temporary password' /var/log/mysqld.log
```

```
sudo mysql_secure_installation
sudo mysql -u root -p
```

配置mysql

sudo vim /etc/my.cnf

innodb_buffer_pool_size=4096M
innodb_log_file_size=64M
innodb_lock_wait_timeout=900



下载地址

https://www.schedmd.com/downloads.php

```
wget https://download.schedmd.com/slurm/slurm-21.08.5.tar.bz2
tar -jxvf slurm-21.08.5.tar.bz2
cd slurm-21.08.5
./configure
grep unable config.log
./configure --with
有编译不过去的， 可以查该插件是否必要，如非必要 可以去掉
```



```
tar 

```

检查config.log

```
conda deactivate

make -j
sudo make install
su
pssh -h ~/pssh.hosts "cd /home/zc/software/slurm-22.05.3; make install"
cp ./etc/slurmctld.service /etc/systemd/system
cp ./etc/slurmd.service /etc/systemd/system
sudo cp ./etc/slurmdbd.service /etc/systemd/system
sudo
cp ./etc/cgroup.conf.example /usr/local/etc/cgroup.conf
cp ./etc/gres.conf.example /usr/local/etc/gres.conf
cp ./etc/slurm.conf.example /usr/local/etc/slurm.conf
```

编辑cgroup.conf gres.conf slurm.conf文件

https://slurm.schedmd.com/gres.conf.html

https://slurm.schedmd.com/cgroup.conf.html

https://slurm.schedmd.com/slurm.conf.html



slurm.conf 

ClusterName=zc
SlurmctldHost=node01

GresTypes=gpu

MpiDefault=none

ProctrackType=proctrack/cgroup

ReturnToService=2

SlurmUser=root

TaskPlugin=task/affinity,task/cgroup

NodeName=node0[1-3] CPUs=128 Gres=gpu:gtx_2080:1 Sockets=2 CoresPerSocket=64 ThreadsPerCore=1 State=UNKNOWN
NodeName=node04 CPUs=64 Gres=gpu:gtx_2080:1 Sockets=2 CoresPerSocket=32 ThreadsPerCore=1 State=UNKNOWN

注意Type的名称不能乱起, 需要是自动检测到的设备的子字符串

JobCompPass=Zc@Zst2327
JobCompType=jobcomp/mysql
JobCompUser=root

AccountingStorageType=accounting_storage/slurmdbd



slurm.conf

SlurmctldHost=node01  #可以多行

GresTypes=gpu
TaskPlugin=task/affinity,task/cgroup
StateSaveLocation=/var/spool/slurmctld #多主机设定到共享位置
MpiDefault=pmix
NodeName
PartitionName



gres.conf

AutoDetect=nvml
Name=gpu Type=rtx_2080 File=/dev/nvidia0

cgroup.conf

CgroupAutomount=yes

ConstrainCores=yes
ConstrainRAMSpace=no



slurmdbd.conf

DbdHost=node01
SlurmUser=root
LogFile=/var/log/slurm_db.log
StorageLoc=slurm_acct_db
StorageType=accounting_storage/mysql
StorageUser=root
StoragePass=Zc@Zst2327

测试启动

slurmd -D

slurmctld -D

slurmdbd -D

作为daemon 启动

systemctl start slurmctld 
systemctl start slurmd 

systemctl start slurmdbd

检查运行状态

systemctl status slurmctld 
systemctl status slurmd 

systemctl status slurmdbd

scontrol shownodes

sinfo -N -O "NodeList:10,CPUsState:15,CPUsLoad:10,FreeMem:10,GresUsed:28,StateComplete:30"

sacctmgr list Cluster



把配置文件拷贝到所有的节点的相同位置

pscp.pssh -H "node02 node03 node04 node05" /usr/local/etc/*.conf /usr/local/etc/

在管理点启动所有daemon

pssh -H "node02 node03 node04 node05 node06" cp  /home/zc/software/slurm-23.02.0-0rc1/etc/*.service /etc/systemd/system

pssh -H "node02 node03 node04 node05 node06" systemctl start slurmd

pssh -H "node02 node03 node04 node05 node06" systemctl enable slurmd

```
systemctl start slurmctld 
systemctl start slurmd 
slurmd -D 看看是否有错误
```

查看日志看是否有错误

```
vim /var/log/slurmd.log
vim /var/log/slurmctld.log
```

把启动加入开机自动运行

```
systemctl enable slurmctld 
systemctl enable slurmd 
```

在计算节点启动daemon并加入自动运行, 并查看是否有错误

```
systemctl start slurmd
systemctl enable slurmd 
vim /var/log/slurmd.log
```



```
scontrol show nodes 查看个节点状态
```

修改slurm.conf后

```
systemctl restart slurmctld
```



```
sinfo -N -o "%10N %15C %10O %10e %T"
```





sacctmgr 的管理

查看当前association

sacctmgr list assoc

参考用户，查看账户，以及把用户加入账户

```bash
sacctmgr list users
sacctmgr create account name=<account-name>
```

sacctmgr add user name=stu account=stu



限制某个账户最大cpu

```shell
sacctmgr add qos cpu256 cpu set MaxTRESPerUser=cpu=256
sacctmgr modify account where name=ACCOUNT_NAME set qos=qosname
```

列出当前已有qos

```bash
sacctmgr list qos format=Name,MaxTRESPerUser
```



## 参考 https://icode.pku.edu.cn/SCOW/docs/hpccluster/config/slurm.conf

#
# slurm.conf file. Please run configurator.html
# (in doc/html) to build a configuration file customized
# for your environment.
#
#
# slurm.conf file generated by configurator.html.
# Put this file on all nodes of your cluster.
# See the slurm.conf man page for more information.
#
################################################
#                   CONTROL                    #
################################################
ClusterName=cluster    #集群名称
SlurmctldHost=manage01    #管理服务节点名称
SlurmctldPort=6817    #slurmctld服务端口
SlurmdPort=6818   #slurmd服务的端口 
SlurmUser=slurm    #slurm的主用户
#SlurmdUser=root    #slurmd服务的启动用户

################################################
#            LOGGING & OTHER PATHS             #
################################################
SlurmctldDebug=info
SlurmctldLogFile=/var/log/slurm/slurmctld.log
SlurmdDebug=info
SlurmdLogFile=/var/log/slurm/slurmd.log
SlurmctldPidFile=/var/run/slurmctld.pid
SlurmdPidFile=/var/run/slurmd.pid
SlurmdSpoolDir=/var/spool/slurmd
StateSaveLocation=/var/spool/slurmctld

################################################
#                  ACCOUNTING                  #
################################################
AccountingStorageEnforce=associations,limits,qos  #account存储数据的配置选项
AccountingStorageHost=manage01    #数据库存储节点
AccountingStoragePass=/var/run/munge/munge.socket.2    #munge认证文件，与slurmdbd.conf文件中的AuthInfo文件同名。
AccountingStoragePort=6819    #slurmd服务监听端口，默认为6819
AccountingStorageType=accounting_storage/slurmdbd    #数据库记账服务

################################################
#                      JOBS                    #
################################################
JobCompHost=localhost      #作业完成信息的数据库本节点
JobCompLoc=slurm_acct_db    #数据库名称
JobCompPass=123456    #slurm用户数据库密码
JobCompPort=3306    #数据库端口
JobCompType=jobcomp/mysql     #作业完成信息数据存储类型，采用mysql数据库
JobCompUser=slurm    #作业完成信息数据库用户名
JobContainerType=job_container/none
JobAcctGatherFrequency=30
JobAcctGatherType=jobacct_gather/linux

################################################
#           SCHEDULING & ALLOCATION            #
################################################
SchedulerType=sched/backfill
SelectType=select/cons_tres
SelectTypeParameters=CR_Core

################################################
#                    TIMERS                    #
################################################
InactiveLimit=0
KillWait=30
MinJobAge=300
SlurmctldTimeout=120
SlurmdTimeout=300
Waittime=0

################################################
#                    OTHER                     #
################################################
MpiDefault=none
ProctrackType=proctrack/cgroup
ReturnToService=1
SwitchType=switch/none
TaskPlugin=task/affinity

################################################
#                    NODES                     #
################################################
NodeName=manage01 NodeAddr=192.168.29.106  CPUs=2 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=200 Procs=1 State=UNKNOWN
NodeName=login01 NodeAddr=192.168.29.101  CPUs=2 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=200 Procs=1 State=UNKNOWN
NodeName=compute0[1-2] NodeAddr=192.168.29.10[2-3]  CPUs=2 CoresPerSocket=1 ThreadsPerCore=1 RealMemory=200 Procs=1 State=UNKNOWN

################################################
#                  PARTITIONS                  #
################################################
PartitionName=compute Nodes=compute0[1-2] Default=YES MaxTime=INFINITE State=UP