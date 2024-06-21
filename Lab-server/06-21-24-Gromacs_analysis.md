### 1. 计算作用能

```
$ gmx make_ndx -f dmb.pdb -o index.ndx
> h
> a 1 14 15 16 81 90
>  
  0 System              : 61000 atoms
  1 Other               : 61000 atoms
  2 DMB                 :  9000 atoms
  3 MCB                 : 52000 atoms
  4 a_1_14_15_16_81_90  :     6 atoms
> name 4 gro1
> a 19 20 22 24 63 61
> 
  0 System              : 61000 atoms
  1 Other               : 61000 atoms
  2 DMB                 :  9000 atoms
  3 MCB                 : 52000 atoms
  4 gro1                :     6 atoms
  5 a_19_20_22_24_63_61 :     6 atoms
> name 5 gro2

vim prod.mdp
```
加入 `energygrps =gro1 gro2`

然后