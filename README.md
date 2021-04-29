# Ploto
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself.
Basically spawns Plots. 

Way dumber than plotman. Still does what it should for all those Windows Farmers out there.

### PlotoSpawn
* [Get-PlotoOutDrives](https://github.com/tydeno/Ploto/blob/main/README.md#get-plotooutdrives)
* [Get-PlotoTempDrives](https://github.com/tydeno/Ploto/blob/main/README.md#get-plototempdrives)
* [Invoke-PlotoJob](https://github.com/tydeno/Ploto/blob/main/README.md#invoke-plotojob)
* [Start-PlotoSpawns](https://github.com/tydeno/Ploto/blob/main/README.md#start-plotospawns)

### PlotoManage
* [Get-PlotoJobs](https://github.com/tydeno/Ploto/blob/main/README.md#get-plotooutdrives)
* [Stop-PlotoJob](https://github.com/tydeno/Ploto/blob/main/README.md#get-plototempdrives)

### PlotoMove - Work in progress
* [Get-PlotoPlots](https://github.com/tydeno/Ploto/blob/main/README.md#get-plotoplots)
* [Move-PlotoPlots](https://github.com/tydeno/Ploto/blob/main/README.md#move-plotoplots)

# PlotoSpawn
TLDR: It plots 1x plot on each TempDrive (if you have 6x TempDrives = 6x parallel Plot Jobs) as long as you want it to and as long as you have OutDrive space.

Ploto checks periodically, if a TempDrive and OutDrive is available for plotting. 
If there is no TempDrive available, or no OutDrive, Ploto checks again in 300 seconds.

When there is one available, Ploto determines the best OutDrive (most free space) and calls chia.exe to start the plot.
Ploto iterates once through all available TempDrives and spawns a plot per each TempDrive (as long as enough OutDrive space is given).
After that, Ploto checks if amount Spawned is equal as defined as input. If not, Ploto keeps going until it is.

You can specify several vital parameters to control when and where plots are spawned, temped and stored. 
PlotoSpawner identifies your drives for temping and storing plots by a common denominator you specify. 

For reference heres my setup:
* CPU: i9-9900k
* RAM: 32 GB DDR4
* GPU: RTX 3080 (refernecing cause its worth to note that I mine eth next to plotting on that machine)
* TempDrives:

| Name          | DriveLetter | Type   | Size      |
|---------------|----------|--------|--------------|
|ChiaPlot 1 | I:\ | SATA SSD | 465 GB
|ChiaPlot 2 | H:\ | SATA SSD | 465 GB
|ChiaPlot 3 | E:\ | SATA SSD | 465 GB
|ChiaPlot 4 | Q:\ | SATA SSD | 1810 GB
|ChiaPlot 5 | J:\ | NVME SSD PCI 16x | 465 GB

* OutDrives:

| Name          | DriveLetter | Type   | Size      |
|---------------|----------|--------|--------------|
|ChiaOut 1 | K:\ | SATA HDD | 465 GB
|ChiaOut 2 | D:\ | SATA HDD | 465 GB

So my denominators for my TempDrives its "plot" and for my destination drives its "out".

By default, Ploto spawns only 1x Plot Job on each Disk in parallel. So when I launch Ploto with default amount to spawn:
```powershell
Start-PlotoSpawns -InputAmountToSpawn 36 -OutDriveDenom "out" -TempDriveDenom "plot" -EnableBitfield $false -ParallelAmount default -WaitTimeBetweenPlotOnSeparateDisks 30 -WaitTimeBetweenPlotOnSameDisk 60
```

the following will happen:
If there is enough free space on the temp and out drive, Ploto spawns 1x job on each disk with the specified wait time between jobs. For each job, it calculates the mot suitable out drive anew, being aware of the plot jobs in progress on that disk. So it should not allow over commiting of temp and or out drives.

If I launch PlotoSpawner with max Parallel Amount param like this:
```powershell
Start-PlotoSpawns -InputAmountToSpawn 36 -OutDriveDenom "out" -TempDriveDenom "plot" -EnableBitfield $false -ParallelAmount max -WaitTimeBetweenPlotOnSeparateDisks 30 -WaitTimeBetweenPlotOnSameDisk 60
```

PlotoSpawner will max out the available temp drives. This means for my temp drive setup the following:
| Name          | DriveLetter | Type   | Size      | Total Plots in parallel |
|---------------|----------|--------|--------------|-------------------------|
|ChiaPlot 1 | I:\ | SATA SSD | 465 GB | 1
|ChiaPlot 2 | H:\ | SATA SSD | 465 GB | 1
|ChiaPlot 3 | E:\ | SATA SSD | 465 GB | 1
|ChiaPlot 4 | Q:\ | SATA SSD | 1810 GB | 5
|ChiaPlot 5 | J:\ | NVME SSD PCI 16x | 465 GB | 1

So there will be 9x Plot jobs running in parallel with defined wait time in minutes betwen jobs on each disk.

When a job is done and a temp drive becomes available again, PlotoSpawner will spawn the next jobs, until it has spawned the amount you specified as -InputAmountToSpawn

PlotoSpawner redirects the output of chia.exe to to the following path: 
* C:\Users\me\.chia\mainnet\plotter

And creates a log for each job with the following notation:
* PlotoSpawnerLog_29_4_15_26_Tmp-H_Out-D.txt


# Prereqs
The following prereqs need to be met in order for Ploto to function properly:
* chia.exe is installed 
* You may need to change PowerShell Execution Policy to allow the script to be imported.

You can do it by using Set-ExecutionPolicy like this:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```


## Get-PlotoOutDrives
Gets all Windows Volumes that match the -OutDriveDenom parameter and checks if free space is greater than 107 GB (amount currently used by final chia plots).
It wraps all the needed information of the volume like DriveLetter, ChiaDriveType, VolumeName, a bool IsPlootable, and the calculated amount of plots to hold into a object and returns the collection of objects as the result of that function.

#### Example:

```powershell
Get-PlotoOutDrives -OutDriveDenom "out"
```

#### Output:

```
DriveLetter         : D:
ChiaDriveType       : Out
VolumeName          : ChiaOut2
FreeSpace           : 363.12
IsPlottable         : True
AmountOfPlotsToHold : 3

DriveLetter         : K:
ChiaDriveType       : Out
VolumeName          : ChiaOut3
FreeSpace           : 364.24
IsPlottable         : True
AmountOfPlotsToHold : 3
```

#### Parameters:
| Name          | Required | Type   | Description                                                                                                                              |
|---------------|----------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
|OutDriveDenom  | Yes      | String | A common denominator for all your drives used as out drives. All drives with that denom in name will be used to store done plots.



## Get-PlotoTempDrives
Gets all Windows Volumes that match the -TempDriveDenom parameter and checks if free space is greater than 270 GB (amount currently used by chia plots as temp storage).
It wraps all the needed information of the volume like DriveLetter, ChiaDriveType, VolumeName, a bool IsPlootable, and the calculated amount of plots to temp, whether it has a plot in porgress (determined by checking if the drive contains any file) into a object and returns the collection of objects as the result of that function.

#### Example:

```powershell
 Get-PlotoTempDrives -TempDriveDenom "plot"
```
#### Output:

```
DriveLetter             : J:
ChiaDriveType           : Temp
VolumeName              : ChiaPlot 5 NVME 980 Pro
FreeSpace               : 361.62
TotalSpace              : 465.75
IsPlottable             : False
AmountOfPlotsToTempMax  : 0
HasPlotInProgress       : True
AmountOfPlotsInProgress : 1
PlotInProgressName      : {plot-k32-2021-04-29-02-37-d9357f04bf93860757e611003228351b050c23d84c4813def7a87ced03e26bf3}

DriveLetter             : Q:
ChiaDriveType           : Temp
VolumeName              : ChiaPlot 4 2TB SSD
FreeSpace               : 678.18
TotalSpace              : 1863
IsPlottable             : False
AmountOfPlotsToTempMax  : -2
HasPlotInProgress       : True
AmountOfPlotsInProgress : 4
PlotInProgressName      : {plot-k32-2021-04-28-14-24-120fc317c4a837d79550b7c16c1faccc101f75aaeeb4fd526c67025b7cedf543,
                          plot-k32-2021-04-28-14-44-4cec8c5141115d41263c5148f0bec5345bdbfe6fe7ede5b8e3c950517cd91601,
                          plot-k32-2021-04-28-15-04-f93405d93b3811085fd4ede4a22b0c349a042bd1d39b7b67b2582cade2d7bf0f,
                          plot-k32-2021-04-28-15-24-b0bc562f8e90d18110f9dce50bb394ede3425970a1ddf27dd498bc65ee42e2b1}
                          
DriveLetter             : E:
ChiaDriveType           : Temp
VolumeName              : ChiaPlot 3 Evo 860 512GB
FreeSpace               : 238.99
TotalSpace              : 465.76
IsPlottable             : False
AmountOfPlotsToTempMax  : 0
HasPlotInProgress       : True
AmountOfPlotsInProgress :
PlotInProgressName      :

DriveLetter             : F:
ChiaDriveType           : Temp
VolumeName              : ChiaPlot4 NVME FullDisk 1
FreeSpace               : 246.88
TotalSpace              : 465.75
IsPlottable             : False
AmountOfPlotsToTempMax  : 0
HasPlotInProgress       : True
AmountOfPlotsInProgress :
PlotInProgressName      :
```

#### Parameters:
| Name          | Required | Type   | Description                                                                                                                              |
|---------------|----------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
|TempDriveDenom  | Yes      | String | A common denominator for all your drives used as temp drives. All drives with that denom in name will be used to as temp drives for chia.


## Invoke-PlotoJob
Calls Get-PlotoTempDrives to get all Temp drives that are plottable. For each tempDrive it determines the most appropriate OutDrive (using Get-PlotoOutDrives function), stitches together the ArgumentList for chia and fires off the chia plot job using chia.exe. For each created PlotJob the function creates an Object and appends it to a collection of objects, which are returned upon the function call. 

#### Example:

```powershell
Invoke-PlotoJob -OutDriveDenom "out" -TempDriveDenom "plot" -EnableBitfield $true -ParallelAmount max -WaitTimeBetweenPlotOnSeparateDisks 0.1 -WaitTimeBetweenPlotOnSameDisk 60
```
#### Output:

```
ProcessID       : 9024
OutDrive        : D:
TempDrive       : H:
ArgumentsList   : plots create -k 32 -t H:\ -d D:\
ChiaVersionUsed : 1.1.2
LogPath         : C:\Users\me\.chia\mainnet\plotter\PlotoSpawnerLog_29_4_13_55_Tmp-H_Out-D.txt
StartTime       : 4/29/2021 1:55:50 PM
```

#### Parameters:
| Name          | Required | Type   | Description                                                                                                                              |
|---------------|----------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
|OutDriveDenom  | Yes      | String | See Parameters Section of [Get-PlotoOutDrives](https://github.com/tydeno/Ploto/blob/main/README.md#parameters)
|TempDriveDenom | Yes      | String | See Parameters Section of [Get-PlotoTempDrives](https://github.com/tydeno/Ploto/blob/main/README.md#parameters-1)
|WaitTimeBetweenPlotOnSeparateDisks | Yes | Int | Amount of minutes to be waited for spawning plots on separate disks.
|WaitTimeBetweenPlotOnSameDisk | Yes | Int | Amount of minutes to be waited for spawning plots on the same disk.
|EnableBitfield | No | bool | Enable or disable Bitfield for all jobs to be spawned. If not set, default is off.
|ParallelAmount | No | String | Defines amount of Plot Jobs to be spawned on same disks at once (with delay). If set to "max" utilizes entire available temp disk space.

## Start-PlotoSpawns
Main function that nests all else.
Continously calls Invoke-PlotoJob and states progress and other information. It runs until it created the amount of specified Plot by using the -InputAmountToSpawn param.

#### Example:

```powershell
Start-PlotoSpawns -InputAmountToSpawn 36 -OutDriveDenom "out" -TempDriveDenom "plot" -EnableBitfield $true -ParallelAmount max -WaitTimeBetweenPlotOnSeparateDisks 0.1 -WaitTimeBetweenPlotOnSameDisk 60
```

#### Output:

```
PlotoManager @ 4/29/2021 1:45:38 PM : Amount of spawned Plots in this iteration: 1
PlotoManager @ 4/29/2021 1:45:38 PM : Overall spawned Plots since start of script: 1
```

#### Parameters:

| Name          | Required | Type   | Description                                                                                                                              |
|---------------|----------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
|InputAmounttoSpawn| Yes | Int | Defines amount of plot to be spanwed overall. Ploto will stop when that amount is reached.
|OutDriveDenom  | Yes      | String | See Parameters Section of [Get-PlotoOutDrives](https://github.com/tydeno/Ploto/blob/main/README.md#parameters)
|TempDriveDenom | Yes      | String | See Parameters Section of [Get-PlotoTempDrives](https://github.com/tydeno/Ploto/blob/main/README.md#parameters-1)
|WaitTimeBetweenPlotOnSeparateDisks | Yes | Int | See Parameters Section of [Invoke-PlotoJob](https://github.com/tydeno/Ploto/blob/main/README.md#parameters-2)
|WaitTimeBetweenPlotOnSameDisk | Yes | Int | See Parameters Section of [Invoke-PlotoJob](https://github.com/tydeno/Ploto/blob/main/README.md#parameters-2)
|EnableBitfield | No | bool | See Parameters Section of [Invoke-PlotoJob](https://github.com/tydeno/Ploto/blob/main/README.md#parameters-2)
|ParallelAmount | No | String | See Parameters Section of [Invoke-PlotoJob](https://github.com/tydeno/Ploto/blob/main/README.md#parameters-2)



# How to use
If you want to use PlotoSpawner follow along:

1. Download Ploto as .ZIP from [here](https://github.com/tydeno/Ploto/archive/refs/heads/main.zip)
3. Import-Module "Ploto" 
```powershell
Import-Module "C:\Users\Me\Downloads\Ploto\Ploto.psm1"
```
5. Launch PlotoSpawner
```powershell
Start-PlotoSpawns -InputAmountToSpawn 36 -OutDriveDenom "out" -TempDriveDenom "plot" -EnableBitfield $true -ParallelAmount max -WaitTimeBetweenPlotOnSeparateDisks 0.1 -WaitTimeBetweenPlotOnSameDisk 60
```

# FAQ
> Can I shut down the script when I dont want Ploto to spawn more Plots?

Yep. The individual Chia Plot Jobs wont be affected by that.

# PlotoManage
Allows you to check status of your current plot jobs aswell as stopping them and cleaning the temp drives.

## Get-PlotoJobs
Analyzes the plotter logs (standard chia.exe output redirected, enriched with additional data) and shows the status, pid and drives in use. The function only pick up data of plot logs that have been spawned using PlotoSpawner (as it deploys initial data like PID of process and drives use). The additional logs are stored in the same location as the standrad logs. If you delete those, this function wont be able to read certain properties anymore. 

#### Example:
```powershell
Get-PlotoJobs
```

#### Output:
```
PlotoSpawnerJobId : 5a0213af-2610-49ab-a339-0fd1dec1de29
PlotId            : a3d0083ced7e26724a644791c82aaa9d8b070f5fb8eb6c5d767fe5457fe37aab
PID               : 2540
PlotJobStatus     : 1:1
TempDrive         : F:
OutDrive          : D:
LogPath           : PlotoSpawnerLog_29_4_21_27_5a0213af-2610-49ab-a339-0fd1dec1de29_Tmp-F_Out-D.txt

PlotoSpawnerJobId : e66695ca-97ee-432d-b095-beab630622b7
PlotId            : c47aa6d7d9e41bb8e7270033f11145cddfde59da52c23e5bcdbb17f1dfe6b003
PID               : 8156
PlotJobStatus     : 1:1
TempDrive         : F:
OutDrive          : D:
LogPath           : PlotoSpawnerLog_29_4_21_30_e66695ca-97ee-432d-b095-beab630622b7_Tmp-F_Out-D.txt
```

#### Parameters:
| Name          | Required | Type   | Description                                                                                                                              |
|---------------|----------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
| |    | | 



# PlotoMove
Continously searches for final Plots on your OutDrives and moves them to your desired location. I do this for transferring plots from my plotting machine to my farming machine.

## Get-PlotoPlots

#### Example:
```powershell
```

#### Output:
```powershell
```

#### Parameters:
| Name          | Required | Type   | Description                                                                                                                              |
|---------------|----------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
| |    | | 



## Move-PlotoPlots

#### Example:

```powershell
```

#### Output:
```powershell
```
#### Parameters:
| Name          | Required | Type   | Description                                                                                                                              |
|---------------|----------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
| |    | | 








