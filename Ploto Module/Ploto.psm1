<#
.SYNOPSIS
Name: Ploto
Version: 1.0
Author: Tydeno


.DESCRIPTION
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself. Basically spawns and moves Plots around.
https://github.com/tydeno/Ploto
#>


function Create-TwilioCredential {
    Param(
        [string] $AccountSid,
        [string] $AuthToken,
        [Hashtable] $Connection
    )

    if(!$Connection -and (!$AuthToken -or !$AccountSid)) {
        throw("No connection data specified. You must use either the Connection parameter, or the AccountSid and AuthToken parameters.")
    }

    if(!$Connection) {
        $con = @{}
    }
    elseif(!$Connection.AccountSid -or !$Connection.AuthToken) {
        throw("Connection object must contain AccountSid and AuthToken properties.")
    }
    else {
        $con = @{
            AccountSid = $Connection.AccountSid;
            AuthToken = $Connection.AuthToken
        }
    }

    if($AccountSid) {
        $con.AccountSid = $AccountSid
    }

    if($AuthToken) {
        $con.AuthToken = $AuthToken
    }

    $secpasswd = ConvertTo-SecureString $con.AuthToken -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($con.AccountSid, $secpasswd)

    return $cred
}

function Send-SMS
{
param ($AccountSid,$AuthToken,$Message,$from,$to)
$cred = Create-TwilioCredential -AccountSid $AccountSid -AuthToken $AuthToken

$TWILIO_BASE_URL = "https://api.twilio.com/2010-04-01"
$URI = "$TWILIO_BASE_URL" + "/Accounts/$AccountSid/Messages.json"

$body = @{
            To = $To;
            From = $From;
            Body = $Message
         }

$responsePOST = Invoke-WebRequest $URI -Method Post -Credential $cred -Body $body -UseBasicParsing 
return $responsePOST

}

function Get-PlotoOutDrives
{
	Param(
		[parameter(Mandatory=$true)]
		$OutDriveDenom
		)

$outDrives = get-WmiObject win32_logicaldisk | ? {$_.VolumeName -like "*$OutDriveDenom*"}

#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($drive in $outDrives)
    {
  
        $FreeSpace = [math]::Round($drive.FreeSpace  / 1073741824, 2)
        If ($FreeSpace -gt 107)
            {
                $PlotToDest = $true
            }
        else
            {
                $PlotToDest = $false
            }

        $outdriveToPass = [PSCustomObject]@{
        DriveLetter     =  $drive.DeviceID
        ChiaDriveType = "Out"
        VolumeName = $drive.VolumeName
        FreeSpace = $FreeSpace
        IsPlottable    = $PlotToDest
        AmountOfPlotsToHold = [math]::Floor(($FreeSpace / 100))
        }

        $collectionWithDisks.Add($outdriveToPass) | Out-Null

    }
    return $collectionWithDisks 
}

function Get-PlotoTempDrives
{
	Param(
		[parameter(Mandatory=$true)]
		$TempDriveDenom
		)

$tmpDrives = get-WmiObject win32_logicaldisk | ? {$_.VolumeName -like "*$TempDriveDenom*"}

#Check Space for outDrives
$collectionWithDisks= New-Object System.Collections.ArrayList
foreach ($tmpDrive in $tmpDrives)
    {
  
        $FreeSpace = [math]::Round($tmpDrive.FreeSpace  / 1073741824, 2)
        If ($FreeSpace -gt 270)
            {
                $ChildItemsOfDrive = Get-ChildItem $tmpDrive.DeviceID

                if ($ChildItemsOfDrive)
                    {
                        $IsPlottable = $false
                        $HasPlotInProgress = $true
                    }
                else
                    {
                        $IsPlottable = $true
                        $HasPlotInProgress = $false
                    }
            }
        else
            {
                $IsPlottable = $false
                $HasPlotInProgress = "Likely"
            }

        $driveToPass = [PSCustomObject]@{
        DriveLetter     =  $tmpDrive.DeviceID
        ChiaDriveType = "Temp"
        VolumeName = $tmpDrive.VolumeName
        FreeSpace = $FreeSpace
        IsPlottable    = $IsPlottable
        AmountOfPlotsToTemp = [math]::Floor(($FreeSpace / 270))
        HasPlotInProgress = $HasPlotInProgress
        }

        $collectionWithDisks.Add($driveToPass) | Out-Null

    }
    return $collectionWithDisks 
}

function Spawn-PlotoPlots
{
	Param(
		[parameter(Mandatory=$true)]
		$OutDriveDenom,
		[parameter(Mandatory=$true)]
		$TempDriveDenom
		)

$PlottableTempDrives = Get-PlotoTempDrives -TempDriveDenom $TempDriveDenom | ? {$_.IsPlottable -eq $true}   
$PlottableOutDrives = Get-PlotoOutDrives -OutDriveDenom $OutDriveDenom | ? {$_.IsPlottable -eq $true}

$collectionWithPlotJobs= New-Object System.Collections.ArrayList

Write-Host "PlotoSpawner @"(Get-Date)": Checking for available temp and out drives..." 

if ($PlottableTempDrives)
    {
         foreach ($PlottableTempDrive in $PlottableTempDrives)
            {
                Write-Host "PlotoSpawner @"(Get-Date)": Found available temp drive: "$PlottableTempDrive -ForegroundColor Green

                #Choose most suitable OutDrive (assumed the one with most space)
                $max = ($PlottableOutDrives | measure-object -Property FreeSpace -maximum).maximum
                $OutDrive = $PlottableOutDrives | ? { $_.FreeSpace -eq $max}
                $OutDriveLetter = $OutDrive.DriveLetter

                Write-Host "PlotoSpawner @"(Get-Date)": Found most suitable Out Drive: "$OutDrive -ForegroundColor Green
            
                #Fire off chia
                try 
                    {
                        $PathToChia = "$env:LOCALAPPDATA\chia-blockchain\app-1.1.1\resources\app.asar.unpacked\daemon\chia.exe"                         
                        $ArgumentList = "plots create -k 32 -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -e"

                        Write-Host "PlotoSpawner @"(Get-Date)": Using the following Arguments for Chia.exe: "$ArgumentList 
                        Write-Host "PlotoSpawner @"(Get-Date)": Starting plotting using the following Path to chia.exe: "$PathToChia

                        Start-Process $PathToChia -ArgumentList $ArgumentList
                    }
                catch
                    {
                        Write-Host "PlotoSpawner @"(Get-Date)": ERROR! Could not launch chia.exe. Check chiapath and arguments (make sure version is set correctly!). Arguments used: "$ArgumentList -ForegroundColor Red
                    }

                #Deduct 106GB from OutDrive Capacity in Var
                $DeductionOutDrive = ($OutDrive.FreeSpace - 106)
                $OutDrive.FreeSpace="$DeductionOutDrive"

                #Getting Plot Object Ready
                $PlotJob = [PSCustomObject]@{
                OutDrive     =  $OutDriveLetter
                TempDrive = $PlottableTempDrive.DriveLetter
                StartTime = (Get-Date)
                }

                $collectionWithPlotJobs.Add($PlotJob) | Out-Null

                Write-Host "PlotoSpawner @"(Get-Date)": The following Job was initiated: "$PlotJob -ForegroundColor Green
                Write-Host "--------------------------------------------------------------------"
                Start-Sleep 900

            }
    
    }
else
    {
        Write-Host "PlotoSpawner @"(Get-Date)": No available Temp and or Out Disks found." -ForegroundColor Yellow
    }

   return $collectionWithPlotJobs
}

function Manage-PlotoSpawns
{
	Param(
	[parameter(Mandatory=$true)]
	$InputAmountToSpawn,
	[parameter(Mandatory=$true)]
	$OutDriveDenom,
	[parameter(Mandatory=$true)]
	$TempDriveDenom,
	[parameter(Mandatory=$true)]
	$SendSMSWhenJobDone,
    $AccountSid,
    $AuthToken,
    $from,
    $to
)

    $SpawnedCount = 0

    Do
    {
        Write-Host "PlotoManager @"(Get-Date)": Initiating PlotoManager..."
        $hostname = hostname
        $SpawnedPlots = Spawn-PlotoPlots -OutDriveDenom $OutDriveDenom -TempDriveDenom $TempDriveDenom

        if ($SpawnedPlots)
            {
                Write-Host "PlotoManager @"(Get-Date)": Amount of spawned Plots in this iteration: " $SpawnedPlots.Count
                Write-Host "PlotoManager @"(Get-Date)": Spawned the following plots using Ploto Spawner: "$SpawnedPlots -ForegroundColor Green
                if ($SendSMSWhenJobDone -eq $true) 
                    {
                        $TwilioMessage = "Hei, a plot is spawned! See details: "+$SpawnedPlots
                        $JobDoneNotification = Send-SMS -AccountSid $AccountSid -AuthToken $AuthToken -Message $TwilioMessage -from $from -to $to
                    }
            }
        else
            {
                Write-Host "PlotoManager @"(Get-Date)": No plots spawned in this cycle, as no temp disks available" -ForegroundColor Yellow
            }

        $SpawnedCount = $SpawnedCount + $SpawnedPlots.Count 
       
        Write-Host "PlotoManager @"(Get-Date)": Overall spawned Plots since start of script: "$SpawnedCount
        Write-Host "PlotoManager @"(Get-Date)": Entering Sleep for 900, then checking again for available temp and out drives"
        Write-Host "----------------------------------------------------------------------------------------------------------------------"
        Start-Sleep 900
    }
    
    Until ($SpawnedCount -eq $InputAmountToSpawn)
}

function Get-PlotoFinalPlotFile
{
	Param(
		[parameter(Mandatory=$true)]
		$OutDriveDenom
		)

#Scan for final Plot Files to Move
$OutDrivesToScan = Get-PlotoOutDrives -OutDriveDenom $OutDriveDenom

$collectionWithFinalPlots= New-Object System.Collections.ArrayList
foreach ($OutDriveToScan in $OutDrivesToScan)
    {
        Write-Host "-------------------------------------------------------------"
        Write-Host "Iterating trough Drive: "$OutDriveToScan

        $ItemsInDrive = Get-ChildItem $OutDriveToScan.DriveLetter
        Write-Host "Checking if any item in that drive contains .PLOT as file ending..."

        If ($ItemsInDrive)

        {
            foreach ($item in $ItemsInDrive)
            {
                If ($item.Extension -eq ".PLOT")
                    {
                        Write-Host -ForegroundColor Green "Found a Final plot: "$item
                    
                        $FilePath = $item.Directory.Name + $item.name
                        $Size = [math]::Round($item.Length  / 1073741824, 2)

                        $PlotToMove = [PSCustomObject]@{
                        FilePath     =  $FilePath
                        Name = $item.Name
                        Size = $Size
                        }

                        $collectionWithFinalPlots.Add($PlotToMove) | Out-Null
                    }
                else
                    {
                        Write-Host "This is no plot: "$item -ForegroundColor Yellow
                    }
            }
        }

        else
            {
                Write-Host "This drive does not contain any files or folders." -ForegroundColor yellow
            }
    }
    
    Write-Host "--------------------------------------------------------------------------------------------------"

    return $collectionWithFinalPlots
}

function Move-PlotoPlots
{
	Param(
		[parameter(Mandatory=$true)]
		$DestinationDrive,
		[parameter(Mandatory=$true)]
		$OutDriveDenom,
	    $SendSMSNotification,
        $AccountSid,
        $AuthToken,
        $from,
        $to
		)

$PlotsToMove = Get-PlotoFinalPlotFile -OutDriveDenom $OutDriveDenom

if ($PlotsToMove)
    {
        Write-Host "PlotoMover @"(Get-Date)": There are Plots found to be moved: "$PlotsToMove
         
        foreach ($plot in $PlotsToMove)
        {
            #Check if Destination drive has enough capacity for file to move
            $DestinationLogicalDisk = get-WmiObject win32_logicaldisk | ? {$_.DeviceID -eq $DestinationDrive}
            $DestinationDriveFreeSpace = [math]::Round($DestinationLogicalDisk.FreeSpace  / 1073741824, 2)

            if ($DestinationDriveFreeSpace -gt $plot.Size)
                {
                   Write-Host "PlotoMover @"(Get-Date)": Destination Drive has enough Space:"$DestinationLogicalDisk.DeviceID "available space on Disk: "$DestinationDriveFreeSpace -ForegroundColor Green

                   #Move Item using BITS
                   try
                        {
                            Write-Host "PlotoMover @"(Get-Date)": Moving plot: "$plot.FilePath "to" $DestinationDrive
                            $BITSOut = Start-BitsTransfer -Source $plot.FilePath -Destination $DestinationDrive -Description "Moving Plot" -DisplayName "Moving Plot"

                            $TwilioMessage = "A plot Has been moved and is ready for transfer: "+$plot 
                            $BadErrorNotification = Send-SMS -AccountSid $AccountSid -AuthToken $AuthToken -Message $TwilioMessage -from $from -to $to
                        }

                    catch
                        {
                            Write-Output "PlotoMover @"(Get-Date)": BITS Transfer failed!" -ForegroundColor Red
                        }

                } 
            else
                {
        
                   Write-Host "PlotoMover @"(Get-Date)": Not enough space on destination drive:"$DestinationLogicalDisk.DeviceID "available space on Disk: "$DestinationDriveFreeSpace -ForegroundColor Red
                   if ($SendSMSNotification -eq $true) 
                    {
                        $TwilioMessage = "A plot to move has been found, but Destination Disk has no space. Make free space on Disk:"+$DestinationDrive 
                        $BadErrorNotification = Send-SMS -AccountSid $AccountSid -AuthToken $AuthToken -Message $TwilioMessage -from $from -to $to
                    }
                }
        }
    }

else
    {
        Write-Host "PlotoMover @"(Get-Date)": No Final plots found." 
    }

}

function Manage-PlotoMove
{
	Param(
		[parameter(Mandatory=$true)]
		$DestinationDrive,
		[parameter(Mandatory=$true)]
		$OutDriveDenom,
	    $SendSMSNotification,
        $AccountSid,
        $AuthToken,
        $from,
        $to
		)

    $count = 0
    $endlessCount = 1000

    Do
        {
            Move-PlotoPlots -DestinationDrive "J:" -OutDriveDenom "out"
            Start-Sleep 900
        }

    Until ($count -eq $endlessCount)
}