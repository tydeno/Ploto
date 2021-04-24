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
                        $PathToChia = "$env:LOCALAPPDATA\chia-blockchain\app-1.1.1\resources\app.asar.unpacked\daemon\"                         
                        $ArgumentList = "plots create -k 32 -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -e"

                        Write-Host "PlotoSpawner @"(Get-Date)": Using the following Arguments for Chia.exe: "$ArgumentList 
                        Write-Host "PlotoSpawner @"(Get-Date)": Starting plotting using the following Path to chia.exe: "$PathToChia

                        cd $PathToChia
                        Start-Process .\chia.exe -ArgumentList $ArgumentList
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
