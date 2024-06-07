#!/bin/env python
import numpy as np
import argparse
import os
import re
import math

parser = argparse.ArgumentParser(description="需要计算SOC、ΔE(st)、T、fcclasses.out和HuangRhys.dat")
parser.add_argument("NAC",type=float, help="SOC/NAC：cm-1")
parser.add_argument("delta",type=float, help="ΔEst/ΔG：eV")
parser.add_argument("T",default=298.15,type=float, help="温度：K")

args = parser.parse_args()

# 将文件名分别赋值给不同的变量
NAC_cm = args.NAC   # 变量 1 SOC
ΔG = args.delta     # 变量 2 ΔEst
T = args.T          # 变量 3 温度

# 读取文件

HRindexfile = "HuangRhys.dat"
Fccfile = "fcclasses.out"

def ReadHRindex(HRindexfile):
    print(f"reading ReadHRindex:{HRindexfile}")
    HRindex = []
    slag = 0
    # snumber = 0
    # mnumber = 0
    # RH = open(path + filename, 'r', encoding='utf8')
    RH = open(HRindexfile, 'r', encoding='utf8')
    for line in RH:
        if 'Huang-Rhys' in line:
            slag = 1
            continue
        if slag == 1 and len(line.strip().split()) ==2:
            # snumber = int(line.strip().split()[0])
            # print(snumber)
            # #line_save = line.split(' ')
            # #line_save = [string.replace('\n', '') for string in line_save]
            # # if snumber > mnumber:
            #     print(line.strip().split())
            HRindex.append(line.strip().split()[-1])
            #     mnumber = snumber
            # else:
            #     flag = 0 
    RH.close()
    return HRindex
if not os.path.isfile(HRindexfile):
    print(f"File {HRindexfile} does not exist.")
else:
    arrHRindex = np.array(ReadHRindex(HRindexfile))

def Readfreq(Fccfile):
    print(f"reading Readfcc.out:{Fccfile}")
    pattern = r'------------------------\s+FREQUENCIES \(cm-1\)\s+------------------------\s+((?:\s*\d+\s+\d+\.\d+\s*)+)\s+------------------------'
    FR = open(Fccfile, 'r', encoding='utf8')
    content = FR.read()
    matches = re.findall(pattern, content)
    all_frequencies = []
    for match in matches:
        frequencies = re.findall(r'\d+\s+(\d+\.\d+)', match)
        all_frequencies.append(frequencies)
    return all_frequencies

arrfrequencies = np.array(Readfreq(Fccfile)).astype(np.float32)

# 计算重组能/λ

Harrf = arrfrequencies[0,arrfrequencies[0]>=400]
HarrHR = arrHRindex[arrfrequencies[0]>=400].astype(np.float32)
Larrf = arrfrequencies[0,arrfrequencies[0]<400] 
LarrHR = arrHRindex[arrfrequencies[0]<400].astype(np.float32) 

λM = np.sum(LarrHR*(Larrf*29979245800*6.6260696E-34)*219474.6363/2625500*6.02214179E+23*1.98644586E-23/1.602176634E-19)

# 计算 w_eff

w_eff = np.sum(Harrf*HarrHR)/np.sum(HarrHR)

# 计算 H-R-Index

S = np.sum(HarrHR)

# 计算 krisc 方程

def marcus_rate(NAC,NAC_cm, λM, ΔG, w_eff, S, T):
    """
    计算 Marcus 速率常数
    参数:
    NAC (eV): 非绝热耦合
    λM (eV): 重组能量
    ΔG (eV): 自由能变化
    ω_eff (cm^-1): 有效振动频率
    S (无单位): Huang-Rhys 因子
    T (K): 温度

    返回:
    kT_Marcus (s^-1): Marcus 速率常数
    """
    # 常量
    h = 4.135667696e-15  # eV·s (普朗克常数)
    kb = 8.617333262145e-5  # eV/K (玻尔兹曼常数)
    ħ = h / (2 * np.pi)  # eV·s (约化普朗克常数)
    
    # 计算 Marcus 速率常数
    factor1 = (np.pi / ħ) * (NAC**2)
    factor2 = 1 / np.sqrt(np.pi * λM * kb * T)
    sum_term = 0
    for n in range(100):  # 使用有限项求和近似
        exp_term = np.exp(-S) * (S ** n) / math.factorial(n)
        exponent = -((ΔG + λM + n * ħ * w_eff * 29979245800) ** 2) / (4 * λM * kb * T)
        sum_term += exp_term * np.exp(exponent)
    
    kT_Marcus = factor1 * factor2 * sum_term
    print(factor1) 
    print(factor2) 
    print(sum_term) 
    return kT_Marcus

NAC = NAC_cm*1.239841E-4  # SOC / eV

print(f'SOC_eV: {NAC}')
print(f"λM_CM-1: {λM}")
print(f"ΔG_eV: {ΔG}")
print(f"w_eff_cm-1: {w_eff}")
print(f"H-R-Index: {S}")
print(f"K: {T}")

# 计算 Marcus 速率常数
rate_constant = marcus_rate(NAC,NAC_cm, λM, ΔG, w_eff, S, T)
print(f"Marcus 速率常数: {rate_constant:.4e} s^-1")
