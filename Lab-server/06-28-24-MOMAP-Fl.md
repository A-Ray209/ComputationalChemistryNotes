### MOMAP 计算荧光光谱

配置环境：
```
export PATH=/home/software/MOMAP-2021B/bin/:$PATH
source /home/software/MOMAP-2021B/env.sh
```
吸收光谱、荧光光谱以及辐射速率的计算流程以 azulene 为例，算例数据位于 momap/example/azulene/ 目录下。 下图为 azulene 的结构示意图，由五元环和七 元环组成，其分子式为 C10H8。

#### 1.1 量化计算
a. 基态构型优化与频率计算
本算例部分计算文件在 azulene/gaussian/ 目录下。Gaussian 使用方法详见 Gaussian 手册。 以下为使用Gaussian进行基态构型优化与频率计算的输入文件的例子：
```
%chk=azulene-s0.chk         #输出 chk 文件
%mem=4GB                    #内存大小
%nprocl=1                   #使用节点数
%nprocs=16                  #每个节点上的并行的核数
#p opt freq B3LYP/6-31G     #基于DFT方法/B3LYP 泛函/6-31G(d)基组对分子基态构型进行优化，然后计算优化后分子构型的频率

azulene-s0 optimization     #标题行

0 1                         #净电荷数为 0，自选多重度为 1
 C                  2.01378743   -1.48849852    0.00000000
 C                  2.28995141   -0.11795315    0.00000000
 C                  1.39185815    0.95357383    0.00000000
 C                  0.78413689   -2.15418449    0.00000000
 C                  0.00000000    0.93285810    0.00000000
 C                 -0.50398383   -1.61065958    0.00000000
 C                 -0.89316505   -0.27406276    0.00000000
 H                  2.88919252   -2.13621797    0.00000000
 H                  3.34387207    0.15083266    0.00000000
 H                  1.84191311    1.94635990    0.00000000
 H                  0.83658347   -3.24058384    0.00000000
 H                 -1.32037398   -2.33298523    0.00000000
 C                 -0.84567310    2.05536637    0.00000000
 H                 -0.51364908    3.08694089    0.00000000
 C                 -2.17758707    1.61062710    0.00000000
 H                 -3.04994479    2.25593917    0.00000000
 C                 -2.21339978    0.20656494    0.00000000
 H                 -3.10314368   -0.41207657    0.00000000
```
计算结束后得到 azulene-s0.chk 和 azulene-s0.log 输出文件。 使用以下指令对二进制的 checkpoint 文件进行转换:

formchk azulene-s0.chk

运行结束后生成文件 azulene-s0.fchk，azulene-s0.flog 和 azulene-s0.fchk 这两个文件将用于后续的振动分析计算。


Warning：文件结尾注意空两行，表示高斯文件结束。

b. 激发态构型优化与频率计算
本部分计算文件在 azulene/gaussian/ 目录下。 基态 S0 构型优化完成后，使用 S0 优化后的构型作为激发态 S1 的初始构型， 用来优化激发态和计算激发态频率。
```
%chk=azulene-s1.chk
%mem=4GB
%nprocl=1
%nprocs=16
#p opt freq td b3lyp/6-31g(d)   #基于TDDFT方法/B3LYP 泛函/6-31G(d)基组对分子激发态构型进行优化，然后计算优化后分子构型的频率

azulene-s1 optimization

0 1
 C                  2.01378700   -1.48849900    0.00000000
 C                  2.28995100   -0.11795300    0.00000000
 C                  1.39185800    0.95357400    0.00000000
 C                  0.78413700   -2.15418400    0.00000000
 C                  0.00000000    0.93285800    0.00000000
 C                 -0.50398400   -1.61066000    0.00000000
 C                 -0.89316500   -0.27406300    0.00000000
 H                  2.88919300   -2.13621800    0.00000000
 H                  3.34387200    0.15083300    0.00000000
 H                  1.84191300    1.94636000    0.00000000
 H                  0.83658300   -3.24058400    0.00000000
 H                 -1.32037400   -2.33298500    0.00000000
 C                 -0.84567300    2.05536600    0.00000000
 H                 -0.51364900    3.08694100    0.00000000
 C                 -2.17758700    1.61062700    0.00000000
 H                 -3.04994500    2.25593900    0.00000000
 C                 -2.21340000    0.20656500    0.00000000
 H                 -3.10314400   -0.41207700    0.00000000
```
计算结束后得到 azulene-s1.chk 和 azulene-s1.log 输出文件。 使用以下指令对二进制的 checkpoint 文件进行转换:

formchk azulene-s1.chk

运行结束后生成文件 azulene-s1.fchk，azulene-s1.flog 和 azulene-s1.fchk 这两个文件将用于后续的振动分析计算。

#### 1.2 振动分析(EVC)
本部分计算文件在 azulene/evc/ 目录下。

收集以上计算得到的基态和激发态的计算结果文件，包括日志文件 (azulene-s0.log、azulene-s1.log)和格式化的 Checkpoint 文件(azulene-s0.fchk、 azulene-s1.fchk)，注意需保证振动结果无虚频(在频率计算文件中搜索 Frequencies，注意 F 大写，可以找到频率信息)，将这些文件都放在一个文件夹 (evc)中，编写 EVC 振动分析的输入文件
```
$cat momap.inp:

do_evc          = 1                      # 1 表示开启dushin计算，0 表示关闭

&evc
  ffreq(1)      = "azulene-s0.log"       #基态结果的日志文件
  ffreq(2)      = "azulene-s1.log"       #激发态结果的日志文件
/
```
执行以下命令运行 EVC 振动分析程序:

momap –input momap.inp –nodefile nodefile

程序正常结束后，得到下一步计算的输入文件 evc.cart.dat。

Important：MOMAP支持并行运算，如果使用队列脚本(如 PBS 脚本)提交任务，则只需在 PBS 脚本中修改提交队列名称、使用节点数量和核数量。

如果不使用队列脚本，可以在 nodefile 里 指定节点名称和核数。例如:需要使用节点名称为 node1 和 node2 的两个节点，每个节点上使用 2 个核。则 nodefile 写为

node1
node1
node2
node2
#### 1.3 辐射速率
a. 辐射速率输入文件 momap.inp:
```
do_spec_tvcf_ft   = 1                   #1 表示开启计算荧光关联函数
do_spec_tvcf_spec = 1                   #1 表示开启计算荧光光谱

&spec_tvcf                              #描述计算内容
  DUSHIN       = True                    #是否考虑 Duschinsky 转动(t 开启，f 关闭)
  Temp         = 300                     #温度
  tmax         = 1000                    #积分时间
  dt           = 1                       #积分步长
  Ead          = 0.07509                 #绝热激发能
  EDMA         = 0.92694                 #吸收跃迁偶极矩
  EDME         = 0.64751                 #发射跃迁偶极矩
  FreqScale    = 1.0                     #频率缩放因子
  DSFile       = "evc.cart.dat"          #定义读取的 evc 文件名
  Emax         = 0.3 au                  #定义光谱频率范围上限
  dE           = 0.00001                 #定义输出能量间隔
  logFile      = "spec.tvcf.log"         #定义输出 log 文件名
  FtFile       = "spec.tvcf.ft.dat"      #定义输出的关联函数文件名
  FoFile       = "spec.tvcf.fo.dat"      #谱函数输出文件
  FoSFile      = "spec.tvcf.spec.dat"    #归一化的光谱输出文件
/
```
版本2
```
do_spec_tvcf_ft   = 1                   #1 表示开启计算荧光关联函数
do_spec_tvcf_spec = 1                   #1 表示开启计算荧光光谱

&spec_tvcf                              #描述计算内容
  DUSHIN       = True                    #是否考虑 Duschinsky 转动(t 开启，f 关闭)
  Temp         = 300                     #温度
  tmax         = 1000                    #积分时间
  dt           = 1                       #积分步长
  DSFile        = “evc.cart.dat“   # evc文件
  Ead           = 0.082678 au        # 绝热激发能
  dipole_abs    = 0.092465 debye     # 跃迁偶极矩（吸收）
  dipole_emi    = 0.440702 debye     # 跃迁偶极矩（发射）
  maxvib        = 10                 # 最大量子数
  if_cal_ic     = .t.                # 是否计算无辐射通道
  promode       = 24                 # 指定提升模式（无辐射通道）
  FC_eps_abs    = 0.1                # FC因子阈值
  FC_eps_emi    = 0.1 
  FC_eps_ic     = 0.1 
  FreqScale     = 1.0                # 频率缩放因子
  FreqEPS       = 0.01               # distortion阈值
  Seps          = 0.01               # 黄昆因子阈值
  FWHM          = 500   cm-1         # 展宽（半高全宽）
  flog          = “spec.sums.log“  # log文件
  reduce_eps    = 0.001              # 光谱输出阈值
/
```


See also

对以上MOMAP输入变量的解释，请参考API Reference 部分.

把 momap.inp 文件、nodefile 文件和 evc.cart.dat 文件放置于同一目录，运行以下命令进行计算:

momap –input momap.inp –nodefile nodefile

b. 计算结果解读:
运行结束后会得到结果文件：

输出文件名

输出文件内容 spec.tvcf.fo.dat

谱函数输出文件 spec.tvcf.ft.dat

关联函数输出文件 spec.tvcf.log

log 文件 spec.tvcf.spec.dat

光谱文件:

计算完成后先确认关联函数是否收敛，将 spec.tvcf.ft.dat 的前两列画图，若随着积分时间的增加，纵坐标的值基本为 0 且呈直线，则表示关联函数已经收敛。

确认关联函数收敛后，根据光谱文件 spec.tvcf.spec.dat，选取所需数据画出 相关的吸收光谱和发射光谱:

辐射速率 kr 可在 spec.tvcf.log 文件末端读取。如下图所示，第一个数值和第 二个数值都表示辐射速率，单位分别是 au 和 s-1，第三个数值表示寿命。计算得 到 azulene 分子的辐射速率 kr 为 2.72281554×105s-1。


[参考网站](https://pyminds.readthedocs.io/en/latest/spec.html#id2)