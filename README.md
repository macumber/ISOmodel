README
======

This is the README for the isomodel (monthly and hourly) building energy model project. 

### How do I get set up? ###

See IsoModel/COMPILING.txt for details on how to compile the code.

Monthly vs Hourly
-----------------

Notes on the current differences between the monthly and hourly simulations. In
general, the monthly simulation is considered to be "correct" and the goal is
to bring the hourly simulation in line with its results, but this is not always
the case. The goal is for the monthly and hourly simulations to produce
relatively consistent results, except in cases where the hourly model is better
able to express the property being studied (e.g., hourly occupancy schedules,
thermal mass, etc.).

### ElecHeat ###

**Untested** - Electric heating is untested, but presumably consistent because it's values
shouldn't differ from gas heating.

| Month | Monthly ElecHeat      | Hourly ElecHeat      | Difference    |
|-------|-----------------------|----------------------|---------------|
| 0     | 0                     | 0                    | 0             |
| 1     | 0                     | 0                    | 0             |
| 2     | 0                     | 0                    | 0             |
| 3     | 0                     | 0                    | 0             |
| 4     | 0                     | 0                    | 0             |
| 5     | 0                     | 0                    | 0             |
| 6     | 0                     | 0                    | 0             |
| 7     | 0                     | 0                    | 0             |
| 8     | 0                     | 0                    | 0             |
| 9     | 0                     | 0                    | 0             |
| 10    | 0                     | 0                    | 0             |
| 11    | 0                     | 0                    | 0             |

### ElecCool ###

**Consistent** - Cooling results are fairly consistent across monthly and hourly simulations.

| Month | Monthly ElecCool      | Hourly ElecCool      | Difference    |
|-------|-----------------------|----------------------|---------------|
| 0     | 0.0231166             | 0                    | 0.0231166     |
| 1     | 0.045225              | 0                    | 0.045225      |
| 2     | 0.135984              | 0                    | 0.135984      |
| 3     | 0.341924              | 0.741856             | -0.399932     |
| 4     | 1.08367               | 1.44067              | -0.357001     |
| 5     | 2.12931               | 2.99811              | -0.868803     |
| 6     | 3.28741               | 4.32944              | -1.04203      |
| 7     | 1.79919               | 2.51963              | -0.720442     |
| 8     | 0.758612              | 1.17443              | -0.415823     |
| 9     | 0.180504              | 0.0484588            | 0.132045      |
| 10    | 0.0404312             | 0                    | 0.0404312     |
| 11    | 0.0185314             | 0                    | 0.0185314     |

### ElecIntLights ###

**Consistent** - After commit #3124f63, monthly and hourly interior lighting results are
consistent.

| Month | Monthly ElecIntLights | Hourly ElecIntLights | Difference |
|-------|-----------------------|----------------------|------------|
| 0     | 2.721                 | 2.74978              | -0.0287845 |
| 1     | 2.45768               | 2.48852              | -0.0308406 |
| 2     | 2.721                 | 2.78731              | -0.0663075 |
| 3     | 2.63322               | 2.61266              | 0.0205609  |
| 4     | 2.721                 | 2.78731              | -0.0663075 |
| 5     | 2.63322               | 2.68771              | -0.0544852 |
| 6     | 2.721                 | 2.71226              | 0.00873865 |
| 7     | 2.721                 | 2.78731              | -0.0663075 |
| 8     | 2.63322               | 2.65019              | -0.0169621 |
| 9     | 2.721                 | 2.74978              | -0.0287845 |
| 10    | 2.63322               | 2.68771              | -0.0544853 |
| 11    | 2.721                 | 2.71226              | 0.00873855 |

### ElecExtLights ###

**Consistent** - Exterior lighting is consistent.

| Month | Monthly ElecExtLights | Hourly ElecExtLights | Difference    |
|-------|-----------------------|----------------------|---------------|
| 0     | 0.257822              | 0.257822             | -2.38698e-015 |
| 1     | 0.199604              | 0.207327             | -0.00772279   |
| 2     | 0.184159              | 0.210892             | -0.0267327    |
| 3     | 0.178218              | 0.198416             | -0.0201981    |
| 4     | 0.147327              | 0.159208             | -0.0118812    |
| 5     | 0.142575              | 0.142575             | -2.77556e-017 |
| 6     | 0.147327              | 0.148515             | -0.00118812   |
| 7     | 0.147327              | 0.178218             | -0.0308912    |
| 8     | 0.178218              | 0.189505             | -0.0112872    |
| 9     | 0.202575              | 0.226931             | -0.0243565    |
| 10    | 0.231684              | 0.236436             | -0.00475249   |
| 11    | 0.257822              | 0.258416             | -0.000594061  |

### ElecFans ###

**Consistent** - Since fixing issue #44, fan results are consistent.

| Month | Monthly ElecFans | Hourly ElecFans | Difference |
|-------|------------------|-----------------|------------|
| 0     | 7.4786           | 7.37921         | 0.0993913  |
| 1     | 6.05336          | 5.89016         | 0.163193   |
| 2     | 4.72618          | 4.32213         | 0.404055   |
| 3     | 2.71281          | 2.91157         | -0.198757  |
| 4     | 1.40998          | 1.62994         | -0.21996   |
| 5     | 0.837238         | 1.33239         | -0.495154  |
| 6     | 1.13737          | 1.54446         | -0.40709   |
| 7     | 0.688762         | 1.05728         | -0.368518  |
| 8     | 0.875118         | 1.08809         | -0.212968  |
| 9     | 2.76048          | 2.33905         | 0.421437   |
| 10    | 4.68014          | 4.37653         | 0.303617   |
| 11    | 7.17145          | 7.12741         | 0.0440359  |

### ElecPump ###

**Inconsistent** - Issue #43. Pump results are not consistent. Both fan and pump values differ the most in
the winter. Their is potentially an error in the monthly pump values.

| Month | Monthly ElecPump      | Hourly ElecPump      | Difference    |
|-------|-----------------------|----------------------|---------------|
| 0     | 0.808168              | 0.186                | 0.622168      |
| 1     | 0.654151              | 0.168                | 0.486151      |
| 2     | 0.510731              | 0.17725              | 0.333481      |
| 3     | 0.293157              | 0.1535               | 0.139657      |
| 4     | 0.152368              | 0.142                | 0.0103682     |
| 5     | 0.0904754             | 0.124                | -0.0335246    |
| 6     | 0.122909              | 0.12                 | 0.00290898    |
| 7     | 0.0744305             | 0.11275              | -0.0383195    |
| 8     | 0.0945689             | 0.122                | -0.0274311    |
| 9     | 0.298309              | 0.16225              | 0.136059      |
| 10    | 0.505756              | 0.1735               | 0.332256      |
| 11    | 0.774976              | 0.186                | 0.588976      |

### ElecEquipInt ###

**Consistent** - Issue #45 fixed.

| Month | Monthly ElecEquipInt | Hourly ElecEquipInt | Difference   |
|-------|----------------------|---------------------|--------------|
| 0     | 2.24457              | 2.24088             | 0.00368978   |
| 1     | 2.02735              | 2.02735             | 1.86517e-014 |
| 2     | 2.24457              | 2.26671             | -0.0221387   |
| 3     | 2.17216              | 2.13526             | 0.0368978    |
| 4     | 2.24457              | 2.26671             | -0.0221387   |
| 5     | 2.17216              | 2.18692             | -0.0147591   |
| 6     | 2.24457              | 2.21505             | 0.0295182    |
| 7     | 2.24457              | 2.26671             | -0.0221387   |
| 8     | 2.17216              | 2.16109             | 0.0110693    |
| 9     | 2.24457              | 2.24088             | 0.00368978   |
| 10    | 2.17216              | 2.18692             | -0.0147591   |
| 11    | 2.24457              | 2.21505             | 0.0295182    |

### ElecEquipExt ###

**Untested** - Exterior equipment defaults to zero at the moment, so it is untested.

| Month | Monthly ElecEquipExt  | Hourly ElecEquipExt  | Difference    |
|-------|-----------------------|----------------------|---------------|
| 0     | 0                     | 0                    | 0             |
| 1     | 0                     | 0                    | 0             |
| 2     | 0                     | 0                    | 0             |
| 3     | 0                     | 0                    | 0             |
| 4     | 0                     | 0                    | 0             |
| 5     | 0                     | 0                    | 0             |
| 6     | 0                     | 0                    | 0             |
| 7     | 0                     | 0                    | 0             |
| 8     | 0                     | 0                    | 0             |
| 9     | 0                     | 0                    | 0             |
| 10    | 0                     | 0                    | 0             |
| 11    | 0                     | 0                    | 0             |

### ElectDHW ###

**Untested** - Electric hot water defaults to zero at the moment, so it is untested.

| Month | Monthly ElectDHW      | Hourly ElectDHW      | Difference    |
|-------|-----------------------|----------------------|---------------|
| 0     | 0                     | 0                    | 0             |
| 1     | 0                     | 0                    | 0             |
| 2     | 0                     | 0                    | 0             |
| 3     | 0                     | 0                    | 0             |
| 4     | 0                     | 0                    | 0             |
| 5     | 0                     | 0                    | 0             |
| 6     | 0                     | 0                    | 0             |
| 7     | 0                     | 0                    | 0             |
| 8     | 0                     | 0                    | 0             |
| 9     | 0                     | 0                    | 0             |
| 10    | 0                     | 0                    | 0             |
| 11    | 0                     | 0                    | 0             |

### GasHeat ###

**Consistent** - Gas heat is consistent.

| Month | Monthly GasHeat       | Hourly GasHeat       | Difference    |
|-------|-----------------------|----------------------|---------------|
| 0     | 42.5212               | 42.273               | 0.248254      |
| 1     | 34.3655               | 33.7567              | 0.6088        |
| 2     | 26.6327               | 24.7907              | 1.84207       |
| 3     | 14.7675               | 15.2197              | -0.452203     |
| 4     | 5.89133               | 6.42497              | -0.533637     |
| 5     | 0.572288              | 1.74543              | -1.17314      |
| 6     | 0                     | 0.413635             | -0.413635     |
| 7     | 0.377265              | 1.04708              | -0.669814     |
| 8     | 3.48712               | 3.8084               | -0.321284     |
| 9     | 15.3567               | 13.2781              | 2.0786        |
| 10    | 26.5589               | 25.1073              | 1.45152       |
| 11    | 40.782                | 40.8199              | -0.0379359    |

### GasCool ###

**Untested** - Gas cooling is untested, but presumably equally consistant to electric cooling,
as the fuel source shouldn't change the calculations.

| Month | Monthly GasCool       | Hourly GasCool       | Difference    |
|-------|-----------------------|----------------------|---------------|
| 0     | 0                     | 0                    | 0             |
| 1     | 0                     | 0                    | 0             |
| 2     | 0                     | 0                    | 0             |
| 3     | 0                     | 0                    | 0             |
| 4     | 0                     | 0                    | 0             |
| 5     | 0                     | 0                    | 0             |
| 6     | 0                     | 0                    | 0             |
| 7     | 0                     | 0                    | 0             |
| 8     | 0                     | 0                    | 0             |
| 9     | 0                     | 0                    | 0             |
| 10    | 0                     | 0                    | 0             |
| 11    | 0                     | 0                    | 0             |

### GasEquip ###

**Untested** - Gas equipment is untested.

| Month | Monthly GasEquip      | Hourly GasEquip      | Difference    |
|-------|-----------------------|----------------------|---------------|
| 0     | 0                     | 0                    | 0             |
| 1     | 0                     | 0                    | 0             |
| 2     | 0                     | 0                    | 0             |
| 3     | 0                     | 0                    | 0             |
| 4     | 0                     | 0                    | 0             |
| 5     | 0                     | 0                    | 0             |
| 6     | 0                     | 0                    | 0             |
| 7     | 0                     | 0                    | 0             |
| 8     | 0                     | 0                    | 0             |
| 9     | 0                     | 0                    | 0             |
| 10    | 0                     | 0                    | 0             |
| 11    | 0                     | 0                    | 0             |

### GasDHW ###

**Untested** - Gas hot water defaults to zero, so is currently untested.

| Month | Monthly GasDHW        | Hourly GasDHW        | Difference    |
|-------|-----------------------|----------------------|---------------|
| 0     | 0                     | 0                    | 0             |
| 1     | 0                     | 0                    | 0             |
| 2     | 0                     | 0                    | 0             |
| 3     | 0                     | 0                    | 0             |
| 4     | 0                     | 0                    | 0             |
| 5     | 0                     | 0                    | 0             |
| 6     | 0                     | 0                    | 0             |
| 7     | 0                     | 0                    | 0             |
| 8     | 0                     | 0                    | 0             |
| 9     | 0                     | 0                    | 0             |
| 10    | 0                     | 0                    | 0             |
| 11    | 0                     | 0                    | 0             |
