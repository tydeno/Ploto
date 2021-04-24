# Ploto
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself.
Basically spawns and moves Plots around.

### PlotoSpawn

* Get-PlotoOutDrives
* Get-PlotoTempDrives
* Spawn-PlotoPlots
* Manage-PlotoSpawns

### PlotoMove

* Get-PlotoFinalPlotFile
* Move-PlotoPlots


# How it works
TLDR: It plots 1x plot on each TempDrive (if you have 6x TempDrives = 6x parallel Plot Jobs) as long as you want it to and as long as you have OutDrive space.

Ploto checks periodically, if a TempDrive and OutDrive is available for plotting. 
If there is no TempDrive available, or no OutDrive, Ploto checks again in 3600 seconds.

When there is one available, Ploto determines the best OutDrive (most free space) and calls chia.exe to start the plot.
Ploto iterates once through all available TempDrives and spawns a plot per each TempDrive (as long as enough OutDrive space is given).
After that, Ploto checks if amount Spawned is equal as defined as input. If not, Ploto keeps going until it is.

# Prereqs
The following prereqs need to be met in order for Ploto to function properly:

* chia.exe is installed and path is valid (currently hardcoded to v1.1.1.1, so may break upon update. Will adjust)
* BITS (Background Intelligent Transfer Service) is functioning properly (used to move final plots around if needed -> Manage-PlotoMove) 

If you want to send and receive SMS:

* Twilio Account
* Twilio AccountSid
* Twilio AuthToken
* Twilio Sender Number


# PlotoSpawn
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

```powershell
-OutDriveDenom
```

This param defines your OutDrives. An OutDrive in Ploto Terms is the drive chia stores the final plot to. Usually these are your big capacity HDDs.

Make sure your OutDriveDenom is unique to your real HDD you want to use to store chia Plots. 
If a Volume has your OutDriveDenom in their VolumeName, they will also be used, if enough free space is given.



## Get-PlotoTempDrives
Gets all Windows Volumes that match the -TempDriveDenom parameter and checks if free space is greater than 270 GB (amount currently used by chia plots as temp storage).
It wraps all the needed information of the volume like DriveLetter, ChiaDriveType, VolumeName, a bool IsPlootable, and the calculated amount of plots to temp, whether it has a plot in porgress (determined by checking if the drive contains any file) into a object and returns the collection of objects as the result of that function.

#### Example:

```powershell
 Get-PlotoTempDrives -TempDriveDenom "plot"
```
#### Output:

```
DriveLetter         : E:
ChiaDriveType       : Temp
VolumeName          : ChiaPlot 3 Evo 860 512GB 
FreeSpace           : 215.19
IsPlottable         : False
AmountOfPlotsToTemp : 0
HasPlotInProgress   : Likely

DriveLetter         : H:
ChiaDriveType       : Temp
VolumeName          : ChiaPlot 2 Crucial CT 512 GB 2
FreeSpace           : 228.14
IsPlottable         : False
AmountOfPlotsToTemp : 0
HasPlotInProgress   : Likely

DriveLetter         : I:
ChiaDriveType       : Temp
VolumeName          : ChiaPlot 1 Crucial CT 512GB  
FreeSpace           : 451.07
IsPlottable         : True
AmountOfPlotsToTemp : 1
HasPlotInProgress   : False

DriveLetter         : Q:
ChiaDriveType       : Temp
VolumeName          : ChiaPlot 4 2TB SSD
FreeSpace           : 1588.29
IsPlottable         : False
AmountOfPlotsToTemp : 5
HasPlotInProgress   : True
```

#### Parameters:
```
-TempDriveDenom
```

The same as -OutDriveDenom but for your temporary drives chia uses to actually plot on. Usually these are are your SATA/NVMe SSDs.
Use a denonimator that all your chia temp drives have in common. For me, all Chia Temp drives (drives I plot on) are called "ChiaPlot 1-4".
So for me I set the param to "plot". 

Make sure your TempDriveDenom is unique to your real SSDs you want to use to create chia Plots. If a Volume has your TempDriveDenom in their VolumeName, they will also be used, if enough free space is given.

## Spawn-PlotoPlots
Calls Get-PlotoTempDrives to get all Temp drives that are plottable. For each tempDrive it determines the most appropriate OutDrive (using Get-PlotoOutDrives function), stitches together the ArgumentList for chia and fires off the chia plot job using chia.exe. For each created PlotJob the function creates an Object and appends it to a collection of objects, which are returned upon the function call. 

#### Example:

```powershell
Spawn-PlotoPlots -OutDriveDenom "out" -TempDriveDenom "plot"
```
#### Output:

```
PlotoSpawner @ 4/24/2021 11:20:01 PM : Checking for available temp and out drives...
PlotoSpawner @ 4/24/2021 11:20:01 PM : No available Temp and or Out Disks found.
```

#### Parameters
See Parameters Section of Get-PlotoOutDrives and Get-PlotoTempDrives

## Manage-PlotoSpawns
Main function that nests all else.
Continously calls Spawn-PlotoSpawns and states progress and other information. It runs until it created the amount of specified Plot by using the -InputAmountToSpawn param.

#### Example:

```powershell
Manage-PlotoSpawns -InputAmountToSpawn 12 -OutDriveDenom "out" -TempDriveDenom "plot"
```

#### Output:

```
PlotoManager @ 4/24/2021 10:29:15 PM : Initiating PlotoManager...
PlotoSpawner @ 4/24/2021 11:10:57 PM : Checking for available temp and out drives...
PlotoSpawner @ 4/24/2021 11:10:57 PM : Found available temp drive:  @{DriveLetter=I:; ChiaDriveType=Temp; VolumeName=ChiaPlot 1 Crucial CT 512GB  ; FreeSpace=451.07; IsPlottable=True; AmountOfPlotsToTemp=1; HasPlotInProgress=False}
PlotoSpawner @ 4/24/2021 11:10:57 PM : Found most suitable Out Drive:  @{DriveLetter=K:; ChiaDriveType=Out; VolumeName=ChiaOut3; FreeSpace=364.24; IsPlottable=True; AmountOfPlotsToHold=3}
PlotoSpawner @ 4/24/2021 11:10:57 PM : Using the following Arguments for Chia.exe:  plots create -k 32 -t I:\ -d K:\ -e
PlotoSpawner @ 4/24/2021 11:10:57 PM : Starting plotting using the following Path to chia.exe:  C:\Users\Yanik\AppData\Local\chia-blockchain\app-1.1.1\resources\app.asar.unpacked\daemon\
PlotoSpawner @ 4/24/2021 11:10:57 PM : The following Job was initiated:  @{OutDrive=K:; TempDrive=I:; StartTime=4/24/2021 11:10:57 PM}
--------------------------------------------------------------------
PlotoManager @ 4/24/2021 11:25:57 PM : Amount of spawned Plots in this iteration:
PlotoManager @ 4/24/2021 11:25:57 PM : Spawned the following plots using Ploto Spawner:  @{OutDrive=K:; TempDrive=I:; StartTime=4/24/2021 11:10:57 PM}
PlotoManager @ 4/24/2021 11:25:58 PM : Overall spawned Plots since start of script:  0
PlotoManager @ 4/24/2021 11:25:58 PM : Entering Sleep for 900, then checking again for available temp and out drives
----------------------------------------------------------------------------------------------------------------------
```

Example with SMS Notifications (trough Twilio):

```powershell
Manage-PlotoSpawns -InputAmountToSpawn 12 -OutDriveDenom "out" -TempDriveDenom "plot" -SendSMSWhenJobDone $true -AccountSid $TwilioAccountSid -AuthToken $TwilioAuthToken -from $TwilioNumber -to $YourNumber
```

#### Parameters
See Parameters Section of Get-PlotoOutDrives, Get-PlotoTempDrives and Spawn-PlotoPlots 

# PlotoMove

## Get-PlotoFinalPlotFile
Searches specified Outdrives for final .PLOT files and returns an array of objects with all final plots found, their names and Path.
A final plot is solely determined by a file on a OutDrive with the file extension .PLOT (Actual item property, not file name)

#### Example:

```powershell
Get-PlotoFinalPlotFile -OutDriveDenom "out"
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
Calls Get-PlotoFinalPlotFile to get all final plots. Then checks if destination drive has enough free space. If yes, PlotoMover moves the file to the destination using BITS.
If no, the function exits and displays a message.

The function supports SMS Notifications using Twilio. When there is a transferable Plot, but the destination drive does not have enough free space to store the plot, an SMS Notifciation is sent to the number specified.

#### Example:

```powershell
Move-PlotoPlots -DestinationDrive "J:" -OutDriveDenom "out" 
```

#### Parameters
```powershell
-DestinationDrive
```
Defines the destination drive the final plot is moved to. Can be a drive or UNC Path.
See Parameters Section of Get-PlotoOutDrives.

#### Output:

```
PlotoMover @ 4/24/2021 11:48:29 PM : There are Plots found to be moved:  @{FilePath=D:\plot-k32-2021-04-23-14-31-674b9f72e0df0a35c6918afd4fd3eb2780915a7a4f776b803328a409
72c99db6.plot; Name=plot-k32-2021-04-23-14-31-674b9f72e0df0a35c6918afd4fd3eb2780915a7a4f776b803328a40972c99db6.plot; Size=101.4} @{FilePath=K:\plot-k32-2021-04-24-06-52-
a1dfce79910040323cab0d10baafe24f25cc0cef592978984e91603acdb3434a.plot; Name=plot-k32-2021-04-24-06-52-a1dfce79910040323cab0d10baafe24f25cc0cef592978984e91603acdb3434a.pl
ot; Size=101.36}
PlotoMover @ 4/24/2021 11:48:29 PM : Not enough space on destination drive: J: available space on Disk:  95.22
PlotoMover @ 4/24/2021 11:48:29 PM : Not enough space on destination drive: J: available space on Disk:  95.22
```

# helper Functions 
For sending SMS for notifications, Ploto uses these self-crafted Twilio helper wrapprs.

## Create-TwilioCredential
Transforms Twilio Credentials into securestrings to be used as Input for API Call.

#### Example:

```powershell
Create-TwilioCredential -AccountSid $TwilioSID -$AuthToken $TwilioAuthToken
```

#### Output:

```
UserName                      Password
--------                      --------
kjsdkksjk System.Security.SecureString

```

### Send-SMS
Calls the Twilio API using the credentials generated by Create-TwilioCredential and send the message defined as input to the defined number.

#### Example:

```powershell
Send-SMS -AccountSid $TwillioSID -AuthToken $TwilioAuthToken -Message $TwilioMessage -from $from -to $to
```

#### Output:

```
StatusCode        : 201
StatusDescription : Created
Content           : {"sid": "xxxxxxxxxxxxxxx", "date_created": "Sat, 24 Apr 2021 21:59:25 +0000", "date_updated": "Sat, 24 Apr 2021 21:59:25 +0000", 
                    "date_sent": null, "account_sid": "xxxx...
RawContent        : HTTP/1.1 201 Created
                    Connection: keep-alive
                    Twilio-Concurrent-Requests: 1
                    Twilio-Request-Id: xxxfc8exxx
                    Twilio-Request-Duration: 0.093
                    Access-Control-Allow-Origin: *
                    Acce...
Forms             : 
Headers           : {[Connection, keep-alive], [Twilio-Concurrent-Requests, 1], [Twilio-Request-Id, xxxxxx0f078fc8eff], [Twilio-Request-Duration, 
                    0.09x3]...}
Images            : {}
InputFields       : {}
Links             : {}
ParsedHtml        : 
RawContentLength  : 825

```

# FAQ
> PlotoSpawner always tells me there are no temp drives available but there is enough storage?!

It checks if a temp drive has plotting in progress by checking if the drive has any Child Items in it (Files or folders). If yes, this indicates that plotting is in progress, as I mostly use completely empty drives for plotting. When it indicates plot in progress on a temp drive, that drive is considered as not available. So if you use drives that have other files in it, you need to make sure you alter Get-PlotoTempDrives function to your needs.

> Can I shut down the script when I dont want Ploto to spawn more Plots?

Yep. The individual Chia Plot Jobs wont be affected by that.





