### 1. 读能级

Linux 计算的 .chk 文件为二进制文件，放在 Windows 电脑要经过转化
```
for i in *.chk; do formchk $i; done    # 将 .chk 转为 .fchk
```

方式一：
用 GaussView 打开 .cube 文件，右键 tools - MOs
查看轨道能级能量，单位 hartree
转化为 eV ，乘以 27.2114


方式二：下载钟老师仓库脚本

```
git clone https://gitee.com/coordmagic/vmwfn.git     # 克隆仓库
cd vmwfn/                                            # 到下载的仓库文件夹下
ls                                                   # 查看可执行权限（绿色）
vim ~/.bashrc                                        # 将下载文件夹路径添加为环境变量
source ~/.bashrc
```
脚本安装结束

用脚本查看能级
```
cd ~/yhy/051524/           # 到计算文件夹下
tmwfn.py -o h1-l1 *.log    # 查看 HOMO-LUMO 能级 
```
结束

### 2. 绘制轨道图


```
cd ~/yhy/051524/                                        # 到计算文件夹下
cubegen 0 mo=homo,lumo QAO-TF.fchk QAO-TF.cube 0 h      # 利用 cubgen 命令生成 .cube 绘图文件

for i in *.fchk; do cubegen 0 mo=homo,lumo $i ${i/.fchk/}.cube 0 h; done       # 利用循环命令批量导出 .cube 文件
```

用 GaussView 打开 .cube 文件，
右键 - Results - Surface - New Surface
![输入图片说明](img/%E5%BE%AE%E4%BF%A1%E6%88%AA%E5%9B%BE_2024051.png)
![输入图片说明](img/%E5%BE%AE%E4%BF%A1%E6%88%AA%E5%9B%BE_20.png)

绘制 HOMO - LUMO 轨道图

修改颜色

![输入图片说明](img/HOMOLUMO.png)

### 3.  SOC






### 4. 空穴电子分布