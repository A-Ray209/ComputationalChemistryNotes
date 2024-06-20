### 1. 安装 cp2k

参考网站 [CP2K第一性原理程序在CentOS中的简易安装方法](http://sobereva.com/586)

将空文件替换 ~/.bashrc 原 bashrc 暂存为 tmp_bashrc (清空安装环境)

去h ttps://github.com/cp2k/cp2k/releases/ 下载CP2K压缩包 cp2k-8.1.tar.bz2，运行 `tar -xf cp2k-8.1.tar.bz2` 命令解压之。下文假设解压后的目录是 /software/cp2k-8.1/ 
运行以下命令
```
cd /software/cp2k-8.1/tools/toolchain/
./install_cp2k_toolchain.sh --with-sirius=no --with-openmpi=install --with-plumed=install
```
接着上一节，现在把 `/software/cp2k-8.1/tools/toolchain/install/arch/` 下所有文件拷到 `/software/cp2k-8.1/arch` 目录下。这些文件定义了编译不同版本的CP2K所需的参数，其内容是 toolchain 脚本根据装的库和当前环境自动产生的。然后运行以下命令
```
source /software/cp2k-8.1/tools/toolchain/install/setup
cd /software/cp2k-8.1
make -j 4 ARCH=local VERSION="ssmp psmp"      #-j后面的数字是并行编译用的核数，机子有多少物理核心建议就设多少。
```

### 2. 计算电荷转移积分

计算需要的程序：AICT、AICTs
```
sudo cp ~/CCflash/AICT /home/jzq/software/ztools
sudo cp ~/CCflash/AICTs /home/jzq/software/ztools
```
计算过程：
1. 优化 (分子1+分子2).gjf
2. $ qcinp (分子1+分子2).log 产生 gif 文件
3. $ cccm.py (分子1+分子2)..gjf  产生 A，B，AB 文件
4. 提交 g16s A，B，AB 文件
5. $ cccm.py 自动输出结果
```
$ cccm.py

system              A_H--B_H (cm-1)     A_H--B_L (cm-1)     A_L--B_H (cm-1)     A_L--B_L (cm-1)
6PhD1                  74.040            -231.906            -198.060             667.778
```
计算电荷转移速率，Marcus 方程：
积分、能极差、重组能
![输入图片说明](img/%E5%BE%AE%E4%BF%A1%E6%88%AA%E5%9B%BE_20240620154932.jpg)
### 3. Gromacs 模拟主客体相互作用动力学

与 06-14-24-GromacsMD.md 内容相同

不同之处在于，要同时优化主客体，生成 .log .fchk 文件，再使用 ztop.py 生成 .gro .top .pdb 文件夹

packmol.inp 要将主客体装入盒子，生成 DMB_mix.pdb

合并拓扑文件命令为：`combinetop.py DMB.top mCBP.top` 生成 topol.top

然后顺序使用：min.mdp、compress.mdp、relax.mdp、prod.mdp 命令对体系进行动力学模拟
```
$ cat packmol.inp

tolerance 2.0
add_box_sides 1.2
output DMB_mix.pdb
structure DMB.pdb
  number 100
  inside cube 0. 0. 0. 150.
end structure
structure mCBP.pdb
  number 1000
  inside cube 0. 0. 0. 150.
end structure
```

```
$ cat topol.top

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
na             7  14.010000  0.00000000  A     0.32058099      0.8543728

#include "DMB.itp"
#include "mCBP.itp"

[ system ]

[ molecules ]
;molecule name    nr.
DMB               100
MCB               1000

```

### 4. 分析 Gromacs 计算结果

Gromacs 进行动力学分析会将原子序号依次排列。

举例：A 分子有 150 个原子、B  分子有 100 个原子，盒子中有 10 个 A 分子、100 个 B 分子，则 A 分子的编号为 1 - 1500 ，B 分子编号为 1501 - 11500。A1 为 1 - 150，A2 为 151 - 300。

所以分析结果询问 GPT 时，有如下提问：

> 我现在有经过gromacs计算得到的.gro和.xtc文件，我给出分子两部分的原子序号，帮我写一个python脚本使用MDanalysis分析，两部分中心距离，平面夹角

> 体系中有n个分子，n以及相对原子序号从外部命令传入，脚本需要计算绝对原子序号

> 需计算每一个分子内的片段1和片段2的 centroid 和 distance

> 我需要修改输入的命令为python analyze_md.py your_file.gro your_file.xtc 100 "1,14,15,16,81,90" "24,83,61,19,20,22" 其中1,14,15,16,81,90是1部分，24,83,61,19,20,22是2部分

代码结果为

```
#!/bin/env python

import MDAnalysis as mda
import numpy as np
import argparse

# 解析命令行参数
parser = argparse.ArgumentParser(description='Analyze MD trajectory.')
parser.add_argument('gro_file', type=str, help='GRO file')
parser.add_argument('xtc_file', type=str, help='XTC file')
parser.add_argument('n_molecules', type=int, help='Number of molecules')
parser.add_argument('rel_atoms_part1', type=str, help='Comma-separated relative atom indices for part 1')
parser.add_argument('rel_atoms_part2', type=str, help='Comma-separated relative atom indices for part 2')
args = parser.parse_args()

# 解析相对原子序号字符串为整数列表
def parse_indices(indices_str):
    return [int(x) for x in indices_str.split(',')]

rel_atoms_part1 = parse_indices(args.rel_atoms_part1)
rel_atoms_part2 = parse_indices(args.rel_atoms_part2)

# 计算绝对原子序号
def calculate_absolute_indices(relative_indices, molecule_index, n_atoms_per_molecule):
    return [i + molecule_index * n_atoms_per_molecule for i in relative_indices]

# 读取文件
gro_file = args.gro_file
xtc_file = args.xtc_file

# 分子数量
n_molecules = args.n_molecules

# 加载宇宙
u = mda.Universe(gro_file, xtc_file)
n_atoms_per_molecule = len(u.atoms) // n_molecules

# 计算质心
def calc_centroid(atomgroup):
    return atomgroup.center_of_mass()

# 计算两个平面的法向量
def calc_plane_normal(atomgroup):
    # 使用前三个原子计算平面
    pos = atomgroup.positions[:3]
    v1 = pos[1] - pos[0]
    v2 = pos[2] - pos[0]
    normal = np.cross(v1, v2)
    normal /= np.linalg.norm(normal)
    return normal

# 计算夹角
def calc_angle_between_planes(normal1, normal2):
    cos_theta = np.dot(normal1, normal2)
    angle = np.arccos(cos_theta)
    return np.degrees(angle)

# 存储结果
distances = []
angles = []

# 遍历轨迹
for ts in u.trajectory:
    frame_distances = []
    frame_angles = []
    for mol_index in range(n_molecules):
        part1_atoms = calculate_absolute_indices(rel_atoms_part1, mol_index, n_atoms_per_molecule)
        part2_atoms = calculate_absolute_indices(rel_atoms_part2, mol_index, n_atoms_per_molecule)
        
        part1 = u.select_atoms("index " + " ".join(map(str, part1_atoms)))
        part2 = u.select_atoms("index " + " ".join(map(str, part2_atoms)))
        
        centroid1 = calc_centroid(part1)
        centroid2 = calc_centroid(part2)
        distance = np.linalg.norm(centroid1 - centroid2)
        frame_distances.append(distance)
        
        normal1 = calc_plane_normal(part1)
        normal2 = calc_plane_normal(part2)
        angle = calc_angle_between_planes(normal1, normal2)
        frame_angles.append(angle)
    distances.append(frame_distances)
    angles.append(frame_angles)

# 打印或保存结果
 #print("Distances:", distances)
 #print("Angles:", angles)

# 可选择保存到文件

distances = np.array(distances)
angles = np.array(angles)

output_filename = "distances_output.txt"
with open(output_filename, 'w', encoding="utf-8") as f:
    f.write("Index \t distance (Å)\n")
    for idx, distances in enumerate(distances):
        f.write(f"{idx + 1}\t{distances}\n")

output_filename = "angles_output.txt"
with open(output_filename, 'w', encoding="utf-8") as f:
    f.write("Index \t Angle (degrees)\n")
    for idx, angle in enumerate(angles):
        f.write(f"{idx + 1}\t{angle}\n")
```
