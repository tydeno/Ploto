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


## Invoke-PlotoJob
Calls Get-PlotoTempDrives to get all Temp drives that are plottable. For each tempDrive it determines the most appropriate OutDrive (using Get-PlotoOutDrives function), stitches together the ArgumentList for chia and fires off the chia plot job using chia.exe. For each created PlotJob the function creates an Object and appends it to a collection of objects, which are returned upon the function call. 

#### Example:

```powershell
Invoke-PlotoJob -BufferSize 3390 -Thread 2 -OutDriveDenom "out" -TempDriveDenom "plot" -WaitTimeBetweenPlotOnSeparateDisks 0.1 -WaitTimeBetweenPlotOnSameDisk 0.1 -MaxParallelJobsOnAllDisks 2 -MaxParallelJobsOnSameDisk 1 -EnableBitfield $true -Verbose
```
#### Output:

```
PlotoSpawnerJobId : 49ab3c48-532b-4f17-855d-3c5b4981528b
ProcessID       : 9024
OutDrive        : D:
TempDrive       : H:
ArgumentsList   : plots create -k 32 -b 3390 -r 2 -t H:\ -d D:\
ChiaVersionUsed : 1.1.2
LogPath           : C:\Users\me\.chia\mainnet\plotter\PlotoSpawnerLog_30_4_0_49_49ab3c48-532b-4f17-855d-3c5b4981528b_Tmp-E_Out-K.txt
StartTime       : 4/29/2021 1:55:50 PM
```

## Start-PlotoSpawns
Main function that nests all else.
Continously calls Invoke-PlotoJob and states progress and other information. It runs until it created the amount of specified Plot by using the -InputAmountToSpawn param.

#### Example:

```powershell
Start-PlotoSpawns -BufferSize 3390 -Thread 2 -InputAmountToSpawn 36 -OutDriveDenom "out" -TempDriveDenom "plot" -WaitTimeBetweenPlotOnSeparateDisks 0.1 -WaitTimeBetweenPlotOnSameDisk 0.1 -MaxParallelJobsOnAllDisks 2 -MaxParallelJobsOnSameDisk 1 -EnableBitfield $true 
```

#### Output:

```
PlotoManager @ 4/29/2021 1:45:38 PM : Amount of spawned Plots in this iteration: 2
PlotoManager @ 4/29/2021 1:45:38 PM : Overall spawned Plots since start of script: 2
```


# PlotoManage
Allows you to check status of your current plot jobs aswell as stopping them and cleaning the temp drives.

## Get-PlotoJobs
Analyzes the plotter logs (standard chia.exe output redirected, enriched with additional data) and shows the status, pid and drives in use. The function only pick up data of plot logs that have been spawned using PlotoSpawner (as it deploys initial data like PID of process and drives use). The additional logs are stored in the same location as the standrad logs. If you delete those, this function wont be able to read certain properties anymore. 

#### Example:
```powershell
Get-PlotoJobs | ft 
```

#### Output:
```
JobId                                PlotId                                                           PID  Status       TempDrive OutDrive LogPath
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
