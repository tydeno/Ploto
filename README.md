# Ploto
A Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself.

# How it works
TLDR: It plots 1x plot on each TempDrive (if you have 6x TempDrives = 6x parallel Plot Jobs) as long as you want it to and as long as you have OutDrive space.

Ploto checks periodically, if a TempDrive and OutDrive is available for plotting. 
If there is no TempDrive available, or no OutDrive, Ploto checks again in 3600 seconds.

When there is one available, Ploto determines the best OutDrive (most free space) and calls chia.exe to start the plot.
Ploto iterates once through all available TempDrives and spawns a plot per each TempDrive (as long as enough OutDrive space is given).
After that, Ploto checks if amount Spawned is equal as defined as input. If not, Ploto keeps going until it is.

# Functions explained
Ploto consists currently of these functions:
* Get-PlotoOutDrives
* Get-PlotoTempDrives
* Spawn-PlotoPlots
* Manage-PlotoSpawns


## Get-PlotoOutDrives
## Get-PlotoTempDrives
## Spawn-PlotoPlots
## Manage-PlotoSpawns

# Parameters explained
This section describes the params for the Main Function "Manage-PlotoSpawns". These params are passed along the stack to all needed helper functions.

## -InputAmountToSpawn

Defines the amount of total plots the Script will manage to plot. Stops when that count ot plots is reached. 
If disk space is running low, the script will continue, but wont launch any new plots until there is disk space again. 

## -OutDriveDenom

This param defines your OutDrives. An OutDrive in Ploto Terms is the drive chia stores the final plot to. Usually these are your big capacity HDDs.
Use a denonimator that all your chia out drives have in common. For me, all Chia Out drives (drives I store my plots) are called "ChiaOut 1-2".
So for me I set the param to "out".

## -TempDriveDenom

The same as -OutDriveDenom but for your temporary drives chia uses to actually plot on. Usually these are are your SATA/NVMe SSDs.
Use a denonimator that all your chia temp drives have in common. For me, all Chia Temp drives (drives I plot on) are called "ChiaPlot 1-4".
So for me I set the param to "plot".

# FAQ
Can I shut down the script when I dont want Ploto to spawn more Plots?
Yep. The individual Chia Plot Jobs wont be affected by that.

# HowTo Use it
```powershell
Manage-PlotoSpawns -InputAmountToSpawn 12 -OutDriveDenom "out" -TempDriveDenom "plot"
```
This will create 12 Plots across all drives that have "plot" in the name properrty and storing these plots on all drives having "out" in their name property.
Ploto attempts to parallelilze as much as possible, meaning that it uses each temp disk in parallel bot only for 1 plot job at the time. If a plot job is running on a temp disk, Ploto wont use that disk. 

