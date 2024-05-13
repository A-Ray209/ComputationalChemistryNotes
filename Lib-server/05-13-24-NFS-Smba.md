# 05-13-24-NFS-Smba
### 1. NFS 文件共享
#### 1.1 安装

服务端（node01）和客户端（node02）都需要安装
```
sudo -i     # 获取超级权限
yum install -y nfs-utils
yum install -y rpcbind
```
#### 1.2 启动
在 node01 中
```
systemctl start rpcbind    # 先启动rpc服务
systemctl enable rpcbind   # 设置开机启动
systemctl start nfs-server    
systemctl enable nfs-server

```
#### 1.3 关闭防火墙


```
systemctl  status firewalld.service      # 查看防火墙的状态
systemctl  stop firewalld.service        # 关闭防火墙
systemctl  disable firewalld.service     # 开机禁用防火墙
systemctl  is-enabled firewalld.service  # 查看防火墙是否开机启动
```
#### 1.4 配置 NFS


```
vim /etc/exports     #编辑配置文件
```
添加一行
/home 192.168.245.0/24(rw,async,no_root_squash)    # 将 home 目录挂载到 192.168.1.x 网段下
:wq 保存退出

```
systemctl reload nfs-server   # 重新加载NFS服务，使配置文件生效
showmount -e 192.168.1.101    # 查看结果
```

#### 1.5 挂载 NFS

切换到 node02 临时挂载

```
mount -t nfs 192.168.1.101:/home /home     # 将 node01 的 home 挂载到 node02 的 home 目录
```
永久挂载

```
vim /etc/fstab     #编辑文件
```













### 1. Smba 文件共享