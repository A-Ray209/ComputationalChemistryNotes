### 1. 更换局域网

#### 1.1 连接新网段

主机连接显示器

用 root 登录，密码 jzq+手机号，登录终端

删除原有网段
```
route -n               # 查看

Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.1.1     0.0.0.0         UG    100    0        0 enp0s3
192.168.1.0     0.0.0.0         255.255.255.0   U     100    0        0 enp0s3

sudo route del -net 192.168.1.0 netmask 255.255.255.0   # 删除
route -n               # 查看
```

添加新网段
```
nmcli device status         # 查看连接状态
# 修改
nmcli connection modify enp0s3 ipv4.addresses 192.168.1.100/24
nmcli connection modify enp0s3 ipv4.gateway 192.168.1.1
nmcli connection modify enp0s3 ipv4.dns 192.168.1.1
nmcli connection modify enp0s3 ipv4.method manual
nmcli con up enp0s3

ping www.baidu.com      # 测试
```
#### 1.2 设置其他应用

1. 设置 hostname 避免与新网段冲突
2. 设置 /etc/hosts 文件（本地IP解析）
3. 修改 NFS 文件共享，配置文件修改，见 05-13-24-NFS (node01)
4. 修改 node12（原02）共享新的 NFS 路径
5. 修改 slurm 配置文件中的主机名称
6. 查看 zerotier 是否正常工作

#### 1.3 加入钟老师计算机集群

1. 在新集群中添加 jzq 账户 （userid=1003）
2. 将旧集群的 jzq 用户的 （userid=1000）改为（userid=1300），使用 root 权限
3. 在新集群中添加 /data 缓存路径


### 2. 定义计算 orca ΔEst 命令

orcas_est.sh 放置于 ztools 文件夹下（环境变量）

脚本内容：

```
#!/bin/bash

# Loop through all .out files not starting with "slurm"
for file in $(ls *.out | grep -v '^slurm'); do
  
  # Find the keyword, get the 5th line after it, and then print the 6th column of that line
  s1=$(grep -A 5 "EXCITED STATES (SINGLETS)" "$file" | awk 'NR==6 {print $6}')
  t1=$(grep -A 5 "EXCITED STATES (TRIPLETS)" "$file" | awk 'NR==6 {print $6}')
  orcas_est=`echo "($s1 - $t1)" | bc`
  echo "orcas_est $file = $orcas_est"
done
```
