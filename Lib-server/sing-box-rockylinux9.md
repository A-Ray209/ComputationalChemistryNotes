## sing-box rockylinux9



### 1. 下载sing-box，解压安装

https://github.com/SagerNet/sing-box/releases

查看安装位置：

`rpm -ql sing-box_1.9.0-alpha.8_linux_amd64.rpm`

进行安装（需要管理员权限

`1sudo rpm -ivh sing-box_1.9.0-alpha.8_linux_amd64.rpm `



### 2. 产生配置文件

正确的配置文件是sing-box成功运行的关键，但是sing-box无法直接读取订阅服务器地址产生配置文件，需要转换一下

到下面的网站，

https://sing-box-subscribe.vercel.app/

把订阅地址复制到"url": 之后，选择1号config_template, 然后点击Select and Generate

将产生的json复制，在Linux服务器上任意一个位置（这里以家目录为例）新键config.json，然后把复制的内容粘贴进去



### 3. 验证配置文件是否可用(关键)

运行下面的命令来测试配置文件是否可用(这里必须要管理员权限，因为他要创建tun虚拟网卡)

```shell
sudo sing-box -c ~/config.json run
```

观察上面的输出，看看远程服务器是否连接成功，如果连接成功，应该会输出延迟，假设这里的输出在窗口A。

然后新开一个窗口B，运行下面的命令测试网络连接情况：

```shell
curl www.baidu.com
curl www.google.com
```

如果这里不成功，需要仔细vionfig.json文件

订阅意味着远程服务器的地址可能会经常更换，如果每次服务器位置更换之后，都需要重新远程产生配置文件，会很麻烦，毕竟远程的东西不太可靠，所以这一步我们配置本地产生config.json文件。

##### a. 首先本地需要python 3.10 以上版本，然后运行下面的命令安装依赖包

```shell
conda install -c conda-forgerequests paramiko scp chardet Flask PyYAML ruamel.yaml
```

##### b. 下载sing-box-subscribe

git clone https://github.com/Toperlock/sing-box-subscribe.git

##### c. 修改配置文件和模板文件

修改providers.json如下

`{`
    `"subscribes":[`
        `{`
            `"url": "https://jmssub.net/members/getsub.php?service=xxxx&id=xxxxxxxxxx",`
            `"tag": "tag_1",`
            `"enabled": true,`
            `"emoji": 0,`
            `"subgroup": "",`
            `"prefix": "",`
            `"User-Agent":"sing-box"`
        `}`
    `],`
    `"auto_set_outbounds_dns":{`
        `"proxy": "",`
        `"direct": ""`
    `},`
    `"save_config_path": "./config.json",`
    `"auto_backup": false,`
    `"exclude_protocol":"ssr",`
    `"config_template": "",`
    `"Only-nodes": false`
`}`

其中"url" 后是订阅地址，User-Agent后改成sing-box

修改config_template/config_template_groups_rule_set_tun.json文件

其中各个参数的含义可以参考

https://icloudnative.io/posts/sing-box-tutorial/#sing-box-%E9%85%8D%E7%BD%AE%E8%A7%A3%E6%9E%90

https://sing-box.sagernet.org/configuration/



##### d. 测试产生位置文件

```
python main.py
```

这里会要你选择使用哪个模板，这里选你刚修改的哪个模板就行

然后这里返回步骤3，测试产生的config.json是否可用



### 5. 把sing-box 加入系统自启动

```shell
sudo vim /etc/systemd/system/sing-box.service
```

内容如下：

[Unit]
Description=sing-box service
Documentation=https://sing-box.sagernet.org
After=network.target nss-lookup.target network-online.target

[Service]
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_SYS_PTRACE CAP_DAC_READ_SEARCH
ExecStart=**/usr/bin/sing-box -c /home/zc/sing-box-subscribe/config.json  -D /home/zc/sing-box-subscribe run**
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=10s
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target



然后修改/home/zc/sing-box-subscribe/目录下的cache.db文件的用户为root，或者赋予其可写权限

```shell
sudo chown  root:root /home/zc/sing-box-subscribe/cache.db
# 或者
sudo chmod  666 /home/zc/sing-box-subscribe/cache.db
```

然后启动服务

```shell
sudo systemctl start sing-box
sudo systemctl enable sing-box
sudo systemctl status sing-box
```



### 6. 配置自动订阅

进入sing-box-subscribe目录然后编辑autosub.sh文件如下

```shell
#!/bin/bash
cd /home/zc/sing-box-subscribe
echo 1 | /home/software/anaconda3/bin/python main.py
```

创建/etc/systemd/system/autosub.service文件，在其中加入

```
[Unit]
Description=Subscription Remote Configuration for sing-box config.json
After=network.target

[Service]
Type=oneshot
WorkingDirectory=/home/zc/sing-box-subscribe
ExecStart=/home/zc/sing-box-subscribe/autosub.sh
ExecStartPost=/bin/sh -c "systemctl restart sing-box"

[Install]
WantedBy=multi-user.target

```

创建/etc/systemd/system/subladder.timer文件，在其中加入

```
[Unit]
Description=Run Subladder Daily

[Timer]
#OnCalendar=daily
OnCalendar=*-*-* 04,16:00:00
RandomizedDelaySec=60m
Persistent=true

[Install]
WantedBy=timers.target
```

启动定时器，并查看定时器

```
systemctl enable autosub.timer
systemctl list-timers --allv
```

测试自动订阅情况，检查sing-box的config.json是否更新
systemctl start subladder
ll ~/sing-box-subscribe/config.json #查看更新时间



### 7. 配置透明代理

用的是tun虚拟网卡模式，配置透明代理比较简单，不用管TPROXY iptables nftable等设置

```shell
su # 切换root用户
 echo 1 > /proc/sys/net/ipv4/ip_forward # 启动IP转发
```

然后将同一局域网下的其他电脑的网关设置为这个电脑就行了

