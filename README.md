## [Ploto](https://www.ploto.rocks)
An easy to use, customizable and heavily reliable Windows PowerShell based Chia Plotting Manager. 


![image](https://user-images.githubusercontent.com/83050419/123462242-57fa0a00-d5ea-11eb-9506-03cb578ce77d.png)
![image](https://user-images.githubusercontent.com/83050419/123462300-6c3e0700-d5ea-11eb-9c2f-f5915c758580.png)

# Table of content
* [Contact](https://github.com/tydeno/Ploto/tree/main#contact)
* [How you can support this project](https://github.com/tydeno/Ploto/tree/main#how-you-can-support-this-project)
* [Is it safe to use?](https://github.com/tydeno/Ploto/tree/main#is-it-safe-to-use)
* [How it works](https://github.com/tydeno/Ploto/tree/main#plotospawn)
   * [Understanding Plot and OutDrives](https://github.com/tydeno/Ploto/tree/main#understanding-plot-and-outdrive-denominators)
   * [About -2 drives](https://github.com/tydeno/Ploto/tree/main#about--2-drives)
   * [About parallelization on separate disks](https://github.com/tydeno/Ploto/tree/main#about-parallelization-on-separate-disks)
   * [About parallelization on the same disk](https://github.com/tydeno/Ploto/tree/main#about-parallelization-on-the-same-disk)
   * [About DIscord webhooks](https://github.com/tydeno/Ploto/tree/main#alright-i-saw-that-discord-bot-picture-how-do-i-use-that)
   * [Plotting with your Pool & Farmer Key](https://github.com/tydeno/Ploto/tree/main#plotting-with-your-pool--farmer-key)
   * [Plotting for pools](https://github.com/tydeno/Ploto/tree/main#plotting-for-pools)
   * [About replotting](https://github.com/tydeno/Ploto/tree/main#about-replotting)
   * [About running custom plotters](https://github.com/tydeno/Ploto/tree/main#about-running-custom-plotters)
   * [Status Codes and their meaning (Chia official plotter)]()
   * [Status Codes and their meaning (madmax/stotik custom plotter)]()
* [How to](https://github.com/tydeno/Ploto/tree/main#prereqs)
 	* [Install Ploto](https://github.com/tydeno/Ploto/tree/main#how-to-install-ploto)
 	* [Spawn Plots](https://github.com/tydeno/Ploto/tree/main#how-to-spawn-plots)
 	* [Get Jobs](https://github.com/tydeno/Ploto/tree/main#how-to-get-jobs)
 	* [Move Plots](https://github.com/tydeno/Ploto/tree/main#how-to-move-plots)
* [FAQ](https://github.com/tydeno/Ploto/tree/main#faq)

## Contact
https://www.ploto.rocks/

For general chatting, issues and support of how to use Ploto, you may join the Discord below.
If you find any bugs, do not hesitate to create or update an issue directly here in GitHub.

* ### [Ploto Discord](https://discord.gg/NgEsMDWWT5)

## How you can support this project
In case you'd like to to support the development of Ploto in a monetary way, you may donate in the currencies below with the according wallet adresses:
* XCH Adress: xch19ddu8lxgq2g6ssnk7kmexmwxazapvdt7fp8cekeun0cdm9jt6vxsqg30yt

Or trough my [GitHub Sponsoring page](https://github.com/sponsors/tydeno)


# PlotoSpawn
TLDR: It plots 1x plot on each TempDrive (if you have 6x TempDrives = 6x parallel Plot Jobs) as long as you want it to and as long as you have OutDrive space.
When and where Plots are spawned is defined by PlotoSpawnerConfig.json.

Ploto checks periodically, if a TempDrive and OutDrive is available for plotting. 
If there is no TempDrive available, or no OutDrive, Ploto checks again in amount of minutes defines in $config.IntervallToCheckInMinutes

When there is one available, Ploto determines the best OutDrive (most free space) and calls chia.exe to start the plot.
Ploto iterates once through all available TempDrives and spawns a plot per each TempDrive (as long as enough OutDrive space is given).
After that, Ploto checks if amount Spawned is equal as defined as input. If not, Ploto keeps going until it is.

### Understanding Plot and OutDrives
To define your temp and outdrives you use the config.
To define a folder within a drive, use following notation: 
`F:\\afolder,E:\\anotherone,K:\\somefolder`

to define several drivesuse :`F:,E:,K:`

Important: There are no spaces allowed betwen the ","!


### About -2 drives
Ploto now supports -2 drives. You define them just like plot and tempdrives. On each Job Ploto checks if a -2 drive is plottable. If yes, it spawns the job using that -2 drive. If not, it spawns the job without the drive. 

> -2 [tmp dir 2]: Define a secondary temporary directory for plot creation. This is where Plotting Phase 3 (Compression) and Phase 4 (Checkpoints) occur. Depending on your OS, > -2 might default to either -t or -d. Therefore, if either -t or -d are running low on space, it's recommended to set -2 manually. The -2 dir requires an equal amount of > > working space as the final size of the plot.

### About parallelization on separate disks
Using the Parameter "-MaxParallelJobsOnAllDisks", you can define how many Plots Jobs overall there should be in parallel. So this will be your hard cap. If there are as many jobs as you defined as max, PlotoSpawner wont spawn further Jobs. This keeps your system from overcommiting.
Using the Parameter "-BufferSize", you can define RAM used per process, the default value is 3390MB.
Using the Parameter "-Thread", you can define threads used per process the default value is 2 threads.

### About parallelization on the same disk
Using "MaxParallelJobsOnSameDisks" you can define how many PlotsJobs there should be in parallel on a single disk. This param affects all Disks that can host more than 1 Plot. Ploto checks each disk for free space and determines the amount of plots it can hold as a tempDrive. Also being aware of the jobs in progress. It will spawn as many jobs as possible by the disk until it reached either the hard cap of -MaxParallelJobsOnAllDisks or -MaxParallelJobsOnSameDisk


If I launch PlotoSpawner with these params like this:
```
WaitTimeBetweenPlotOnSeparateDisks = 15
WaitTimeBetweenPlotOnSameDisk = 60
MaxParallelJobsOnAllDisks = 7
MaxParallelJobsOnSameDisk = 3
```
The following will happen:

PlotoSpawner will at max spawn 7 parallel jobs, and max 3 Jobs in parallel on the same disk. This means for my temp drive setup the following:
| Name          | DriveLetter | Type   | Size      | Total Plots in parallel |
|---------------|----------|--------|--------------|-------------------------|
|ChiaPlot 1 | I:\ | SATA SSD | 465 GB | 1
|ChiaPlot 2 | H:\ | SATA SSD | 465 GB | 1
|ChiaPlot 3 | E:\ | SATA SSD | 465 GB | 1
|ChiaPlot 4 | Q:\ | SATA SSD | 1810 GB | 3
|ChiaPlot 5 | J:\ | NVME SSD PCI 16x | 465 GB | 1

So there will be 7x Plot jobs running in parallel with defined wait time in minutes betwen jobs on each disk and the same Disk. 
Drive Q:\ will never see more than 3x Plots in parallel as defined by -MaxParallelJobsOnSameDisk 3

When a job is done and a temp drive becommes available again, PlotoSpawner will spawn the next jobs, until it has spawned the amount you specified as -InputAmountToSpawn or it reaches it max cap.

PlotoSpawner redirects the output of chia.exe to to the following path: 
* C:\Users\Tydeno\.chia\mainnet\plotter\ (Tydeno is adjusted with your Username)

And creates two log files for each job with the following notation:
* PlotoSpawnerLog_30_4_0_49_49ab3c48-532b-4f17-855d-3c5b4981528b_Tmp-E_Out-K.txt (chia.exe output)
* PlotoSpawnerLog_30_4_0_49_49ab3c48-532b-4f17-855d-3c5b4981528b_Tmp-E_Out-K'@'Stat.txt (Additional Info from PLotoSpawner)

### Alright, I saw that Discord Bot picture, how do I use that?
You can control whether you want to receive and what kind of alerts in a handy config file.
Now change the WebhookUrl to match the URL of your Discord Servers Webhook and enable/disable alert notifications as you wish. [How to create a Discord Webhook](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks). 

Set the Name for your plotter, as it allows you to distinguish between alerts for each plotter. You may also use several Webhooks in different Discord Channels.

When you Start Ploto, make sure you also specified the Parameter "EnableAlerts" in the config. If not specified, your Disocrd remains silent.

### Plotting with your Pool & Farmer Key
If your keys are not the present on the machine you want to plot, you need to specify -p (PoolKey) and -f (FarmerKey) param of your farm, in order to farm these plots correctly.
If no -pf and -f param are specified, it uses the available keys.

### Plotting for pools
Ploto now supports pool plotting, since we know the needed commands. 
Be advises that this in BETA mode right now.

To create portable pool plots, we need to use the param "P2Singleton" in the config. 
Therefore we need to create a singleton that points to a pool first, and then we can start plotting. 
If you want to plot portable pools, make sure your PoolKey is NOT specified in the config, as this will mess thing up.

### About replotting
Ploto now supports the ability to replot existing drives. This assumes you have one or more drives with final plots that are actively being farmed.
If you now launch Ploto with 'Replot: "true"' and your denom for your ReplotDrives (drives you want to replot), the following will happen:

1. Ploto launches a Watchdog that looks for jobs that are about to enter phase 4 and have property "IsReplot=True"
2. If there is a job entering phase 4 with "IsReplot=True", it deletes the oldest plot on the drive, the replotJob uses as OutDrive.

All ReplotJobs launchd, will use the the drives as OutDrive, that match the ReplotDriveDenom. So if you replot, make sure you set the InputAmountToSpawn to exactly the number of Plots you want to Replot. Currently Ploto does not know with which keys/singletons a Plot was plotted. So it keeps going and potentially deletes already replotted jobs, if InputAmountToSpawn is too high. This can lead to unneccesary wear & tear.

The replotting mechanism features a * `"ReplotPlotsOlderThan": "20.6.2021` parameter in config. It allows you to define which plots shall be replotted and which not by specifying a date as seen above. This is a mandatory param if you want to replot, as its the only way to determine which plots shall be replotted
It picks those drives that have final plots on it for replotting. If there is no drive that has plots to replot, its chooses the best suited OutDrive by free space. If there is none, it aborts. 

## About running custom plotters
Ploto now supports custom plotters. This functionality was implemented to support madMAx43v3r's chia-plotter. It also allows to use sever other forks, like Stotiks and catchmeifyoucans release.

To run a custom plotter, make sure you define "PlotterUsed: Stotik" in your config. Use the value "Stotitk" for all custom plotters.
Also make sure that you add the fullpath of the customplotter to the config. Then simply run Ploto as usually.

When setting up your conifg; Take into consideration how your custom Plotter works!

## Prereqs
The following prereqs need to be met in order for Ploto to function properly:
* chia.exe is installed (version is determined automatically) 
* You may need to change PowerShell Execution Policy to allow the script to be imported.

You can do it by using Set-ExecutionPolicy like this:
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

* In some cases, you may need to set ExecutionPolicy to "Bypass" (If it does not allow Import with "RemoteSigned")

```powershell
Set-ExecutionPolicy Bypass -Scope CurrentUser
```

## How to Install Ploto
1. Make sure your Out and TempDrives are named accordingly
2. Download Ploto as .ZIP from [here](https://github.com/tydeno/Ploto/archive/refs/heads/main.zip)
3. Launch `Install-Ploto.ps1` (If your User does not have Admin right, run it as Admin)
4. Let the Script run trough and if you do not have a config yet, let the Script create one for you

## How to Spawn Plots
1. Launch PlotoSpawner
```powershell
Start-PlotoSpawns
```
```
PlotoSpawner @ 4/30/2021 3:19:13 AM : Spawned the following plot Job:
JobId :           ad917660-9de9-4810-8977-6ace317d7ddb
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
2. Leave the PowerShell Session open (can be minimized)

## How to get Jobs
1. Open another PowerShell session 
2. Launch Get-PlotoJobs and format Output
```powershell
Get-PlotoJobs | ft
```

```
JobId                                PlotId                                                           PID   Status       TempDrive OutDrive LogPath
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
JobId                 : 10e6deb5-6a13-4a0d-9c77-8c65d717bf6b
PlotId                : 332f93247b707d3bcf977889edff9bcbc9f0c3d3e30bfd941328bd7bf424f03a
PID                   : 6648
Status                : 3.6
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
Get-PlotoJobs -PerfCounter | ? {$_.Status -ne "Completed"} | select PID, Status, TempDrive, OutDrive, cpuUsage, memUsageMB, PlotSizeOnDisk | ft
```

```
PID  Status       TempDrive OutDrive cpuUsagePercent memUsageMB PlotSizeOnDisk
---  ------------ --------- -------- --------------- ---------- --------------
8144 3.5          Q:        K:                  0.58       2130 89.46 GB
6648 3.6          Q:        D:                  6.24       2676 48.03 GB
5444 3.6          Q:        D:                  3.29       2676 48.03 GB
```

### Status Codes and their meaning (Chia official plotter)
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
"Renamed final file*" {$StatusReturn = "Completed"}
```

### Status Codes and their meaning (madmax/stotik custom plotter)
See below for a definition of what phase coe is associated with which chia.exe log output.
```powershell
"Process ID*" {$StatusReturn = "Initializing"}
"Plot Name*" {$StatusReturn = "1.1"}
"*P1] Table 1*" {$StatusReturn = "1.2"}
"*P1] Table 2*" {$StatusReturn = "1.3"}
"*P1] Table 3*" {$StatusReturn = "1.4"}
"*P1] Table 4*" {$StatusReturn = "1.5"}
"*P1] Table 5*" {$StatusReturn = "1.6"}
"*P1] Table 6*" {$StatusReturn = "1.7"}
"*P1] Table 7*" {$StatusReturn = "1.8"}
"Phase 1 took*" {$StatusReturn = "2.0"}
"*P2] Table 7 rewrite*" {$StatusReturn = "2.1"}
"*P2] Table 6 rewrite*" {$StatusReturn = "2.2"}
"*P2] Table 5 rewrite*" {$StatusReturn = "2.3"}
"*P2] Table 4 rewrite*" {$StatusReturn = "2.4"}
"*P2] Table 3 rewrite*" {$StatusReturn = "2.5"}
"*P2] Table 2 rewrite*" {$StatusReturn = "2.6"}
"Phase 2 took*" {$StatusReturn = "3.0"}
"*P3-2] Table 2 rewrite took*" {$StatusReturn = "3.1"}
"*P3-2] Table 3 rewrite took*" {$StatusReturn = "3.2"}
"*P3-2] Table 4 rewrite took*" {$StatusReturn = "3.3"}
"*P3-2] Table 5 rewrite took*" {$StatusReturn = "3.4"}
"*P3-2] Table 6 rewrite took*" {$StatusReturn = "3.5"}
"*P3-2] Table 7 rewrite took*" {$StatusReturn = "3.6"}
"Phase 3 took*" {$StatusReturn = "4.0"}
"*P4] Finished writing C2 table*" {$StatusReturn = "4.1"}
"Phase 4 took*" {$StatusReturn = "4.2"}
"Total plot creation*" {$StatusReturn = "4.2"}
"Started copy*" {$StatusReturn = "4.3"}
```

## How to Stop Jobs
1. Open a PowerShell session and import Module "Ploto" or use an existing one.
2. Get PlotJobSpawnerId of Job you want to stop by calling "Get-PlotJobs"
3. Stop the process:

```powershell
Stop-PlotoJob -JobId cfff29b8-fdee-4988-ae89-9db035d809bc
```
or if you want to Stop all Jobs that are aborted:
```powershell
Remove-AbortedPlotoJobs
```

## How to Move Plots
As you may have noticed in my ref setup: I have little OutDrive storage capacity (1TTB roughly).
This is only possible as I continously move the final Plots to my farming machine with lots of big drives. 

I do this by moving plots to a external drive and plug that into my farmer, and sometimes I also transfer plots across my network (not the fatest, thats why I kind of have to do  the running around approach)

PlotoMover helps to automate this process. In PlotoSpawnerConfig.json, you can define several drives you want to move your final plots to. Mover then checks all defined outdrives for final plots and moves one by one trough Background Inteligence Transfer Service (BITS) to the desired location. In order for remote destination targets (your farmers/harvesters) to recognized correctly, these drives needed to be mapped as network drives and have a volume letter assigned (eg Z:\) for mover to tbe able to grab them.

To enable mover,, in the config set EnablerMover to "true" and define the PathsToMovePlotsTo according the example config.
Then the next time you launch `Start-PlotoSpawns` mover will be launched aswell.


## How to Check Farm Logs
If you want to peek at your farm logs you can use Check-PLotoFarmLogs:
1. Launch a PowerShell session and Import Ploto Module
2. Launch Check-PlotoFarmLogs with your desired LogLevel. It accepts EligiblePlots, Error and Warning.
```powershell
Get-PlotoFarmLog -LogLevel error
```

```
2021-05-03T23:34:45.532 full_node full_node_server        : ERROR    Exception:  <class 'concurrent.futures._base.CancelledError'>, closing connection {'host': '127.0.0.1', 'port': 8449}. Traceback (most recent call last):
concurrent.futures._base.CancelledError
2021-05-03T23:34:48.454 full_node full_node_server        : ERROR    Exception:  <class 'concurrent.futures._base.CancelledError'>, closing connection {'host': '127.0.0.1', 'port': 8449}. Traceback (most recent call last):
concurrent.futures._base.CancelledError
2021-05-03T23:34:52.548 full_node full_node_server        : ERROR    Exception:  <class 'concurrent.futures._base.CancelledError'>, closing connection {'host': '127.0.0.1', 'port': 8449}. Traceback (most recent call last):
concurrent.futures._base.CancelledError
2021-05-03T23:35:03.845 full_node full_node_server        : ERROR    Exception:  <class 'concurrent.futures._base.CancelledError'>, closing connection {'host': '127.0.0.1', 'port': 8449}. Traceback (most recent call last):
concurrent.futures._base.CancelledError
2021-05-03T23:35:08.720 full_node full_node_server        : ERROR    Exception:  <class 'concurrent.futures._base.CancelledError'>, closing connection {'host': '127.0.0.1', 'port': 8449}. Traceback (most recent call last):
concurrent.futures._base.CancelledError
2021-05-03T23:35:15.360 full_node full_node_server        : ERROR    Exception:  <class 'concurrent.futures._base.CancelledError'>, closing connection {'host': '127.0.0.1', 'port': 8449}. Traceback (most recent call last):
concurrent.futures._base.CancelledError
```
# FAQ
> Can I shut down the script when I dont want Ploto to spawn more Plots?

Yep. The individual Chia Plot Jobs wont be affected by that.

> My config does not laod due to an error. What can I do?
 
Make sure all '"' and "," are set correctly. Also make sure for PLotoPathToModule you use "/" instead of "\\".

> Ploto wont start due to an error. What can I do?

Try flushing your logs. You can simply move them to another folder. This is due to the fact that Ploto handles log different than the Chia GUI/CLI Plotter.

# Knowns Bugs and Limitations
Please be aware that Ploto was built for my specific setup. I try to generalize it as much as possible, but thats not easy-breezy.
So what works for me, may not ultimately work for you. 
Please also bear in mind that unexpected beahviour and or bugs are possible.

These are known:
* Only works when Drives are dedicated to plotting (dont hold any other files)
* If you start to use Ploto and you have Logs created by GUI or any other manager in C:\Users\me.chia\mainnet\plotter\, Get-PlotoPlots wont the able to read the status.
Make sure you delete/move all existing Logs in said path. 
* Can only display and stop PlotJobs that have been spawned using PlotoSpawner
* Using the -PerfCounter param on Get-PlotoJobs takes a while to load
* PlotoMover is very limited right now, may break copy jobs at times (Bits)
* PlotoMover does not check for available free space on network drives as its unaware of it (only does for local drives)
* If you have more than 1x version of chia within your C:\Users\Me\AppData\Local\chia-blockchain folder, Ploto wont be able to determine the version and will fail.
  Make sure theres only one available folder with chia.exe (eg. app-1.1.3)

## Function details
For a detailled documentation of all available functions, their params in- and outputs see the links below, or 
[here](https://github.com/tydeno/Ploto/blob/main/Functions.md)
### PlotoSpawn
* [Get-PlotoOutDrives](https://github.com/tydeno/Ploto/blob/main/Functions.md#get-plotooutdrives)
* [Get-PlotoTempDrives](https://github.com/tydeno/Ploto/blob/main/Functions.md#get-plototempdrives)
* [Invoke-PlotoJob](https://github.com/tydeno/Ploto/blob/main/Functions.md#invoke-plotojob)
* [Start-PlotoSpawn](https://github.com/tydeno/Ploto/blob/main/Functions.md#start-plotospawns)

### PlotoManage
* [Get-PlotoJobs](https://github.com/tydeno/Ploto/blob/main/Functions.md#get-plotojobs)
* [Stop-PlotoJob](https://github.com/tydeno/Ploto/blob/main/Functions.md#stop-plotojob)
* [Remove-AbortedJobs](https://github.com/tydeno/Ploto/blob/main/Functions.md#remove-abortedjobs)

### PlotoMove
* [Get-PlotoPlots](https://github.com/tydeno/Ploto/blob/main/Functions.md#get-plotoplots)
* [Move-PlotoPlots](https://github.com/tydeno/Ploto/blob/main/Functions.md#move-plotoplots)
* [Start-PlotoMove](https://github.com/tydeno/Ploto/blob/main/Functions.md#start-plotomove)
### PlotoFarmer
* [Get-PlotoFarmLog](https://github.com/tydeno/Ploto/blob/main/README.md#check-farm-logs)
