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

然后 `gmx grompp -f prod.mdp -c prod.gro -n index.ndx   -p topol.top -o prod.tpr -maxwarn 1`

运行`gmx mdrun -s prod.tpr  -rerun prod.xtc`
```
$ gmx energy -f ener.edr
Command line:
  gmx energy -f ener.edr

Opened ener.edr as single precision energy file

Select the terms you want from the following list by
selecting either (part of) the name or the number or a combination.
End your selection with an empty line or a zero.
-------------------------------------------------------------------
  1  Bond             2  Angle            3  Proper-Dih.      4  Per.-Imp.-Dih.
  5  LJ-14            6  Coulomb-14       7  LJ-(SR)          8  Coulomb-(SR)
  9  Coul.-recip.                        10  Potential
 11  Coul-SR:gro1-gro1                   12  LJ-SR:gro1-gro1
 13  Coul-14:gro1-gro1                   14  LJ-14:gro1-gro1
 15  Coul-SR:gro1-gro2                   16  LJ-SR:gro1-gro2
 17  Coul-14:gro1-gro2                   18  LJ-14:gro1-gro2
 19  Coul-SR:gro1-rest                   20  LJ-SR:gro1-rest
 21  Coul-14:gro1-rest                   22  LJ-14:gro1-rest
 23  Coul-SR:gro2-gro2                   24  LJ-SR:gro2-gro2
 25  Coul-14:gro2-gro2                   26  LJ-14:gro2-gro2
 27  Coul-SR:gro2-rest                   28  LJ-SR:gro2-rest
 29  Coul-14:gro2-rest                   30  LJ-14:gro2-rest
 31  Coul-SR:rest-rest                   32  LJ-SR:rest-rest
 33  Coul-14:rest-rest                   34  LJ-14:rest-rest

15


Back Off! I just backed up energy.xvg to ./#energy.xvg.1#
Last energy frame read 100 time 20000.000

Statistics over 10000001 steps [ 0.0000 through 20000.0000 ps ], 1 data sets
All statistics are over 101 points (frames)

Energy                      Average   Err.Est.       RMSD  Tot-Drift
-------------------------------------------------------------------------------
Coul-SR:gro1-gro2           106.091       0.15    2.50604   0.012175  (kJ/mol)

GROMACS reminds you: "Step Aside, Butch" (Pulp Fiction)

(base) [jzq@node01 MD_DMB]$ gmx energy -f ener.edr
                      :-) GROMACS - gmx energy, 2023.3 (-:

Executable:   /home/zc/software/program/gromacs-2023.3/bin/gmx
Data prefix:  /home/zc/software/program/gromacs-2023.3
Working dir:  /home/jzq/lrh/mCBP/MD_DMB
Command line:
  gmx energy -f ener.edr

Opened ener.edr as single precision energy file

Select the terms you want from the following list by
selecting either (part of) the name or the number or a combination.
End your selection with an empty line or a zero.
-------------------------------------------------------------------
  1  Bond             2  Angle            3  Proper-Dih.      4  Per.-Imp.-Dih.
  5  LJ-14            6  Coulomb-14       7  LJ-(SR)          8  Coulomb-(SR)
  9  Coul.-recip.                        10  Potential
 11  Coul-SR:gro1-gro1                   12  LJ-SR:gro1-gro1
 13  Coul-14:gro1-gro1                   14  LJ-14:gro1-gro1
 15  Coul-SR:gro1-gro2                   16  LJ-SR:gro1-gro2
 17  Coul-14:gro1-gro2                   18  LJ-14:gro1-gro2
 19  Coul-SR:gro1-rest                   20  LJ-SR:gro1-rest
 21  Coul-14:gro1-rest                   22  LJ-14:gro1-rest
 23  Coul-SR:gro2-gro2                   24  LJ-SR:gro2-gro2
 25  Coul-14:gro2-gro2                   26  LJ-14:gro2-gro2
 27  Coul-SR:gro2-rest                   28  LJ-SR:gro2-rest
 29  Coul-14:gro2-rest                   30  LJ-14:gro2-rest
 31  Coul-SR:rest-rest                   32  LJ-SR:rest-rest
 33  Coul-14:rest-rest                   34  LJ-14:rest-rest

16


Back Off! I just backed up energy.xvg to ./#energy.xvg.2#
Last energy frame read 100 time 20000.000

Statistics over 10000001 steps [ 0.0000 through 20000.0000 ps ], 1 data sets
All statistics are over 101 points (frames)

Energy                      Average   Err.Est.       RMSD  Tot-Drift
-------------------------------------------------------------------------------
LJ-SR:gro1-gro2            -7.73054       0.17    1.34642  -0.745969  (kJ/mol)

GROMACS reminds you: "I'm Gonna Get Medieval On Your Ass" (Pulp Fiction)
```