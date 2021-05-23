## Ploto 
A Windows PowerShell based Chia Plotting Manager. 
Consists of a PowerShell Module that allows to spawn, manage and move plots.

Also informs you in Discord about spawned jobs. 
And if you like, you may define an Intervall upon which Plotofy sends you notifications about whats going on.

![image](https://user-images.githubusercontent.com/83050419/118192418-662f0500-b446-11eb-9340-e919234d3d5f.png)
![image](https://user-images.githubusercontent.com/83050419/118396387-a57c7200-b64f-11eb-8ef5-0526bd8cb3c6.png)
![image](https://user-images.githubusercontent.com/83050419/118396379-9eedfa80-b64f-11eb-9a83-1262a6625f3a.png)

![image](https://user-images.githubusercontent.com/83050419/118398002-f479d580-b656-11eb-82f7-a92a4a0af4a9.png)

## Contact
For general chatting, issues and support of how to use Ploto, you may join the Discord below.
If you find any bugs, do not hesitate to create an issue directly here in GitHub.

* [Ploto Discord](https://discord.gg/NgEsMDWWT5)

## How you can support this project
There are several things you can do:
* Use Ploto and provide feedback about what works, what not, and what features you'd like to see
* Spread the word, so that more people use and test it 
* If you can and want to you're of course also invited to contribute your pieces of PowerShell to the module by submitting pull requests

In case you'd like to to support the development of Ploto in a monetary way, you may donate in the currencies below with the according wallet adresses:
* XCH Adress: xch1rz7auuuuykntmkp35xr95mhyx6tqdzr20q8gwmnxdg2ylx5j3r5qxl3mv8
* BTC Adress: 36JQnBmN4XLuS4gHEkAFfoQVjkjnpqGuo3

# What effect sponsoring has on the development of Ploto
All the work I'm doing on Ploto happens in my time off-work, most of the times until deep in the night.
Your sponsoring helps me to fuel the ongoing development of a PowerShell based toolset for chia farming.
 It allows me to spend more time on it, fix out the bugs and keep adding new features.

Your donations will be mainly used as gas to fuel the development with:

- Coffee
- Energydrinks
- Pizza

So if you'd like to support me and my work; Why not get me a coffee? :)


# PlotoSpawn
TLDR: It plots 1x plot on each TempDrive (if you have 6x TempDrives = 6x parallel Plot Jobs) as long as you want it to and as long as you have OutDrive space.
When and where Plots are spawned is defined by PlotoSpawnerConfig.json which looks like this:

```
{
    "EnableAlerts": "false",            | Enable JobSpawned Alerts (Webhook config in PlotoAlertsConfig.json)
    "ChiaWindowStyle": "hidden",        | Determines Window Style of chia.exe (Allowed Values: normal, hidden, maximized, minimized)

    "DiskConfig": [
      {
        "TempDriveDenom": "plot",      | The common denominator for all your TempDrives
	"Temp2Denom": "t2",	       | The common denominator for all your Temp2Drives
        "OutDriveDenom": "out",        | The common denominator for all your OutDrives
	"EnableT2": "true"             | Determines if Ploto uses Temp2 drives. Must be set to true along with temp2denom defined
      }
    ],

    "JobConfig": [
        {
	  "IntervallToCheckInMinutes": "5",   	      | Defines the time Ploto waits between each iteration to check for available tempd drives again 
    	  "InputAmountToSpawn": "100",                | Amount of jobs maximal to be spawned in this launch of ploto
          "WaitTimeBetweenPlotOnSeparateDisks": "15", | Wait time in minutes Ploto waits until a new job on another disk is spawned
          "WaitTimeBetweenPlotOnSameDisk": "30",      | Wait time in minutes Ploto waits until a new job on the same disk is spawned
          "MaxParallelJobsOnAllDisks": "6", 	      | Maximum amount of parallel jobs allowed on all disks combined
          "MaxParallelJobsOnSameDisk": "2", 	      | Maximum amount of parallel jobs allowed on a single disk. Affects all disks of all sizes. Set to you're highest disk.
	  "MaxParallelJobsInPhase1OnSameDisk": "2",   | Maximum amoumt of parallel jobs allowed on the same in  phase 1
          "MaxParallelJobsInPhase1OnAllDisks" : "10", | Maximum amoumt of parallel jobs allowed on all disks in  phase 1
          "StartEarly": "true",		              | Enable EarlyStart (when jobs completed StatusEarlyPhase)
          "StartEarlyPhase": "3",                     | Defines when a job should be early started. If a job completes phase 3 in this example, it is not considered an active                                                           job anymore and makes room for another to spawn early.
          "BufferSize": "1000",
          "Thread": "1",
          "Bitfield": "true"
        }
      ]
    "SpawnerAlerts": [
	    {
	      "DiscordWebhookURL": "https://discord.com/api/webhooks/xxxxxxxxxxxxxxxx",    | EndpointURL of your discord Webhook 
	      "WhenJobSpawned": "true",                                                
	      "WhenNoOutDrivesAvailable": "true",
	      "WhenJobCouldNotBeSpawned": "true"
	    }
	  ],

	  "PlotoFyAlerts": [
	    {
	      "DiscordWebhookURL": "https://discord.com/api/webhooks/xxxxxxxxxxxxxx",    | EndpointURL of your discord Webhook 
	      "PeriodOfReportInHours": "1",                                              | Period the report is send out and covering
	      "PathToPloto": "C:/Users/me/Desktop/Ploto/Ploto.psm1"                      | Absolute path to the module as the background jobs needs to load it again
	    }
	  ]
}
```
Ploto checks periodically, if a TempDrive and OutDrive is available for plotting. 
If there is no TempDrive available, or no OutDrive, Ploto checks again in amount of minutes defines in $config.IntervallToCheckInMinutes

When there is one available, Ploto determines the best OutDrive (most free space) and calls chia.exe to start the plot.
Ploto iterates once through all available TempDrives and spawns a plot per each TempDrive (as long as enough OutDrive space is given).
After that, Ploto checks if amount Spawned is equal as defined as input. If not, Ploto keeps going until it is.

## Understanding Plot and OutDrives
PlotoSpawner identifies your drives for temping and storing plots by a common denominator you specify. 
This means that all drives that match that denominator, will be used as either Temp or OutDrive.

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

### About -2 drives
Ploto now supports -2 drives. You define them just like plot and tempdrives. On each Job Ploto checks if a -2 drive is plottable. If yes, it spawns the job using that -2 drive. If not, it spawns the job without the drive. The implementation is rather basic now, as I currently do not use -2 drives for my plotting and may not understand the usage of this param correctly yet. 


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
* C:\Users\me\.chia\mainnet\plotter\

And creates two log files for each job with the following notation:
* PlotoSpawnerLog_30_4_0_49_49ab3c48-532b-4f17-855d-3c5b4981528b_Tmp-E_Out-K.txt (chia.exe output)
* PlotoSpawnerLog_30_4_0_49_49ab3c48-532b-4f17-855d-3c5b4981528b_Tmp-E_Out-K'@'Stat.txt (Additional Info from PLotoSpawner)



### Alright, I saw that Discord Bot picture, how do I use that?
You can control whether you want to receive and what kind of alerts in a handy config file.
This config file belongs in the following folder: C:\Users\YourUsserName\.chia\mainnet\config. Make sure you copy it there, as Ploto expects to find it at that location.
Now change the WebhookUrl to match the URL of your Discord Servers Webhook and enable/disable alert notifications as you wish. [How to create a Discord Webhook](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks). 

Set the Name for your plotter, as it allows you to distinguish between alerts for each plotter. You may also use several Webhooks in different Discord Channels.

When you Start Ploto, make sure you also specified the Parameter "EnableAlerts" in the config. If not specified, your Disocrd remains silent.


# Prereqs
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

# How to
If you want to use Ploto follow along.

## Spawn Plots
1. Make sure your Out and TempDrives are named accordingly
2. If you start to use Ploto and you have Logs created by GUI or any other manager in C:\Users\me.chia\mainnet\plotter\, Get-PlotoJobs wont the able to read the status.
Make sure you delete/move all existing Logs in said path. 
3. Download Ploto as .ZIP from [here](https://github.com/tydeno/Ploto/archive/refs/heads/main.zip)
4. Get the PlotoSpawnerConfig.json, adjust it to your needs and make sure its stored in C:\Users\YourUserName\.chia\mainnet\config
5. Import-Module "Ploto" (make sure you change the path to Ploto.psm1 to reflect your situation)
```powershell
Import-Module "C:\Users\Me\Downloads\Ploto\Ploto.psm1"
```
4. Launch PlotoSpawner
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

5. Leave the PowerShell Session open (can be minimized)

## Setup Discord Alerts for spawned Jobs
To start with your Discord Alerts, the first step is to get the PlotoAlertConfig.json file and edit it to your wishes.

1. Edit PlotoSpawnerConfig.json
2. Set WebhookURL (Your Discord Servers Webhook)
3. Set PlotterName (A freely choosen name for your plotter, to be sent in the notification)
4. Set your config of alerts. Disable/Enable the alerts your interested with true/false.
5. Make sure you copy/move the edited .json to the folder: C:\Users\YourUserName\.chia\mainnet\config. If its not there, it wont work.
6. Open a PowerShell Session
7. Edit PlotoSpawnerConfig to EnableAlerts = true
8. Import-Module "C:\Users\me\desktop\Ploto\Ploto.psm1" (make sure you change the path to Ploto.psm1 to reflect your situation)
9. Launch Start-PlotoSpawns:
```powershell
Start-PlotoSpawns 
```
## Setup Discord Alerts for periodical summary of jobs completed and in progress
To configure the behaviour of periodical summary reports in discord, we also use the PlotoAlertConfig.json stored in C:\Users\YourUserName\.chia\mainnet\config.

1. Edit PlotoSpawnerConfig.json
2. Set WebhookURL (Your Discord Servers Webhook). You may use the same or a different WebhookURL than what PlotoSpawner Alerts uses. This allows you to separate channels in Discord for various alerts. I use this separate for each plotter I habve:
![image](https://user-images.githubusercontent.com/83050419/118396604-892d0500-b650-11eb-8b5a-f05939a292b3.png)
3. Set the intervall upon which you would like to receive the summary. This also affects the period PlotoFy uses to check for events. For example: If 1 is specified (1hr), PlotoFy will each hour lookup jobs that were copleted in the last hours, and all active jobs in progress and wrap this in a notification.
If there are no jobs completed within the period, PlotoFy will only send the notification for the jobs in progress. If there are no completed and no jobs in progress, PlotoFy tells you with a notification, that Ploto seems not running.
4. Set the Path to Ploto Module (where its stored right now)
5. Make sure you copy/move the edited .json to the folder: C:\Users\YourUserName\.chia\mainnet\config. If its not there, it wont work.
6. Open a new PowerShell Session.
7. Import-Module "C:\Users\me\desktop\Ploto\Ploto.psm1" (make sure you change the path to Ploto.psm1 to reflect your situation)
8. Launch PlotoFy using the cmd below:
```powershell
Start-PlotoFy
```
As PlotoFy launched a backgroundJob that continously calls "Request-PlotoFySummaryReport", for almost infinity, you may wont to stop that job at some point. To do this, you can use the following commands:

1. Get-Job to get the current running PowerShell Jobs:
```powershell
Get-Job
```
```
Id     Name            PSJobTypeName   State         HasMoreData     Location             Command
--     ----            -------------   -----         -----------     --------             -------
1      Job1            BackgroundJob   Running       True            localhost            ...
```

2. Stop the Job, using Stop-Job
```powershell
Stop-Job -Id 1
```

3. And to clean up, we need to deleted the stopped job.
```powershell
Get-Job | where-object {$_.State -eq "Stopped"} | Remove-Job
```

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

### Status Codes and their meaning
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

## Stop Jobs
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

```powershell
Move-PlotoPlots -DestinationDrive "\\Desktop-xxxxx\d" -OutDriveDenom "out" -TransferMethod Move-Item
```

Please be aware that if you use UNC paths as Destination, PlotoMover cannot grab the free space there and just fires off.

## But I want to do it continously
Sure, just use Start-PlotoMove with your needed params:

```powershell
Move-PlotoPlots -DestinationDrive "\\Desktop-xxxxx\d" -OutDriveDenom "out" -TransferMethod Move-Item
```

Please be aware that if you use UNC paths as Destination, PlotoMover cannot grab the free space there and just fires off.

## Check Farm Logs
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
 
Make sure all '"' and "," are set correctly. Also make sure for PLotoPathToModule you use "/" instead of "\".

> Ploto wont start due to an error. What can I do?

Try flushing your logs. You can simply move them to another folder. This is due to the fact that Ploto handles log different than the Chia GUI/CLI Plotter.

# Knowns Bugs and Limitations
Please be aware that Ploto was built for my specific setup. I try to generalize it as much as possible, but thats not easy-breezy.
So what works for me, may not ultimately work for you. 
Please also bear in mind that unexpected beahviour and or bugs are possible.

These are known:
* Only works when plotting in root of drives
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
