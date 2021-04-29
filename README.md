# Ploto
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself.
Basically spawns and moves Plots around.

### PlotoSpawn

* [Get-PlotoOutDrives](https://github.com/tydeno/Ploto/blob/main/README.md#get-plotooutdrives)
* [Get-PlotoTempDrives](https://github.com/tydeno/Ploto/blob/main/README.md#get-plototempdrives)
* [Invoke-PlotoJob](https://github.com/tydeno/Ploto/blob/main/README.md#invoke-plotojob)
* [Start-PlotoSpawns](https://github.com/tydeno/Ploto/blob/main/README.md#start-plotospawns)

### PlotoMove

* [Get-PlotoPlots](https://github.com/tydeno/Ploto/blob/main/README.md#get-plotoplots)
* [Move-PlotoPlots](https://github.com/tydeno/Ploto/blob/main/README.md#move-plotoplots)


# How it works
TLDR: It plots 1x plot on each TempDrive (if you have 6x TempDrives = 6x parallel Plot Jobs) as long as you want it to and as long as you have OutDrive space.

Ploto checks periodically, if a TempDrive and OutDrive is available for plotting. 
If there is no TempDrive available, or no OutDrive, Ploto checks again in 3600 seconds.

When there is one available, Ploto determines the best OutDrive (most free space) and calls chia.exe to start the plot.
Ploto iterates once through all available TempDrives and spawns a plot per each TempDrive (as long as enough OutDrive space is given).
After that, Ploto checks if amount Spawned is equal as defined as input. If not, Ploto keeps going until it is.

# Prereqs
The following prereqs need to be met in order for Ploto to function properly:

* chia.exe is installed 
* BITS (Background Intelligent Transfer Service) is functioning properly (used to move final plots around if needed -> Manage-PlotoMove) 


# PlotoSpawn
PlotoSpawn spawns one plot job on each available Drive defined as a TempDrive, if it has enough free space (270 GB) and there is no plotting in progress on that drive. Plotting in progress is considered when a SSD defined as a TempDrive has less than 270 GB free space or has ANY files or folders in it that have file extension ".tmp".
Using the -ParallelAmount Parameter, you may also plot several Jobs in Parallel on a disk. It determines the amount of available plots to to temp on a disk and maxes it out.

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
LogPath         : C:\Users\Yanik\.chia\mainnet\plotter\PlotoSpawnerLog_29_4_13_55_Tmp-H_Out-D.txt
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



# PlotoMove
Heavy WORK IN PROGRESS HERE!
It continously searches for final Plots on your OutDrives and moves them to your desired location. I do this for transferring plots from my plotting machine to my farming machine.

## Get-PlotoPlots
Searches specified Outdrives for final .PLOT files and returns an array of objects with all final plots found, their names and Path.
A final plot is solely determined by a file on a OutDrive with the file extension .PLOT (Actual item property, not file name)

#### Example:

```powershell
Get-PlotoPlots -OutDriveDenom "out"
```

#### Output:

```
-------------------------------------------------------------
Iterating trough Drive:  @{DriveLetter=D:; ChiaDriveType=Out; VolumeName=ChiaOut2; FreeSpace=363.12; IsPlottable=True; AmountOfPlotsToHold=3}
Checking if any item in that drive contains .PLOT as file ending...
Found a Final plot:  plot-k32-2021-04-23-14-31-674b9f72e0df0a35c6918afd4fd3eb2780915a7a4f776b803328a40972c99db6.plot
-------------------------------------------------------------
Iterating trough Drive:  @{DriveLetter=K:; ChiaDriveType=Out; VolumeName=ChiaOut3; FreeSpace=364.24; IsPlottable=True; AmountOfPlotsToHold=3}
Checking if any item in that drive contains .PLOT as file ending...
Found a Final plot:  plot-k32-2021-04-24-06-52-a1dfce79910040323cab0d10baafe24f25cc0cef592978984e91603acdb3434a.plot
--------------------------------------------------------------------------------------------------

FilePath                                                                                           Name                                                                 
--------                                                                                           ----                                                                 
D:\plot-k32-2021-04-23-14-31-674b9f72e0df0a35c6918afd4fd3eb2780915a7a4f776b803328a40972c99db6.plot plot-k32-2021-04-23-14-31-674b9f72e0df0a35c6918afd4fd3eb2780915a7a...
K:\plot-k32-2021-04-24-06-52-a1dfce79910040323cab0d10baafe24f25cc0cef592978984e91603acdb3434a.plot plot-k32-2021-04-24-06-52-a1dfce79910040323cab0d10baafe24f25cc0cef...
```

#### Parameters
See Parameters Section of Get-PlotoOutDrives.


## Move-PlotoPlots
Gets all final Plot files and moves them to a destination drive. Can also use UNC Paths, as the transfer method is BITS (Background Intelligence Transfer Service).
Calls Get-PlotoPlots to get all final plots and moves one by one to the destination drive.

#### Example:

```powershell
Move-PlotoPlots -DestinationDrive "\\DESKTOP-XXXX\d" -OutDriveDenom "out" 
```

#### Parameters
```powershell
-DestinationDrive
```
Defines the destination drive the final plot is moved to. Can be a drive or UNC Path.
See Parameters Section of Get-PlotoOutDrives.

#### Output:

```
Iterating trough Drive:  @{DriveLetter=D:; ChiaDriveType=Out; VolumeName=ChiaOut2; FreeSpace=261.79; IsPlottable=True; AmountOfPlotsToHold=2}
Checking if any item in that drive contains .PLOT as file ending...
Found a Final plot:  plot-k32-2021-04-23-14-31-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1.plot
Found a Final plot:  plot-k32-2021-04-24-17-35-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx2.plot
Iterating trough Drive:  @{DriveLetter=K:; ChiaDriveType=Out; VolumeName=ChiaOut3; FreeSpace=60.18; IsPlottable=False; AmountOfPlotsToHold=0}
Checking if any item in that drive contains .PLOT as file ending...
Found a Final plot:  plot-k32-2021-04-24-06-52-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx3.plot
Found a Final plot:  plot-k32-2021-04-24-17-20-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx4.plot
Found a Final plot:  plot-k32-2021-04-24-23-10-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx5.plot
Found a Final plot:  plot-k32-2021-04-25-00-40-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx6.plot
--------------------------------------------------------------------------------------------------
PlotoMover @ 4/25/2021 12:09:17 PM : There are Plots found to be moved: 
D:\plot-k32-2021-04-23-14-31-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1.plot
D:\plot-k32-2021-04-24-17-35-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx2.plot
K:\plot-k32-2021-04-24-06-52-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx3.plot
K:\plot-k32-2021-04-24-17-20-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx4.plot
K:\plot-k32-2021-04-24-23-10-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx5.plot
K:\plot-k32-2021-04-25-00-40-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx6.plot
PlotoMover @ 4/25/2021 12:09:17 PM : A total of  6  plot have been found.
PlotoMover @ 4/25/2021 12:09:17 PM : Moving plot:  D:\plot-k32-2021-04-23-14-31-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx1.plot to \\Desktop-XXXXX\d
```





