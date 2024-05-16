### 1. 激发态计算
#### 1.1 激发态分类

1. 垂直激发态：相对于基态（opt）构型保持不变（并未发生 振动弛豫/重组，计算关键词：td ）
2. 绝热激发态：由于 振动弛豫/重组 相对于基态发生构型变化 （由高能级激发态转到激发态的最低能级，计算关键词：opt-td）
3. 同理，s1 构型下的 s0 基态 与 绝热激发态的构型相同，发生重组后又会回到开始的基态构型

#### 1.2 绝热激发态计算

须在基态构型优化结果下进行计算

```
qcinp.py -a td -A _tdopt *.log
mkdir tdopt
mv *_tdopt.gjf tdopt/
cd tdopt/
head *_tdopt.gjf
g16s *.gjf 
```
#### 1.3 垂直激发态计算

须在基态构型优化结果下进行计算

删除优化命令（opt），添加激发态命令（td）

一并计算 SOC ，没有优化命令，计算较快

```
qcinp.py -a td -r opt -A _tdvert *.log
mkdir td_vert
 mv *_tdvert.gjf td_vert/
cd td_vert/
qcinp.py -P soc *.gjf
vim TSSQ_tdvert.gjf
g16s *.gjf
```

### 2. 定义新命令


```
vim ~/.basharc
alias sq='squeue -o "%8i %20j %4C %3t %30R %M %Z"'   # 定义 sq 为新命令，代替 squeue 且更高级
alias si='sinfo -N -o "%10N %15C %10O %10e %T"'      # 定义 si 为新命令，代替 sinfo 且更高级
source ~/.bashrc
```

