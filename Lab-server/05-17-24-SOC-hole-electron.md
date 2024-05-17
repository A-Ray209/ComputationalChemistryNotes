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

File - Preference - Couor - Surface Color

![输入图片说明](img/HOMOLUMO.png)

### 3.  SOC

#### 3.1 从仓库安装 SOC

```
cd ~/software                                                 # 到软件目录下
git clone https://gitee.com/alpharay18953964293/pysoc.git     # 下载执行文件
cd /home/jzq/software/sob_PySOC_MolSOC/pysoc/bin              # 到执行文件目录下
ls                                                            # 查看可执行文件
export PATH=/home/jzq/software/sob_PySOC_MolSOC/pysoc/bin:$PATH    # 临时添加环境变量
which pysoc.py                                                     # 查看添加结果
update_pysoc.sh                                                    # 配置 SOC 文件
vim ~/.bashrc                                                      # 永久添加环境变量
export PATH=/home/jzq/software/sob_PySOC_MolSOC/pysoc/bin:$PATH    # 添加内容
```
#### 3.2 计算 SOC

```
cd /home/jzq/yhy/20240515/td_vert/                                 # 到计算目录下
calcsoc -s 3 -t 3 TQAOF_tdvert.log                                 # 查看计算结果                    
calcsoc -s 1 -t 1 TQAOF_tdvert.log > TQAOF_tdvert——soc.txt              # 将理算结果导入到 .txt 文件中
for i in *.log; do calcsoc -s 1 -t 1 $i > ${i/.log/}_soc.txt; done      # 批量执行
grep 'sum_soc, <S1|Hso|T1,1,0,-1>' *.txt                                # 抓取计算结果
```
取冒号后的第一位数字

![输入图片说明](img/SOC_1.png)

#### 3.3 上传 Gitee 仓库

将钟老师编译好的 pysoc 包上传到仓库

```
cd ~/software                          
git clone https://gitee.com/alpharay18953964293/pysoc.git      # 克隆仓库
git add -A                                                     # 添加
git status                                                     # 查看状态
git commit -m pysoc                                            # 提交 pysoc 
git config --global user.name '葛世杰'                          # 仓库信息
git config --global user.email '2091816477@qq.com'             # 仓库信息 
git push                                                       # 推送仓库
```


### 4. 空穴电子分布