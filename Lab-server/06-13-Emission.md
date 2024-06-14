### 1 Orca 计算振动分辨荧光光谱

参考 orca 计算手册 orca_manual_5_0_3.pdf

#### 1. 计算的文件

基态的 opt freq ，激发态的 td opt freq

使用 fchk2hess 脚本将 fchk 文件转换成 .hess 文件（基态、激发态）

编写 orca 计算文件 eg DFBP-CZDABNA.inp
```
! PBE0 def2-SVP TIGHTSCF ESD(FLUOR)      # 计算振动分辨荧光光谱关键词
%TDDFT 
NROOTS 5 
IROOT 1 
END 
%ESD 
GSHESSIAN "DFBP-CZDABNA_freq.hess"        # 基态文件
ESHESSIAN "DFBP-CZDABNA_tdopt_freq.hess"  # 激发态文件
DOHT TRUE 
LINES VOIGT                               # 线形函数
LINEW 75                                  # 单位：cm-1 调整线形状
INLINEW 200                               # 调整线形状
END 
%pal nprocs 40
     end
%MaxCore 2560
* xyz 0 1
# 基态坐标
*
```
1. 线形函数：ELTA（用于 Dirac delta）、LORENTZ（默认）、GAUSS（用于高斯）和 VOIGT（高斯和洛伦兹的乘积）
2. 如果要分别控制 GAUSS 和 LORENTZ 的线形，可以为 Lorenztian 设置 LINEW，为 Gaussian 设置 INLINEW（"I "表示非均质线宽）
3. LINEW 和 INLINEW 并不是这些曲线的全宽半最大值 (FWHM)。不过，它们之间的关系如下 FWHM_lorentz = 2 × LINEW 和 FWHM_gauss = 2.355 × INLINEW
4. 总的半峰宽 FWHM_voigt ![公式](img/%E5%BE%AE%E4%BF%A1%E6%88%AA%E5%9B%BE_20240613174452.png)

使用 orcas 命令提交任务，计算 17 个小时后得到计算结果

#### 1.2 结果处理
计算得到 DFBP-CZDABNA.spectrum 文件，第一列是波数 （cm-1）需要转成 nm 第二列是 TotalSpectrum，使用 origin 作图有
![计算得到的光谱](img/%E5%BE%AE%E4%BF%A1%E6%88%AA%E5%9B%BE_20240613173230.jpg)

#### 1.3 使用近似方法计算

最简单模型，垂直梯度 VG : 

```
! PBE0 def2-SVP TIGHTSCF ESD(FLUOR) 
%TDDFT 
NROOTS 5 
IROOT 1 
END 
%ESD 
GSHESSIAN "DFBP-CZDABNA_freq.hess" 
ESHESSIAN "DFBP-CZDABNA_tdopt_freq.hess" 
DOHT TRUE 
HESSFLAG AHAS
LINES VOIGT 
LINEW 75 
INLINEW 100
END 
%pal nprocs 40
     end
%MaxCore 2560
* xyz 0 1
基态坐标
*
```
一个更好的模型，即 "一步之后的绝热赫赛斯 "模型 AHAS : 
```
! PBE0 def2-SVP TIGHTSCF ESD(FLUOR) 
%TDDFT 
NROOTS 5 
IROOT 1 
END 
%ESD 
GSHESSIAN "DFBP-CZDABNA_freq.hess" 
ESHESSIAN "DFBP-CZDABNA_tdopt_freq.hess" 
DOHT TRUE 
HESSFLAG AHAS
LINES VOIGT 
LINEW 75 
INLINEW 100
END 
%pal nprocs 40
     end
%MaxCore 2560
* xyz 0 1
基态的坐标
*
```

### 2. 使用 Fcclasses3 计算发射光谱

参考 Fcclasses3 手册：FCclasses3_tutorial.pdf
参考文件：/home/jzq/software/fcclasses3-3.0.3/tests/properties/EMI/TD/VH

#### 2.1 计算文件

基态的 opt freq ，激发态的 td opt freq

使用 gen_fcc_state -i *.fchk 命令将 fchk 文件转换成 .fcc 文件（基态、激发态）
使用 gen_fcc_dipfile -i *.fchk 命令将 fchk 文件转换成 .fcc 文件（基态、激发态）

编写计算文件
```
$$$
PROPERTY     =   EMI  ; OPA/EMI/ECD/CPL/RR/TPA/MCD/IC
MODEL        =   AH   ; AS/ASF/AH/VG/VGF/VH
DIPOLE       =   FC   ; FC/HTi/HTf
TEMP         =   298.15 ; (temperature in K) 
BROADFUN     =   GAU  ; GAU/LOR/VOI
HWHM         =   0.2 ; (broadening width in eV)
METHOD       =   TD   ; TI/TD
;VIBRATIONAL ANALYSIS 
NORMALMODES  =   COMPUTE   ; COMPUTE/READ/IMPLICIT
COORDS       =   CARTESIAN ; CARTESIAN/INTERNAL
;INPUT DATA FILES 
STATE1_FILE  =   DFBP-CZDABNA_tdopt_freq.fcc           # 始态 s1
STATE2_FILE  =   DFBP-CZDABNA_freq.fcc                 # 末态 s0
ELDIP_FILE   =   eldip_DFBP-CZDABNA_tdopt_freq_fchk    # s1 的偶极子文件

SPCMIN = 0         ; 光谱范围 eV
SPCMAX = 5
```
更改 MODEL 可以计算不同的近似情况

#### 2.2 结果处理

将 Clas_spectrum_Wigner_shape.dat 和 Clas_spectrum_Boltzmann_shape.dat 转入 origin 作图

横坐标是 eV 需要转为 nm 
![输入图片说明](img/%E5%BE%AE%E4%BF%A1%E6%88%AA%E5%9B%BE_20240613185400.png)

