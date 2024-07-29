
#### 1. fchk 转换文件出错

在转换大体系 .chk 到 .fchk 时出现

```
(base) [jzq@node01 tdvert]$ formchk BNBO-LAST_tdvert.chk
 Read checkpoint file BNBO-LAST_tdvert.chk type G16
 Write formatted file BNBO-LAST_tdvert.fchk
 Out-of-memory error in routine WrCIDn-1 (IEnd=     129621121 MxCore=     104857162)
 Use %mem=124MW to provide the minimum amount of memory required to complete this step.
 Error termination via Lnk1e at Sat Jun  1 09:34:50 2024.
Error: segmentation violation
```
在询问 GPT 得到回答

> 在使用 formchk 工具转换 Gaussian 生成的二进制检查点文件 (.chk) 为格式化检查点文件 (.fchk) 的过程中遇到 "Out-of-memory error in routine WrCIDn-1" 错误，这是因为 formchk 工具尝试使用的内存超过了你的系统可用内存或当前内存限制。

解决：输入下面代码
```
export GAUSS_MEMDEF=100GB
```
添加到环境变量，成功

#### 2. 使用 orca 的不同泛函计算 ΔEst

对于 orca 输入文件有
```
! RIJCOSX RI-mPW2PLYP def2-SVP def2/J def2-SVP/C TIGHTSCF

# 总体计算设置：
# RIJCOSX: 使用RI-J近似来加速计算交换积分
# RI-mPW2PLYP: 使用mPW2PLYP杂化密度泛函理论与RI近似结合
# def2-SVP: 基组，使用def2-SVP基组进行计算
# def2/J: RI近似的辅助基组
# def2-SVP/C: 密度拟合基组，用于相关计算
# TIGHTSCF: 使用严格的SCF收敛标准，提高计算精度

%tddft
  dcorr 1         # 选择动能修正的方法。dcorr 1 表示使用修正后的交换-相关能量。
  nroots 5        # 计算前 5 个激发态。
  triplets true   # 包括三重态激发态的计算。
  DoNTO true      # 计算自然跃迁轨道 (NTOs)
  NTOStates 1,2,3 # 为前 3 个激发态计算 NTOs。
  NTOThresh 1e-4  # NTOs 的阈值。表示计算 NTO 的贡献超过 1e-4 的激发态。
  tda true        # 使用 Tamm-Dancoff 近似 (TDA)。
  printlevel 3    # 输出详细级别设置为 3，打印较多的计算信息。
end
%mp2 density relaxed  end  # 在 MP2 计算中使用放松后的密度矩阵。
%pal nprocs 40           # 并行计算，使用 40 个处理器核心。
	end
%MaxCore 2560   # 为每个核心分配的最大内存为 2560 MB。
```

将所有双杂化的泛函 列入`~/software/coordmagic/dftlist`
```
qcinp.py -P otddh TQAO-TF.log                                    # 生成 orca 输入文件        
cat ~/software/coordmagic/dftlist                                # 查看所有泛函
for i in $(cat ~/software/coordmagic/dftlist); do echo $i; done  # 循环查看
for i in $(cat ~/software/coordmagic/dftlist); do sed "s/mPW2PLYP/$i/g" TQAO-TF.inp > TQAO-TF-${i}.inp; done  循环替代输入文件中的泛函
```

查看结果，使用命令：`orcaDEst # 已加载到环境变量 ~/software/ztools/orcaDEst`

```
              system  dEst(eV)        S1        T1
   TQAO-TF-B2GP-PLYP     0.337     3.304     2.967
      TQAO-TF-B2PLYP     0.388     3.165     2.777
    TQAO-TF-mPW2PLYP     0.446     3.270     2.824
     TQAO-TF-PBE0-DH     0.646     3.453     2.807
    TQAO-TF-PBE-QIDH     0.437     3.477     3.040
     TQAO-TF-RSX-0DH     0.926     4.073     3.147
    TQAO-TF-RSX-QIDH     0.439     3.854     3.415
TQAO-TF-SCS-B2GP-PLYP21     0.383     3.495     3.112
TQAO-TF-SCS-PBE-QIDH     0.297     3.322     3.025
TQAO-TF-SCS-RSX-QIDH     0.039     3.363     3.324
TQAO-TF-SCS-wB2GP-PLYP     0.098     3.507     3.409
TQAO-TF-SCS-wB88PP86     0.089     3.489     3.400
TQAO-TF-SCS-wPBEPP86    -0.045     3.294     3.339
TQAO-TF-SOS-B2GP-PLYP21     0.361     3.435     3.074
TQAO-TF-SOS-PBE-QIDH     0.279     3.312     3.033
TQAO-TF-SOS-RSX-QIDH    -0.001     3.371     3.372
TQAO-TF-SOS-wB2GP-PLYP     0.119     3.561     3.442
TQAO-TF-SOS-wB88PP86     0.063     3.456     3.393
TQAO-TF-SOS-wPBEPP86    -0.024     3.376     3.400
  TQAO-TF-wB2GP-PLYP     0.279     3.753     3.474
     TQAO-TF-wB2PLYP     0.667     3.807     3.140
    TQAO-TF-wB88PP86     0.039     3.527     3.488
    TQAO-TF-wPBEPP86    -0.072     3.473     3.545
```
根据实验测得 ΔEst 为 0.25 eV,结合计算结果，应该选择 SOS-PBE-QIDH 和 wB2GP-PLYP 为计算基组。

运用嵌套循环，将  SOS-PBE-QIDH 和 wB2GP-PLYP 写入剩下四个分子的文件，将需要的泛函列入 ./dftlist 文件里

```
dos2unix dftlist                                                                                             # 将换行符转换为 Linux 系统下的换行符
for m in *.inp; do for i in $(cat ./dftlist); do sed "s/mPW2PLYP/$i/g" $m > ${m/.inp/}-${i}.inp; done;done   # 嵌套循环，先循环文件，再循环替换泛函
for i in *.inp; do sed "s/mPW2PLYP/SOS-PBE-QIDH/g" $i > ${i/.inp/}_est.inp;done
```

#### 3. 使用 orca 的 PBE0 计算 soc

将 Gaussian 优化的基态 log 文件放入文件夹，使用 qcinp 生成计算 soc 文件
```
mkdir orca_soc 
cp *_tdvert.inp orca_soc/ 
cd orca_soc/

qcinp.py -k "RIJCOSX PBE0 def2-SVP def2/J TIGHTSCF"  -B "%tddft;nroots 5;DoSOC True;TRIPLETS TRUE;tda true;printlevel 3;end" -n 64 -m 150GB -p orca  -A _orcasoc *.log
qcinp.py -P osoc -A _orcasoc*.log
```
输入文件表头
```
! RIJCOSX PBE0 def2-SVP def2/J def2-SVP/C TIGHTSCF
%tddft
nroots 5
dosoc true
triplets true
tda true
printlevel 3
end
%pal nprocs 40
     end
%MaxCore 2560
* xyz 0 1
```
从计算的 out 文件查看结果

![输入图片说明](img/%E5%BE%AE%E4%BF%A1%E6%88%AA%E5%9B%BE_20240601184538.jpg)

计算 SOC 公式
```
<S1|H_SO|T1> = sqrt[2(0.00)**2 + (-0.01)**2 + (-0.12)**2 + (-4.76)**2 + (-0.12)**2+(4.76)**2]
```
也可以使用钟老师编写的脚本进行计算，例如 `orcasoc TQAOD_tdvert.out`
![输入图片说明](img/%E5%BE%AE%E4%BF%A1%E6%88%AA%E5%9B%BE_20240601190804.jpg)

orcasoc 脚本内容
```
awk 'BEGIN{idx=1;printf "%-3s%-3s%12s%12s\n","S","T","soc(cm-1)","S-T(eV)"}{if($0 ~/<T|HSO|S>/) readf=1
if($0 ~/EXCITED STATES \(SINGLETS\)/) {reads=1;getline}
if(reads==1 && $0 ~/\*\*\*\*\*\*/) {reads=0}
if(reads==1 && $0 ~/STATE/) {gsub(":","",$2);sene[$2]=$6}
if($0 ~/EXCITED STATES \(TRIPLETS\)/) {readt=1;getline}
if(readt==1 && $0 ~/\*\*\*\*\*\*/) {readt=0}
if(readt==1 && $0 ~/STATE/) {gsub(":","",$2);tene[$2]=$6}
if(readf==1 && $0 ~/MS=/) {readf=2}
if(readf==2 && $0 ~/-----/) {readf=3;getline}
if(readf==3 && $0 ~/-----/) {readf=0}
if(readf==3 && NF > 2) {
soc=($4^2 + $6^2 + $8^2 + $10^2 + $12^2 + $14^2)^0.5
dest=sene[$2]-tene[$1]
if($2 > 0) {
printf "%-3d%-3d%12.6f%12.6f\n",$2,$1,soc,dest
}
}
}' $1
~
```



