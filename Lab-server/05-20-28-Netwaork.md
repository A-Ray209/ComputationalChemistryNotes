### 1. 更换局域网

主机连接显示器

用 root 登录，密码 jzq+手机号，登录终端
```

```

### 2. 定义计算 orca ΔEst 命令

orcas_est.sh 放置于 ztools 文件夹下（环境变量）

脚本内容：

```
#!/bin/bash

# Loop through all .out files not starting with "slurm"
for file in $(ls *.out | grep -v '^slurm'); do
  
  # Find the keyword, get the 5th line after it, and then print the 6th column of that line
  s1=$(grep -A 5 "EXCITED STATES (SINGLETS)" "$file" | awk 'NR==6 {print $6}')
  t1=$(grep -A 5 "EXCITED STATES (TRIPLETS)" "$file" | awk 'NR==6 {print $6}')
  orcas_est=`echo "($s1 - $t1)" | bc`
  echo "orcas_est $file = $orcas_est"
done
```
