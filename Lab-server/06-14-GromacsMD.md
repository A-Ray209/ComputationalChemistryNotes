### 1. Gromacs MD

#### 1.1 安装 Gromacs 

#### 1.2 构建及优化分子力场参数脚本 ztop

参考网站：[构建及优化[小大]分子力场参数脚本 ztop.py](http://bbs.keinsci.com/forum.php?mod=viewthread&tid=22171&fromuid=63513)
> 需要 python3 库 (Anaconda)：networkx(图论), openmm(动力学), parmed(力场文件io和转换)，pandas和numpy(数据处理), matplotlib(绘图)
> 需要的第三方软件：Multiwfn，AmberTools，Gaussian，Libpargen(暂时不用）

安装 ambertools

```
conda create -n ztop -c conda-forge  networkx pandas numpy matplotlib parmed ambertools openmm

# 用 conda 安装的时候，容易出现不同包之间的版本冲突问题，创建一个虚拟环境专门运行本脚本，下面的命令建立了一个名为 ztop 的虚拟环境，并在其中安装必要的包之后要运行本脚本之前先运行下面的命令激活该环境
conda activate ztop

ztop.py --checkenv       # 检查安装结果

check parmed...parmed version 4.2.2 detected
check networkx...networkx version 3.3 detected
...
All differences are within tolerance.
```

安装 packmol
```
tar -vxf packmol-20.14.4-docs1.tar.gz
cd ./packmol-20.14.4-docs1.tar.gz/
make
vim ~/.bashrc
export PATH=/home/jzq/software/packmol-20.14.4-docs1:$PATH
```

#### 1.3 计算 DMB 的 Gromacs MD

计算文件准备
```
$ mkdir lrh/20240515//bulk_md/DMB   # 新建文件夹 
$ cp ../../DMB.chk ./               # 需要优化后的基态 .chk 和 .log 文件
$ cp ../../DMB.log ./

$ ztop.py -r e -g "DMB.log" -o DMB.top,DMB.gro   # 生成 .top 和 .gro 文件（-r e 优化生成力常数 .top 文件）
$ ztop.py -r e -g "DMB.log" -o DMB.top,DMB.pdb   # 
```
查看分子大小
```
$ Multiwfn DMB.fchk     # 使用 Multiwfn 测量大小
100                     # Other functions (Part 1)
21                      # Calculate properties based on geometry information for specific atoms
size                    # Input "size" will report size information of the whole system

Farthest distance:   52(H )  ---   78(H ):    17.469 Angstrom
 vdW radius of   52(H ): 1.200 Angstrom
 vdW radius of   78(H ): 1.200 Angstrom
 Diameter of the system:    19.869 Angstrom
 Radius of the system:     9.935 Angstrom
 Length of the three sides:    19.522    13.843    10.442 Angstrom      # 分子的长宽高约为 20 15 11
```
构建盒子，参考网站：[分子动力学初始结构构建程序 Packmol 的使用](http://sobereva.com/473)
```
vim packmol.inp            # 打包用的指令文件

tolerance 2.0
add_box_sides 1.2
output DMB_box.pdb             # 改名称，生成 DMB_box.pdb
structure DMB.pdb              # 改名称
  number 100                   # 数量
  inside cube 0. 0. 0. 100.    # 边长
end structure

packmol < packmol.inp         # 运行 packmol ，生成 DMB_box.pdb
```
合并拓扑文件
```
$ combinetop.py DMB.top    # 合并拓扑文件（包含力常数等）生成 topol.top
vim topol.top              # 修改名称和 nr. 100 （100 个）

[ defaults ]
; nbfunc        comb-rule       gen-pairs       fudgeLJ fudgeQQ
1               2               yes             0.5          0.83333333  
[ atomtypes ]
; name    at.num    mass    charge ptype  sigma      epsilon
nh             7  14.010000  0.00000000  A      0.3189952        0.89956
n2             7  14.010000  0.00000000  A     0.33841679      0.3937144
ca             6  12.010000  0.00000000  A     0.33152123      0.4133792
ha             1   1.008000  0.00000000  A     0.26254785      0.0673624
c5             6  12.010000  0.00000000  A     0.33977095      0.4510352
cp             6  12.010000  0.00000000  A     0.33152123      0.4133792
cq             6  12.010000  0.00000000  A     0.33152123      0.4133792
c2             6  12.010000  0.00000000  A     0.33152123      0.4133792

#include "DMB.itp"

[ system ]

[ molecules ]
;molecule name    nr.
DMB               100
```

GPT : 给我写一个优化体系的 gromacs 的 min.mdp 的输入文件并带上中文注释
```
$ vim min.mdp       # 编辑 min.mdp
$ cat min.mdp       # 查看 min.mdp
; GROMACS 模拟参数文件 (MDP 文件) - 能量最小化

; Run parameters 运行参数
integrator               = steep      ; 使用steepest descent算法进行能量最小化
emtol                    = 100.0      ; 力的阈值 (kJ/mol/nm)，达到这个值即认为最小化结束
emstep                   = 0.01       ; 最大步长 (nm)
nsteps                   = 50000      ; 最大步数

; Output control 输出控制
nstxout                  = 1000        ; 每 100 步保存一次坐标
nstvout                  = 1000        ; 每 100 步保存一次速度
nstenergy                = 1000        ; 每 100 步保存一次能量
nstlog                   = 1000        ; 每 100 步保存一次日志

; Neighborsearching 邻域搜索
nstlist                  = 10         ; 邻域列表更新频率
ns_type                  = grid       ; 使用网格方法进行邻域搜索
rlist                    = 1.0        ; 邻域列表的半径 (nm)

; Electrostatics 静电作用
coulombtype              = PME        ; 使用 Particle Mesh Ewald 方法计算静电作用
rcoulomb                 = 1.0        ; 静电作用截断半径 (nm)

; van der Waals forces 范德华力
vdwtype                  = cut-off    ; 使用截断法计算范德华力
rvdw                     = 1.0        ; 范德华力截断半径 (nm)

; Apply constraints on bonds 对键施加约束
constraints              = none       ; 无约束

; Periodic boundary conditions 周期性边界条件
pbc                      = xyz        ; 在 x, y, z 方向上应用周期性边界条件

; Temperature coupling is off during energy minimization 能量最小化过程中关闭温度耦合
tcoupl                   = no

; Pressure coupling is off during energy minimization 能量最小化过程中关闭压力耦合
pcoupl                   = no

; Velocity generation 速度生成
gen_vel                  = no         ; 不生成初始速度
```

```
$ ml av                                                           # 列出当前可用的软件模块，以便用户知道可以加载哪些软件环境
$ ml load gromacs                                                 # 设置 GROMACS 所需的环境变量和路径，使其可用。ml是module load的缩写，是模块化环境管理工具的一部分
$ gmx                                                             # 运行 GROMACS 的命令行工具，显示可用的GROMACS子命令
$ gmx grompp -f min.mdp -c DMB_box.pdb -p topol.top -o min.tpr    # 预处理 GROMACS 输入文件（合并要计算的文件）
$ gmx mdrun -s min.tpr -ntomp 32 -ntmpi 1 -deffnm min -v          # 运行 GROMACS 模拟（运行 优化）

# -f 计算指令 -c 体系坐标 -p 体系参数 -o 要输出文件的名称

$ vim compess.mdp                                                         # 编辑压缩体系指令
$ gmx grompp -f compess.mdp -c min.gro -p topol.top -o compress.tpr       # 预处理 GROMACS 输入文件（合并要计算的文件）  第一次
$ gmx mdrun -s compress.tpr -ntomp 32 -ntmpi 1 -deffnm compress -v        # 运行 GROMACS 模拟（运行 压缩）
$ vim compess.mdp                                                         # 修改压力参数，直到压缩成致密的正方体
$ gmx grompp -f compess.mdp -c compress.gro  -p topol.top -o compress.tpr # 预处理 GROMACS 输入文件（合并要计算的文件）  第 n 次
$ gmx mdrun -s compress.tpr -ntomp 32 -ntmpi 1 -deffnm compress -v        # 运行 GROMACS 模拟（运行 压缩）

$ cp compess.mdp relax.mdp                                          
$ vim relax.mdp                                                      # 编辑舒展体系指令，直到体系不再随时间舒展
$ gmx grompp -f relax.mdp -c compress.gro  -p topol.top -o relax.tpr # 预处理 GROMACS 输入文件（合并要计算的文件）
$ gmx mdrun -s relax.tpr -ntomp 32 -ntmpi 1 -deffnm relax -v         # 运行 GROMACS 模拟（运行 舒展）

$ cp relax.mdp prod.mdp                                              
$ vim prod.mdp                                                       # 编辑动力学模拟指令
$ gmx grompp -f prod.mdp -c relax.gro  -p topol.top -o prod.tpr      # 预处理 GROMACS 输入文件（合并要计算的文件）
$ gmx mdrun -s prod.tpr -ntomp 32 -ntmpi 1 -deffnm prod -v           # 运行 GROMACS 模拟（运行 动力学模拟）
```
在压缩的过程中，查看每次压缩的结果：用 VMD 加载 compress.gro （体系坐标），Main 窗口右键 load Data into Molcules 选择 compress.xtc（过程路径）CMD 命令窗口输入 pbc box 查看体系盒子边界

$ gmx energy -f compress.edr   选择 20 Volume （体积）产看结果 # energy.xvg   
在 Windows 电脑上安装 QtGrace，并打开产看 energy.xvg 

附：
compess.mdp
```
; GROMACS 模拟参数文件 (MDP 文件) - NPT 动力学和退火

; Run parameters 运行参数
integrator               = md            ; 使用分子动力学模拟算法
nsteps                   = 500000         ; 模拟步数，总时间 = nsteps * dt
dt                       = 0.002         ; 时间步长，单位 ps (这里为 2 fs)

; Output control 输出控制
nstxout                  = 10000          ; 每 1000 步保存一次坐标
nstvout                  = 10000          ; 每 1000 步保存一次速度
nstenergy                = 10000          ; 每 1000 步保存一次能量
nstlog                   = 10000          ; 每 1000 步保存一次日志
nstxout-compressed       = 10000          ; 每 1000 步保存一次压缩坐标文件

; Neighborsearching 邻域搜索
nstlist                  = 10            ; 邻域列表更新频率
ns_type                  = grid          ; 使用网格方法进行邻域搜索
rlist                    = 1.0           ; 邻域列表的半径 (nm)

; Electrostatics 静电作用
coulombtype              = PME           ; 使用 Particle Mesh Ewald 方法计算静电作用
rcoulomb                 = 1.0           ; 静电作用截断半径 (nm)

; van der Waals forces 范德华力
vdwtype                  = cut-off       ; 使用截断法计算范德华力
rvdw                     = 1.0           ; 范德华力截断半径 (nm)

; Apply constraints on bonds 对键施加约束
constraints              = h-bonds       ; 对含氢键使用约束

; Periodic boundary conditions 周期性边界条件
pbc                      = xyz           ; 在 x, y, z 方向上应用周期性边界条件

; Temperature coupling 温度耦合
tcoupl                   = V-rescale     ; 使用 V-rescale 方法进行温度耦合
tc-grps                  = system        ; 对整个系统进行温度耦合
tau_t                    = 0.1           ; 温度耦合时间常数 (ps)
ref_t                    = 300           ; 参考温度 (K)，初始为 300 K
; 退火参数
annealing                = periodic        ; 退火模式
annealing-npoints        = 3             ; 退火过程中使用的温度点数
annealing-time           = 0 200 400         ; 退火时间点 (ps)
annealing-temp           = 500 600 500     ; 对应的温度 (K)，从 300 K 降到 100 K

; Pressure coupling 压力耦合
pcoupl                   = C-rescale ; 使用 Parrinello-Rahman 方法进行压力耦合
pcoupltype               = isotropic     ; 等压缩 (各向同性)
tau_p                    = 2.0           ; 压力耦合时间常数 (ps)
ref_p                    = 1000.0           ; 参考压力 (bar)
compressibility          = 4.5e-5        ; 体系的可压缩性 (bar^-1)

; Velocity generation 速度生成
gen_vel                  = yes           ; 生成初始速度
gen_temp                 = 300           ; 生成速度对应的温度 (K)
gen_seed                 = -1            ; 随机数种子 (设置为-1表示随机种子)

```
relax.mdp
```
; GROMACS 模拟参数文件 (MDP 文件) - NPT 动力学和退火

; Run parameters 运行参数
integrator               = md            ; 使用分子动力学模拟算法
nsteps                   = 1000000         ; 模拟步数，总时间 = nsteps * dt
dt                       = 0.002         ; 时间步长，单位 ps (这里为 2 fs)

; Output control 输出控制
nstxout                  = 10000          ; 每 1000 步保存一次坐标
nstvout                  = 10000          ; 每 1000 步保存一次速度
nstenergy                = 10000          ; 每 1000 步保存一次能量
nstlog                   = 10000          ; 每 1000 步保存一次日志
nstxout-compressed       = 10000          ; 每 1000 步保存一次压缩坐标文件

; Neighborsearching 邻域搜索
nstlist                  = 10            ; 邻域列表更新频率
ns_type                  = grid          ; 使用网格方法进行邻域搜索
rlist                    = 1.0           ; 邻域列表的半径 (nm)

; Electrostatics 静电作用
coulombtype              = PME           ; 使用 Particle Mesh Ewald 方法计算静电作用
rcoulomb                 = 1.0           ; 静电作用截断半径 (nm)

; van der Waals forces 范德华力
vdwtype                  = cut-off       ; 使用截断法计算范德华力
rvdw                     = 1.0           ; 范德华力截断半径 (nm)

; Apply constraints on bonds 对键施加约束
constraints              = h-bonds       ; 对含氢键使用约束

; Periodic boundary conditions 周期性边界条件
pbc                      = xyz           ; 在 x, y, z 方向上应用周期性边界条件

; Temperature coupling 温度耦合
tcoupl                   = V-rescale     ; 使用 V-rescale 方法进行温度耦合
tc-grps                  = system        ; 对整个系统进行温度耦合
tau_t                    = 0.1           ; 温度耦合时间常数 (ps)
ref_t                    = 300           ; 参考温度 (K)，初始为 300 K
; 退火参数
annealing                = no        ; 退火模式
annealing-npoints        = 3             ; 退火过程中使用的温度点数
annealing-time           = 0 200 400         ; 退火时间点 (ps)
annealing-temp           = 500 600 500     ; 对应的温度 (K)，从 300 K 降到 100 K

; Pressure coupling 压力耦合
pcoupl                   = C-rescale ; 使用 Parrinello-Rahman 方法进行压力耦合
pcoupltype               = isotropic     ; 等压缩 (各向同性)
tau_p                    = 10.0           ; 压力耦合时间常数 (ps)
ref_p                    = 1.0           ; 参考压力 (bar)
compressibility          = 4.5e-5        ; 体系的可压缩性 (bar^-1)

; Velocity generation 速度生成
gen_vel                  = yes           ; 生成初始速度
gen_temp                 = 300           ; 生成速度对应的温度 (K)
gen_seed                 = -1            ; 随机数种子 (设置为-1表示随机种子)

```
prod.mdp
```
; GROMACS 模拟参数文件 (MDP 文件) - NPT 动力学和退火

; Run parameters 运行参数
integrator               = md            ; 使用分子动力学模拟算法
nsteps                   = 10000000         ; 模拟步数，总时间 = nsteps * dt
dt                       = 0.002         ; 时间步长，单位 ps (这里为 2 fs)

; Output control 输出控制
nstxout                  = 100000          ; 每 1000 步保存一次坐标
nstvout                  = 100000          ; 每 1000 步保存一次速度
nstenergy                = 100000          ; 每 1000 步保存一次能量
nstlog                   = 100000          ; 每 1000 步保存一次日志
nstxout-compressed       = 100000          ; 每 1000 步保存一次压缩坐标文件

; Neighborsearching 邻域搜索
nstlist                  = 10            ; 邻域列表更新频率
ns_type                  = grid          ; 使用网格方法进行邻域搜索
rlist                    = 1.0           ; 邻域列表的半径 (nm)

; Electrostatics 静电作用
coulombtype              = PME           ; 使用 Particle Mesh Ewald 方法计算静电作用
rcoulomb                 = 1.0           ; 静电作用截断半径 (nm)

; van der Waals forces 范德华力
vdwtype                  = cut-off       ; 使用截断法计算范德华力
rvdw                     = 1.0           ; 范德华力截断半径 (nm)

; Apply constraints on bonds 对键施加约束
constraints              = h-bonds       ; 对含氢键使用约束

; Periodic boundary conditions 周期性边界条件
pbc                      = xyz           ; 在 x, y, z 方向上应用周期性边界条件

; Temperature coupling 温度耦合
tcoupl                   = V-rescale     ; 使用 V-rescale 方法进行温度耦合
tc-grps                  = system        ; 对整个系统进行温度耦合
tau_t                    = 0.1           ; 温度耦合时间常数 (ps)
ref_t                    = 300           ; 参考温度 (K)，初始为 300 K
; 退火参数
annealing                = no        ; 退火模式
annealing-npoints        = 3             ; 退火过程中使用的温度点数
annealing-time           = 0 200 400         ; 退火时间点 (ps)
annealing-temp           = 500 600 500     ; 对应的温度 (K)，从 300 K 降到 100 K

; Pressure coupling 压力耦合
pcoupl                   = no            ; 使用 Parrinello-Rahman 方法进行压力耦合
pcoupltype               = isotropic     ; 等压缩 (各向同性)
tau_p                    = 10.0           ; 压力耦合时间常数 (ps)
ref_p                    = 1.0           ; 参考压力 (bar)
compressibility          = 4.5e-5        ; 体系的可压缩性 (bar^-1)

; Velocity generation 速度生成
gen_vel                  = yes           ; 生成初始速度
gen_temp                 = 300           ; 生成速度对应的温度 (K)
gen_seed                 = -1            ; 随机数种子 (设置为-1表示随机种子)


```
