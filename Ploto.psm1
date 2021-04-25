<#
.SYNOPSIS
Name: Ploto
Version: 1.0
Author: Tydeno


.DESCRIPTION
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself. Basically spawns and moves Plots around.
https://github.com/tydeno/Ploto
#>

function Format-TwilioCredential {
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
$cred = Format-TwilioCredential -AccountSid $AccountSid -AuthToken $AuthToken

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

function Invoke-PlotoJob
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

function Start-PlotoSpawns
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
        $SpawnedPlots = Invoke-PlotoJob -OutDriveDenom $OutDriveDenom -TempDriveDenom $TempDriveDenom

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

function Get-PlotoPlots
{
	Param(
		[parameter(Mandatory=$true)]
		$OutDriveDenom
		)

#Scan for final Plot Files to Move
$OutDrivesToScan = Get-PlotoOutDrives -OutDriveDenom $OutDriveDenom

if ($OutDrivesToScan)
    {
        $collectionWithFinalPlots= New-Object System.Collections.ArrayList

        foreach ($OutDriveToScan in $OutDrivesToScan)
        {
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

    }
else
    {
        Write-Host "No drives to Scan. Make sure you set your denominator correctly. Dont specify the drive, speficy the denom across all drives!" -ForegroundColor Red
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


$PlotsToMove = Get-PlotoPlots -OutDriveDenom $OutDriveDenom

if ($PlotsToMove)
    {
        Write-Host "PlotoMover @"(Get-Date)": There are Plots found to be moved: "
        foreach ($plot in $PlotsToMove)
            {
                Write-Host $plot.filepath -ForegroundColor Green
            }
        Write-Host "PlotoMover @"(Get-Date)": A total of "$PlotsToMove.Count" plot have been found."
                          

        foreach ($plot in $PlotsToMove)
        {
            #Check if BITS Transfer already in progress:
            $HasBITSinProgress = Get-BitsTransfer | ? {$_.FileList.RemoteName -eq $plot.Filepath} 

            if ($HasBITSinProgress)
                {
                    Write-Host "PlotoMover @"(Get-Date)": WARN:" $plot.FilePath "has already a BITS transfer in progress"
                }

            else
                {
                     try 
                        {
                            Write-Host "PlotoMover @"(Get-Date)": Moving plot: "$plot.FilePath "to" $DestinationDrive
                            $source = $plot.FilePath
                            $BITSOut = Start-BitsTransfer -Source $source -Destination $DestinationDrive -Description "Moving Plot" -DisplayName "Moving Plot"
                            
                            while ((Get-BitsTransfer | ? { $_.JobState -eq "Transferring" }).Count -gt 0) {     
                                $totalbytes=0;    
                                $bytestransferred=0; 
                                $timeTaken = 0;    
                                foreach ($job in (Get-BitsTransfer | ? { $_.JobState -eq "Transferring" } | Sort-Object CreationTime)) {         
                                    $totalbytes += $job.BytesTotal;         
                                    $bytestransferred += $job.bytestransferred     
                                    if ($timeTaken -eq 0) { 
                                        #Get the time of the oldest transfer aka the one that started first
                                        $timeTaken = ((Get-Date) - $job.CreationTime).TotalMinutes 
                                    }
                                }    
                                #TimeRemaining = (TotalFileSize - BytesDownloaded) * TimeElapsed/BytesDownloaded
                                if ($totalbytes -gt 0) {        
                                    [int]$timeLeft = ($totalBytes - $bytestransferred) * ($timeTaken / $bytestransferred)
                                    [int]$pctComplete = $(($bytestransferred*100)/$totalbytes);     
                                    Write-Progress -Status "Transferring $bytestransferred of $totalbytes ($pctComplete%). $timeLeft minutes remaining." -Activity "Dowloading files" -PercentComplete $pctComplete  
                                }
                            }
                        }

                    catch
                        {
                            Write-Host "PlotoMover @"(Get-Date)": ERROR: " $_.Exception.Message -ForegroundColor Red
                        }        
                }
        }
    }

else
    {
        Write-Host "PlotoMover @"(Get-Date)": No Final plots found." 
    }

}

function Start-PlotoMove
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

    Write-Host "Start-PlotoMove: Using destination drive: "$DestinationDrive

    Do
        {
            Move-PlotoPlots -DestinationDrive $DestinationDrive -OutDriveDenom $OutDriveDenom
            Start-Sleep 900
        }

    Until ($count -eq $endlessCount)
}

function Install-PlotoModule
{
    
    $PlotoModule = Get-Module | ? {$_.Name -eq "Ploto"}

    if ($PlotoModule)
        {
           Write-Host "PlotoBooter @"(Get-Date)": Ploto Module is present. Ready to roll. Or plot." -ForegroundColor Green
           $ModuleOK = $true 
        }

    else
        {
            Write-Host "PlotoBooter @"(Get-Date)": Ploto Module not present. Trying to Import." -ForegroundColor yellow
            try
            {
                Import-Module Ploto -ErrorAction Stop
                $ModuleOK = $true 
            }

            catch
            {
                Write-Host "PlotoBooter @"(Get-Date)": Could not import due to Error:"$_.Exception.Message -ForegroundColor red

                if ($_.Exception.Message -eq "The specified module 'Ploto' was not loaded because no valid module file was found in any module directory.")
                    {
                        Write-Host "PlotoBooter @"(Get-Date)": The error is known. Starting Module download from Github now. Using URL: https://github.com/tydeno/Ploto/archive/refs/heads/main.zip "
                        $repo = "https://github.com/tydeno/Ploto/archive/refs/heads/main.zip"
                    
                        $ZipPath = $env:TEMP+"\ploto"+(Get-Date).TimeOfDay.Seconds
                        Write-Host "PlotoBooter @"(Get-Date)": Storing local .ZIP in "$ZipPath
                        $Zip = $ZipPath+".zip"

                        New-Item $Zip -ItemType File -Force | Out-Null
                        Invoke-RestMethod -Uri $repo -OutFile $Zip | Out-Null

                        Write-Host "PlotoBooter @"(Get-Date)": Downloaded Ploto Module from Github Repo. Extracting now."
                        Expand-Archive -Path $Zip -DestinationPath $ZipPath | Out-Null


                        Write-Host "PlotoBooter @"(Get-Date)": Module extracting, cleaning up Downloaded file and starting import."
                        Remove-Item -Path $Zip -Force 

                        $PathToModule = $ZipPath+"\Ploto-main\Ploto.psm1"
                        Copy-Item -Path $PathToModule -Destination "C:\Windows\System32\WindowsPowerShell\v1.0\Modules"
                        Import-Module $PathToModule

                        Write-Host "PlotoBooter @"(Get-Date)": Module installed successfully. Ready to roll. Or plot." -ForegroundColor Green
                        $ModuleOK = $true
                    }

                else
                    {
                        Write-Host "PlotoBooter @"(Get-Date)": The error" $_.Exception.Message " is unknown." -ForegroundColor Red
                        $ModuleOK = $false
                
                    }
            }
         }
    return $ModuleOK
}

function Start-Ploto
{
	Param(
		[parameter(Mandatory=$true)]
		$DestinationDrive,
		[parameter(Mandatory=$true)]
		$OutDriveDenom,
		[parameter(Mandatory=$true)]
		$TempDriveDenom,
        [parameter(Mandatory=$true)]
	    $SendSMSNotification,
        [parameter(Mandatory=$true)]
	    $InputAmountToSpawn,
        $AccountSid,
        $AuthToken,
        $from,
        $to
		)

    Write-Host $DestinationDrive
    Write-Host $Inp

    $ModuleUp = Install-PlotoModule
    if ($ModuleUp -eq $true)
        {
          $Mover = Start-Job -ScriptBlock {Start-PlotoMove -DestinationDrive $DestinationDrive -OutDriveDenom $OutDriveDenom} -verbose
          $Spawner = Start-Job -ScriptBlock {Start-PlotoSpawns -InputAmountToSpawn $InputAmountToSpawn -OutDriveDenom $OutDriveDenom -TempDriveDenom $TempDriveDenom -SendSMSWhenJobDone $false } -Verbose
          Write-Host "PlotoBooter @"(Get-Date)": Launched Spawner and Mover. Use Get-Job / Retrieve-Job to see details."
        }

    else
        {
            Write-Host "ERROR! Modules arent up!" -ForegroundColor Red
        }
}
