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
Ploto consists currently of these main functions:
* Get-PlotoOutDrives
* Get-PlotoTempDrives
* Spawn-PlotoPlots
* Manage-PlotoSpawns


## Get-PlotoOutDrives
Gets all Windows Volumes that match the -OutDriveDenom parameter and checks if free space is greater than 107 GB (amount currently used by final chia plots).
It wraps all the needed information of the volume like DriveLetter, ChiaDriveType, VolumeName, a bool IsPlootable, and the calculated amount of plots to hold into a object and returns the collection of objects as the result of that function.

Example:

```powershell
Get-PlotoOutDrives -OutDriveDenom "out"
```
![alt text](https://github.com/tydeno/Ploto/blob/main/Pictures/CAP_OutDrives1.PNG)


## Get-PlotoTempDrives
Gets all Windows Volumes that match the -TempDriveDenom parameter and checks if free space is greater than 270 GB (amount currently used by chia plots as temp storage).
It wraps all the needed information of the volume like DriveLetter, ChiaDriveType, VolumeName, a bool IsPlootable, and the calculated amount of plots to temp, whether it has a plot in porgress (determined by checking if the drive contains any file) into a object and returns the collection of objects as the result of that function.

Example:

```powershell
 Get-PlotoTempDrives -TempDriveDenom "plot"
```

![alt text](https://github.com/tydeno/Ploto/blob/main/Pictures/CAP_TempDrives1.PNG)

## Spawn-PlotoPlots
Calls Get-PlotoTempDrives to get all Temp drives that are plottable. For each tempDrive it determines the most appropriate OutDrive (using Get-PlotoOutDrives function), stitches together the ArgumentList for chia and fires off the chia plot job using chia.exe. For each created PlotJob the function creates an Object and appends it to a collection of objects, which are returned upon the function call. 

Example:

```powershell
Spawn-PlotoPlots -OutDriveDenom "out" -TempDriveDenom "plot
```

![alt text](https://github.com/tydeno/Ploto/blob/main/Pictures/CAP_PlotoSpawner.PNG)

## Manage-PlotoSpawns
Main function that nests all else.
Continously calls Spawn-PlotoSpawns and states progress and other information. It runs until it created the amount of specified Plot by using the -InputAmountToSpawn param.

Example:

```powershell
Manage-PlotoSpawns -InputAmountToSpawn 12 -OutDriveDenom "out" -TempDriveDenom "plot"
```

Example with SMS Notifications (trough Twilio):

```powershell
Manage-PlotoSpawns -InputAmountToSpawn 12 -OutDriveDenom "out" -TempDriveDenom "plot" -SendSMSWhenJobDone $true -AccountSid $TwilioAccountSid -AuthToken $TwilioAuthToken -from $TwilioNumber -to $YourNumber
```
![alt text](https://github.com/tydeno/Ploto/blob/main/Pictures/CAP_PlotoManager.PNG)

# helper Functions used 
For sending SMS for notifications, Ploto uses these self-crafted Twilio helper wrapprs.
## Create-TwilioCredential
## Send-SMS


# Parameters explained
This section describes the params for the Main Function "Manage-PlotoSpawns". These params are passed along the stack to all needed helper functions.

## -InputAmountToSpawn

Defines the amount of total plots the Script will manage to plot. Stops when that count ot plots is reached. 
If disk space is running low, the script will continue, but wont launch any new plots until there is disk space again. 

## -OutDriveDenom

This param defines your OutDrives. An OutDrive in Ploto Terms is the drive chia stores the final plot to. Usually these are your big capacity HDDs.
Use a denonimator that all your chia out drives have in common. For me, all Chia Out drives (drives I store my plots) are called "ChiaOut 1-2".
So for me I set the param to "out". 

Make sure your OutDriveDenom is unique to your real HDD you want to use to store chia Plots. If a Volume has your OutDriveDenom in their VolumeName, they will also be used, if enough free space is given.

## -TempDriveDenom

The same as -OutDriveDenom but for your temporary drives chia uses to actually plot on. Usually these are are your SATA/NVMe SSDs.
Use a denonimator that all your chia temp drives have in common. For me, all Chia Temp drives (drives I plot on) are called "ChiaPlot 1-4".
So for me I set the param to "plot". 

Make sure your TempDriveDenom is unique to your real SSDs you want to use to create chia Plots. If a Volume has your TempDriveDenom in their VolumeName, they will also be used, if enough free space is given.

# FAQ
> PlotoSpawner always tells me there are no temp drives available but there is enough storage?!

It checks if a temp drive has plotting in progress by checking if the drive has any Child Items in it (Files or folders). If yes, this indicates that plotting is in progress, as I mostly use completely empty drives for plotting. When it indicates plot in progress on a temp drive, that drive is considered as not available. So if you use drives that have other files in it, you need to make sure you alter Get-PlotoTempDrives function to your needs.

> Can I shut down the script when I dont want Ploto to spawn more Plots?

Yep. The individual Chia Plot Jobs wont be affected by that.

# Prereqs
The following prereqs need to be met in order for Ploto to function properly:

* chia.exe is installed and path is valid (currently hardcoded to v1.1.1.1, so may break upon update. Will adjust)
* BITS (Background Intelligent Transfer Service) is functioning properly (used to move final plots around if needed -> Manage-PlotoMove) 

If you want to send and receive SMS:

* Twilio Account
* Twilio AccountSid
* Twilio AuthToken
* Twilio Sender Number


# HowTo Use it
```powershell
Manage-PlotoSpawns -InputAmountToSpawn 12 -OutDriveDenom "out" -TempDriveDenom "plot"
```
This will create 12 Plots across all drives that have "plot" in the name properrty and storing these plots on all drives having "out" in their name property.
Ploto attempts to parallelilze as much as possible, meaning that it uses each temp disk in parallel bot only for 1 plot job at the time. If a plot job is running on a temp disk, Ploto wont use that disk. 

