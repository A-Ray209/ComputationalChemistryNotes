### 1. 读能级

Linux 计算的 .chk 文件为二进制文件，放在 Windows 电脑要经过转化
```
for i in *.chk; do formchk $i; done    # 将 .chk 转为 .fchk
```
下载钟老师仓库脚本

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








### 3.  SOC






### 4. 空穴电子分布