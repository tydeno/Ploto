# Ploto
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself.
Basically spawns Plots. 

Way dumber than plotman. Still does what it should for all those Windows Farmers out there.

### PlotoSpawn
* [Get-PlotoOutDrives](https://github.com/tydeno/Ploto/blob/main/README.md#get-plotooutdrives)
* [Get-PlotoTempDrives](https://github.com/tydeno/Ploto/blob/main/README.md#get-plototempdrives)
* [Invoke-PlotoJob](https://github.com/tydeno/Ploto/blob/main/README.md#invoke-plotojob)
* [Start-PlotoSpawn](https://github.com/tydeno/Ploto/blob/main/README.md#start-plotospawns)

### PlotoManage
* [Get-PlotoJobs](https://github.com/tydeno/Ploto/blob/main/README.md#get-plotojobs)
* [Stop-PlotoJob](https://github.com/tydeno/Ploto/blob/main/README.md#stop-plotojob)
* [Remove-AbortedJobs](https://github.com/tydeno/Ploto/blob/main/README.md#remove-abortedjobs)

### PlotoMove
* Get-PlotoPlots
* Move-PlotoPlots
* Start-PlotoMove

# PlotoSpawn
TLDR: It plots 1x plot on each TempDrive (if you have 6x TempDrives = 6x parallel Plot Jobs) as long as you want it to and as long as you have OutDrive space.

Ploto checks periodically, if a TempDrive and OutDrive is available for plotting. 
If there is no TempDrive available, or no OutDrive, Ploto checks again in 300 seconds.

When there is one available, Ploto determines the best OutDrive (most free space) and calls chia.exe to start the plot.
Ploto iterates once through all available TempDrives and spawns a plot per each TempDrive (as long as enough OutDrive space is given).
After that, Ploto checks if amount Spawned is equal as defined as input. If not, Ploto keeps going until it is.

You can specify several vital parameters to control when and where plots are spawned, temped and stored. 
PlotoSpawner identifies your drives for temping and storing plots by a common denominator you specify. 

IMPORTANT: Ploto Assumes you Plot in the root of your Drives and that the Drives are dedicated to plotting. So make sure you do that aswell.
It may work when the drives contains other data but, but Ploto was designed for empty, plot-only drives.
EDIT: I noticed I have a folder in my Q:\ drive with some data. So it seems to work. 

For reference heres my setup:
* CPU: i9-9900k
* RAM: 32 GB DDR4
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
Start-PlotoSpawns -InputAmountToSpawn 36 -OutDriveDenom "out" -TempDriveDenom "plot" -WaitTimeBetweenPlotOnSeparateDisks 0.1 -WaitTimeBetweenPlotOnSameDisk 0.1 -MaxParallelJobsOnAllDisks 2 -EnableBitfield $false -Verbose
```

the following will happen:
If there is enough free space on the temp and out drive, Ploto spawns 1x job on each disk with the specified wait time between jobs. For each job, it calculates the mot suitable out drive anew, being aware of the plot jobs in progress on that disk.

### I need more parallelization

Using the Parameter "-MaxParallelJobsOnAllDisks", you can define how many Plots Jobs overall there should be. So this will be your hard cap. If there are as many jobs as you defined as max, PlotoSpawner wont spawn further Jobs. This keeps your system from overcommiting.

Using "-MaxParallelJobsOnSameDisks" you can define how many PlotsJobs there should be in parallel on a single disk. This param affects all Disks that can host more than 1 Plot. Still Ploto checks if the drive has enough SPace to temp that many plots.

If I launch PlotoSpawner with these params like this:
```powershell
Start-PlotoSpawns -InputAmountToSpawn 36 -OutDriveDenom "out" -TempDriveDenom "plot" -WaitTimeBetweenPlotOnSeparateDisks 0.1 -WaitTimeBetweenPlotOnSameDisk 0.1 -MaxParallelJobsOnAllDisks 2 -MaxParallelJobsOnSameDisk 1 -EnableBitfield $false
```

PlotoSpawner will max out the available temp drives. This means for my temp drive setup the following:
| Name          | DriveLetter | Type   | Size      | Total Plots in parallel |
|---------------|----------|--------|--------------|-------------------------|
|ChiaPlot 1 | I:\ | SATA SSD | 465 GB | 1
|ChiaPlot 2 | H:\ | SATA SSD | 465 GB | 1
|ChiaPlot 3 | E:\ | SATA SSD | 465 GB | 1
|ChiaPlot 4 | Q:\ | SATA SSD | 1810 GB | 3
|ChiaPlot 5 | J:\ | NVME SSD PCI 16x | 465 GB | 1

So there will be 8x Plot jobs running in parallel with defined wait time in minutes betwen jobs on each disk and the same Disk. 
Drive J:\ will never see more than 3x Plots in parallel as defined by -MaxParallelJobsOnSameDisk 3

When a job is done and a temp drive becommes available again, PlotoSpawner will spawn the next jobs, until it has spawned the amount you specified as -InputAmountToSpawn or it reaches it max cap.

PlotoSpawner redirects the output of chia.exe to to the following path: 
* C:\Users\me\.chia\mainnet\plotter\

And creates two log files for each job with the following notation:
* PlotoSpawnerLog_30_4_0_49_49ab3c48-532b-4f17-855d-3c5b4981528b_Tmp-E_Out-K.txt (chia.exe output)
* PlotoSpawnerLog_30_4_0_49_49ab3c48-532b-4f17-855d-3c5b4981528b_Tmp-E_Out-K'@'Stat.txt (Additional Info from PLotoSpawner)


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
DriveLetter             : E:
ChiaDriveType           : Temp
VolumeName              : ChiaPlot 3 Evo 860 512GB
FreeSpace               : 437.28
TotalSpace              : 465.76
hasFolder               : False
IsPlottable             : True
HasPlotInProgress       : False
AmountOfPlotsInProgress : 0
AmountOfPlotsToTempMax  : 1
AvailableAmountToPlot   : 1
PlotInProgressID        :

DriveLetter             : F:
ChiaDriveType           : Temp
VolumeName              : ChiaPlot4 NVME FullDisk 1
FreeSpace               : 446.76
TotalSpace              : 465.75
hasFolder               : False
IsPlottable             : True
HasPlotInProgress       : False
AmountOfPlotsInProgress : 0
AmountOfPlotsToTempMax  : 1
AvailableAmountToPlot   : 1
PlotInProgressID        :

DriveLetter             : H:
ChiaDriveType           : Temp
VolumeName              : ChiaPlot 2 Crucial CT 512 GB 2
FreeSpace               : 450.99
TotalSpace              : 476.94
hasFolder               : False
IsPlottable             : True
HasPlotInProgress       : False
AmountOfPlotsInProgress : 0
AmountOfPlotsToTempMax  : 1
AvailableAmountToPlot   : 1
PlotInProgressID        :

DriveLetter             : I:
ChiaDriveType           : Temp
VolumeName              : ChiaPlot 1 Crucial CT 512GB
FreeSpace               : 451
TotalSpace              : 476.94
hasFolder               : False
IsPlottable             : True
HasPlotInProgress       : False
AmountOfPlotsInProgress : 0
AmountOfPlotsToTempMax  : 1
AvailableAmountToPlot   : 1
PlotInProgressID        :

DriveLetter             : J:
ChiaDriveType           : Temp
VolumeName              : ChiaPlot 5 NVME 980 Pro
FreeSpace               : 463.04
TotalSpace              : 465.75
hasFolder               : False
IsPlottable             : True
HasPlotInProgress       : False
AmountOfPlotsInProgress : 0
AmountOfPlotsToTempMax  : 1
AvailableAmountToPlot   : 1
PlotInProgressID        :

DriveLetter             : Q:
ChiaDriveType           : Temp
VolumeName              : ChiaPlot 4 2TB SSD
FreeSpace               : 1441.41
TotalSpace              : 1863
hasFolder               : True
IsPlottable             : True
HasPlotInProgress       : False
AmountOfPlotsInProgress : 0
AmountOfPlotsToTempMax  : 4
AvailableAmountToPlot   : 4
PlotInProgressID        :
```

#### Parameters:
| Name          | Required | Type   | Description                                                                                                                              |
|---------------|----------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
|TempDriveDenom  | Yes      | String | A common denominator for all your drives used as temp drives. All drives with that denom in name will be used to as temp drives for chia.


## Invoke-PlotoJob
Calls Get-PlotoTempDrives to get all Temp drives that are plottable. For each tempDrive it determines the most appropriate OutDrive (using Get-PlotoOutDrives function), stitches together the ArgumentList for chia and fires off the chia plot job using chia.exe. For each created PlotJob the function creates an Object and appends it to a collection of objects, which are returned upon the function call. 

#### Example:

```powershell
Invoke-PlotoJob -OutDriveDenom "out" -TempDriveDenom "plot" -WaitTimeBetweenPlotOnSeparateDisks 0.1 -WaitTimeBetweenPlotOnSameDisk 0.1 -MaxParallelJobsOnAllDisks 2 -MaxParallelJobsOnSameDisk 1 -EnableBitfield $false -Verbose
```
#### Output:

```
PlotoSpawnerJobId : 49ab3c48-532b-4f17-855d-3c5b4981528b
ProcessID       : 9024
OutDrive        : D:
TempDrive       : H:
ArgumentsList   : plots create -k 32 -t H:\ -d D:\
ChiaVersionUsed : 1.1.2
LogPath           : C:\Users\me\.chia\mainnet\plotter\PlotoSpawnerLog_30_4_0_49_49ab3c48-532b-4f17-855d-3c5b4981528b_Tmp-E_Out-K.txt
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
Start-PlotoSpawns -InputAmountToSpawn 36 -OutDriveDenom "out" -TempDriveDenom "plot" -WaitTimeBetweenPlotOnSeparateDisks 0.1 -WaitTimeBetweenPlotOnSameDisk 0.1 -MaxParallelJobsOnAllDisks 2 -MaxParallelJobsOnSameDisk 1 -EnableBitfield $false -Verbose
```

#### Output:

```
PlotoManager @ 4/29/2021 1:45:38 PM : Amount of spawned Plots in this iteration: 2
PlotoManager @ 4/29/2021 1:45:38 PM : Overall spawned Plots since start of script: 2
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

# PlotoManage
Allows you to check status of your current plot jobs aswell as stopping them and cleaning the temp drives.

## Get-PlotoJobs
Analyzes the plotter logs (standard chia.exe output redirected, enriched with additional data) and shows the status, pid and drives in use. The function only pick up data of plot logs that have been spawned using PlotoSpawner (as it deploys initial data like PID of process and drives use). The additional logs are stored in the same location as the standrad logs. If you delete those, this function wont be able to read certain properties anymore. 

## Status Codes and their meaning

See below for a definition of what phase coe is associated with which chia.exe log output.
```powershell
"Starting plotting progress into temporary dirs:*" {$StatusReturn = "Initializing"}
"Starting phase 1/4*" {$StatusReturn = "1.0"}
"Computing table 1" {$StatusReturn = "1.1"}
"F1 complete, time*" {$StatusReturn = "1.1"}
"Computing table 2" {$StatusReturn = "1.1"}
"Computing table 3" {$StatusReturn = "1.2"}
"Computing table 4" {$StatusReturn = "1.3"}
"Computing table 5" {$StatusReturn = "1.4"}
"Computing table 6" {$StatusReturn = "1.5"}
"Computing table 7" {$StatusReturn = "1.6"}
"Starting phase 2/4*" {$StatusReturn = "2.0"}
"Backpropagating on table 7" {$StatusReturn = "2.1"}
"Backpropagating on table 6" {$StatusReturn = "2.2"}
"Backpropagating on table 5" {$StatusReturn = "2.3"}
"Backpropagating on table 4" {$StatusReturn = "2.4"}
"Backpropagating on table 3" {$StatusReturn = "2.5"}
"Backpropagating on table 2" {$StatusReturn = "2.6"}
"Starting phase 3/4*" {$StatusReturn = "3.0"}
"Compressing tables 1 and 2" {$StatusReturn = "3.1"}
"Compressing tables 2 and 3" {$StatusReturn = "3.2"}
"Compressing tables 3 and 4" {$StatusReturn = "3.3"}
"Compressing tables 4 and 5" {$StatusReturn = "3.4"}
"Compressing tables 5 and 6" {$StatusReturn = "3.5"}
"Compressing tables 6 and 7" {$StatusReturn = "3.6"}
"Starting phase 4/4*" {$StatusReturn = "4.0"}
"Writing C2 table*" {$StatusReturn = "4.1"}
"Time for phase 4*" {$StatusReturn = "4.2"}
"Renamed final file*" {$StatusReturn = "4.3"}
```


#### Example:
```powershell
Get-PlotoJobs | ft 
```

#### Output:
```
PlotoSpawnerJobId                    PlotId                                                           PID  PlotJobPhase TempDrive OutDrive LogPath
-----------------                    ------                                                           ---  ------------ --------- -------- -------
2e39e295-ccd9-4abf-94e9-01a854cbfa24 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx None Completed    E:        K:       C:\Users\...
ed2133b0-018c-44db-81e7-61befbda8031 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx None Completed    F:        D:       C:\Users\...
bc3b44b1-b290-4487-a552-c4dda2e11366 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx None Completed    H:        K:       C:\Users\...
10e6deb5-6a13-4a0d-9c77-8c65d717bf6b xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx None Completed    Q:        D:       C:\Users\...
f865e425-ada4-44f0-8537-23a033aef302 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx None Completed    Q:        D:       C:\Users\...
b19eaef4-f9b3-4807-8870-a959e5aa3a21 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx None Completed    I:        D:       C:\Users\...
278615e9-8e4d-4af4-bfcc-4665412aae89 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx None Completed    Q:        K:       C:\Users\...

```


## Remove-AbortedJobs
Gets all Jobs from Get-PlotoJobs that are aborted (where no process runs to PID) and foreach call Stop-PlotoJob

#### Example:

```powershell
Remove-AbortedJobs
```

#### Output:
```
PlotoRemoveAbortedJobs @ 5/1/2021 6:42:24 PM : Found aborted Jobs to be deleted: 6cfb4e4a-cb71-4f2a-9387-17a8049ce625 85b08573-054d-46f0-b7e3-755f9ce021bc cbab519c-2f26-41c9-b3fa-8bcb0ba36d3a 2b0ab204-3b0e-4e8c-b04c-a884859ae637 f639cb35-23a8-4010-a1db-ab6186bd117c
PlotoRemoveAbortedJobs @ 5/1/2021 6:42:24 PM : Cleaning up...
PlotoStopJob @ 5/1/2021 6:42:24 PM : ERROR:  Cannot bind parameter 'Id'. Cannot convert value "None" to type "System.Int32". Error: "Input string was not in a correct format."
PlotoStopJob @ 5/1/2021 6:42:24 PM : Found .tmp files for this job to be deleted. Continue with deletion.
PlotoStopJob @ 5/1/2021 6:42:24 PM : Removed temp files on F:
PlotoStopJob @ 5/1/2021 6:42:24 PM : Removed log files for this job.
PlotoStopJob @ 5/1/2021 6:42:25 PM : ERROR:  Cannot bind parameter 'Id'. Cannot convert value "None" to type "System.Int32". Error: "Input string was not in a correct format."
PlotoStopJob @ 5/1/2021 6:42:25 PM : Found .tmp files for this job to be deleted. Continue with deletion.
PlotoStopJob @ 5/1/2021 6:42:25 PM : Removed temp files on H:
PlotoStopJob @ 5/1/2021 6:42:25 PM : Removed log files for this job.
PlotoStopJob @ 5/1/2021 6:42:25 PM : ERROR:  Cannot bind parameter 'Id'. Cannot convert value "None" to type "System.Int32". Error: "Input string was not in a correct format."
PlotoStopJob @ 5/1/2021 6:42:25 PM : Found .tmp files for this job to be deleted. Continue with deletion.
PlotoStopJob @ 5/1/2021 6:42:25 PM : Removed temp files on E:
PlotoStopJob @ 5/1/2021 6:42:25 PM : Removed log files for this job.
PlotoStopJob @ 5/1/2021 6:42:26 PM : ERROR:  Cannot bind parameter 'Id'. Cannot convert value "None" to type "System.Int32". Error: "Input string was not in a correct format."
PlotoStopJob @ 5/1/2021 6:42:26 PM : Found .tmp files for this job to be deleted. Continue with deletion.
PlotoStopJob @ 5/1/2021 6:42:26 PM : Removed temp files on J:
PlotoStopJob @ 5/1/2021 6:42:26 PM : Removed log files for this job.
PlotoStopJob @ 5/1/2021 6:42:26 PM : ERROR:  Cannot bind parameter 'Id'. Cannot convert value "None" to type "System.Int32". Error: "Input string was not in a correct format."
PlotoStopJob @ 5/1/2021 6:42:26 PM : Found .tmp files for this job to be deleted. Continue with deletion.
PlotoStopJob @ 5/1/2021 6:42:26 PM : Removed temp files on I:
PlotoStopJob @ 5/1/2021 6:42:26 PM : Removed log files for this job.
PlotoRemoveAbortedJobs @ 5/1/2021 6:42:26 PM : Removed Amount of aborted Jobs: 5
```
The Error below is known and only says that the process is already closed. This is expected. In the future this error may be surpressed.

```
PlotoStopJob @ 5/1/2021 6:42:26 PM : ERROR:  Cannot bind parameter 'Id'. Cannot convert value "None" to type "System.Int32". Error: "Input string was not in a correct format."
```

# PlotoMove
Continously searches for final Plots on your OutDrives and moves them to your desired location. I do this for transferring plots from my plotting machine to my farming machine.

## Get-PlotoPlots
Searches defined Outdrives for Final Plots (file that end upon .plot) and returns an array with final plots.

#### Example:
```powershell
Get-PlotoPlots -OutDriveDenom "out"
```

#### Output:
```
Iterating trough Drive:  @{DriveLetter=D:; ChiaDriveType=Out; VolumeName=ChiaOut2; FreeSpace=59.04; TotalSpace=0; IsPlottable=False; AmountOfPlotsToHold=0}
Checking if any item in that drive contains .PLOT as file ending...
Found a Final plot:  plot-k32-2021-04-30-18-52-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot
Found a Final plot:  plot-k32-2021-04-30-19-02-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot
Found a Final plot:  plot-k32-2021-04-30-19-12-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot
Found a Final plot:  plot-k32-2021-04-30-19-42-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot
Iterating trough Drive:  @{DriveLetter=K:; ChiaDriveType=Out; VolumeName=ChiaOut3; FreeSpace=262.86; TotalSpace=0; IsPlottable=True; AmountOfPlotsToHold=2}
Checking if any item in that drive contains .PLOT as file ending...
Found a Final plot:  plot-k32-2021-04-30-18-57-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot
Found a Final plot:  plot-k32-2021-04-30-19-12-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot
--------------------------------------------------------------------------------------------------

FilePath                                                                                           Name
--------                                                                                           ----
D:\plot-k32-2021-04-30-18-52-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot plot-k32-2021-04-...
D:\plot-k32-2021-04-30-19-02-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot plot-k32-2021-04-...
D:\plot-k32-2021-04-30-19-12-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot plot-k32-2021-04-...
D:\plot-k32-2021-04-30-19-42-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot plot-k32-2021-04-...
K:\plot-k32-2021-04-30-18-57-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot plot-k32-2021-04-...
K:\plot-k32-2021-04-30-19-12-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot plot-k32-2021-04-...
```

#### Parameters:
| Name          | Required | Type   | Description                                                                                                                              |
|---------------|----------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
| OutDriveDenom | Yes      | String | See Parameters Section of [Get-PlotoOutDrives](https://github.com/tydeno/Ploto/blob/main/README.md#parameters) 


## Move-PlotoPlots
Grabs the found plots from Get-PlotoPlots and moves them to either a local/external drive using Move-Item cmdlet or to a UNC path using Background Intelligence TRansfer Service (Bits). You can define the OutDrives to search for Plots, TransferMethod and Destination.

Make sure TrasnferMethod and Destination match. 

#### Example:

```powershell
Move-PlotoPlots -DestinationDrive "\\Desktop-xxxxx\d" -OutDriveDenom "out" -TransferMethod BITS
```

#### Output:
```
PlotoMover @ 5/1/2021 7:08:09 PM : Moving plot:  D:\plot-k32-2021-04-30-18-52-dxxxxxxxxxxxxxxxxxxxxxxxxxxxxx00454fxxxxxxxxxxxxxxxxxxxxxxxxxx64.plot to \\Desktop-xxxxx\d using BITS
```
#### Parameters:
| Name          | Required | Type   | Description                                                                                                                              |
|---------------|----------|--------|------------------------------------------------------------------------------------------------------------------------------------------|
| DestinationDrive| Yes    | String | The destination drive you want the plot to be moved to. Accpets UNC Paths aswell as DriveLetters (eg E:)
| OutDriveDenim | Yes | String | See Parameters Section of [Get-PlotoOutDrives](https://github.com/tydeno/Ploto/blob/main/README.md#parameters) 
| TransferMethod | Yes | String | Defines TransferMethod to be used. If local drive use "Move-Item". If UNC path use "BITS".


# How to:
If you want to use PlotoSpawner follow along:

## Spawn Plots
1. Make sure your Out and TempDrives are named accordingly
2. Download Ploto as .ZIP from [here](https://github.com/tydeno/Ploto/archive/refs/heads/main.zip)
3. Import-Module "Ploto" 
```powershell
Import-Module "C:\Users\Me\Downloads\Ploto\Ploto.psm1"
```
4. Launch PlotoSpawner
```powershell
Start-PlotoSpawns -InputAmountToSpawn 36 -OutDriveDenom "out" -TempDriveDenom "plot" -EnableBitfield $false -ParallelAmount max -WaitTimeBetweenPlotOnSeparateDisks 30 -WaitTimeBetweenPlotOnSameDisk 60
```
```
PlotoSpawner @ 4/30/2021 3:19:13 AM : Spawned the following plot Job:
PlotoSpawnerJobId : ad917660-9de9-4810-8977-6ace317d7ddb
ProcessID         : 13192
OutDrive          : K:
TempDrive         : Q:
ArgumentsList     : plots create -k 32 -t Q:\ -d K:\ -e
ChiaVersionUsed   : 1.1.2
LogPath           : C:\Users\me\.chia\mainnet\plotter\PlotoSpawnerLog_30_4_3_19_ad917660-9de9-4810-8977-6ace317d7ddb_Tmp-Q_Out-K.txt
StartTime         : 4/30/2021 3:19:13 AM

PlotoManager @ 4/30/2021 3:49:13 AM : Amount of spawned Plots in this iteration: 6
PlotoManager @ 4/30/2021 3:49:13 AM : Overall spawned Plots since start of script: 6
```


5. Leave the PowerShell Session open (can be minimized)


## Get Jobs
1. Open another PowerShell session 
2. Import-Module "Ploto" 
```powershell
Import-Module "C:\Users\Me\Downloads\Ploto\Ploto.psm1"
```
4. Launch Get-PlotoJobs and format Output
```powershell
Get-PlotoJobs | ft
```

```
PlotoSpawnerJobId                    PlotId                                                           PID   PlotJobPhase TempDrive OutDrive LogPath
-----------------                    ------                                                           ---   ------------ --------- -------- -------
49ab3c48-532b-4f17-855d-3c5b4981528b xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 11856 3.6          E:        K:       C:\Users\me\.chia...
8a0cc01e-37e7-4507-ad6e-cad9401c1381 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 9184  3.6          F:        K:       C:\Users\me\.chia...
95c7cd61-bd88-45a3-a6a2-c243338de480 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 1604  3.5          H:        D:       C:\Users\me\.chia...
465355ef-7da6-4691-8137-3eeba98976d5 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 16280 3.4          I:        K:       C:\Users\me\.chia...
2120b771-2376-49f5-8d47-99a411865ec9 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 14228 3.3          J:        D:       C:\Users\ne\.chia...
ad917660-9de9-4810-8977-6ace317d7ddb xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 13192 2.2          Q:        K:       C:\Users\me\.chia...
2b8596cd-3369-4e8c-a04f-26c85acdfd82 xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 9752  2.1          Q:        K:       C:\Users\me\.chia...
cfff29b8-fdee-4988-ae89-9db035d809bc xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 11176 1.6          Q:        K:       C:\Users\me\.chia...
```

Check Jobs With PerformanceCounters:
```powershell
Get-PlotoJobs -PerfCounter 
```

```
PlotoSpawnerJobId     : 10e6deb5-6a13-4a0d-9c77-8c65d717bf6b
PlotId                : 332f93247b707d3bcf977889edff9bcbc9f0c3d3e30bfd941328bd7bf424f03a
PID                   : 6648
PlotJobPhase          : 3.6
TempDrive             : Q:
OutDrive              : D:
LogPath               : C:\Users\me\.chia\mainnet\plotter\PlotoSpawnerLog_30_4_19_12_10e6deb5-6a13-4a0d-9c77-8c65d71
                        7bf6b_Tmp-Q_Out-D.txt
StatLogPath           : C:\Users\me\.chia\mainnet\plotter\PlotoSpawnerLog_30_4_19_12_10e6deb5-6a13-4a0d-9c77-8c65d71
                        7bf6b_Tmp-Q_Out-D@Stat.txt
PlotSizeOnDisk        : 48.03 GB
cpuUsagePercent       : 0.49
memUsageMB            : 2676
CompletionTimeInHours : Still in progress
```

To get a better Overview, select the Proprties you want to see and use Format-Table:
```powershell
Get-PlotoJobs -PerfCounter | ? {$_.PLotJobPhase -ne "Completed"} | select PID, PlotJobPhase, TempDrive, OutDrive, cpuUsagePercent, memUsageMB, PlotSizeOnDisk | ft
```

```
PID  PlotJobPhase TempDrive OutDrive cpuUsagePercent memUsageMB PlotSizeOnDisk
---  ------------ --------- -------- --------------- ---------- --------------
8144 3.5          Q:        K:                  0.58       2130 89.46 GB
6648 3.6          Q:        D:                  6.24       2676 48.03 GB
5444 3.6          Q:        D:                  3.29       2676 48.03 GB
```


## Stop Jobs
1. Open a PowerShell session and import Module "Ploto" or use an existing one.
2. Get PlotJobSpawnerId of Job you want to stop by calling "Get-PlotJobs"
3. Stop the process:

```powershell
Stop-PlotoJob -PlotSpawnerId cfff29b8-fdee-4988-ae89-9db035d809bc
```
or if you want to Stop all Jobs that are aborted:
```powershell
Remove-AbortedPlotoJobs
```

## Move Plots
As you may have noticed in my ref setup: I have little OutDrive storage capacity (1TTB roughly).
This is only possible as I continously move the final Plots to my farming machine with lots of big drives. 

I do this by moving plots to a external drive and plug that into my farmer, and sometimes I also transfer plots across my network (not the fatest, thats why I kind of have to do  the running around approach)

PlotoMover helps to automate this process.

If you want to move your plots to a local/external drive just once:
1. Launch a PowerShell session and Import Ploto Module
2. Launch Move-PlotoPLots

```powershell
Move-PlotoPlots -DestinationDrive "P:" -OutDriveDenom "out" -TransferMethod Move-Item
```

If you want to move your plots to a UNC path just once:
1. Launch a PowerShell session and Import Ploto Module
2. Launch Move-PlotoPLots

powershell
Move-PlotoPlots -DestinationDrive "\\Desktop-xxxxx\d" -OutDriveDenom "out" -TransferMethod Move-Item
```
Please be aware that if you use UNC paths as Destination, PlotoMover cannot grab the free space there and just fires off.

## But I want it do it continously!
Sure, just use Start-PlotoMove with your needed params:

```
Move-PlotoPlots -DestinationDrive "\\Desktop-xxxxx\d" -OutDriveDenom "out" -TransferMethod Move-Item
```

Please be aware that if you use UNC paths as Destination, PlotoMover cannot grab the free space there and just fires off.

# FAQ
> Can I shut down the script when I dont want Ploto to spawn more Plots?

Yep. The individual Chia Plot Jobs wont be affected by that.


# Knowns Bugs and Limitations
Ploto has its bugs and limitations here and there.

These are known:
* Only works when plotting in root of drives
* Only works when Drives are dedicated to plotting (dont hold any other files)
* Can only display and stop PlotJobs that have been spawned using PlotoSpawner
* Using the -PerfCounter param on Get-PlotoJobs takes a while to load
* PlotoMover is very limited right now, may break copy jobs at times (Bits)

Please be aware that Ploto was built for my specific setup. I try to generalize it as much as possible, but thats not easy-breezy.
So what works for me, may not ultimately work for you. 
Please also bear in mind that unexpoected beahviour and or bugs are possible.


