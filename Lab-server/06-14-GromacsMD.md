### 1. Gromacs MD

#### 1.1 安装 Gromacs 

#### 1.3 构建及优化分子力场参数脚本 ztop

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
#### 1.3 计算 DMB 的 Gromacs MD

计算文件准备
```
$ mkdir lrh/20240515//bulk_md/DMB   # 新建文件夹 
$ cp ../../DMB.chk ./               # 需要优化后的基态 .chk 和 .log 文件
$ cp ../../DMB.log ./

$ ztop.py -r e -g "DMB.log" -o DMB.top,DMB.gro   # 生成 .top 和 .gro 文件
$ ztop.py -r e -g "DMB.log" -o DMB.top,DMB.pdb
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
构建盒子，参考网站[分子动力学初始结构构建程序 Packmol 的使用](http://sobereva.com/473)
```
vim packmol.inp            # 打包用的指令文件

tolerance 2.0
add_box_sides 1.2
output DMB_box.pdb             # 名称
structure DMB.pdb              # 名称
  number 100                   # 数量
  inside cube 0. 0. 0. 100.    # 边长
end structure
```
