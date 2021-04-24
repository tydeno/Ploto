function Spawn-PlotoPlots
{

$PlottableTempDrives = Get-PlotoTempDrives | ? {$_.IsPlottable -eq $true}   
$PlottableOutDrives = Get-PlotoOutDrives | ? {$_.IsPlottable -eq $true}

$collectionWithPlotJobs= New-Object System.Collections.ArrayList

Write-Host "PlotoSpawner @"(Get-Date)": Checking for available temp and out drives..."

if ($PlottableTempDrives)
    {
         foreach ($PlottableTempDrive in $PlottableTempDrives)
            {
                Write-Host "PlotoSpawner @"(Get-Date)": Found available temp drive:"
                Write-Host $PlottableTempDrive | ft

                #Choose most suitable OutDrive (assumed the one with most space)
                $max = ($PlottableOutDrives | measure-object -Property FreeSpace -maximum).maximum
                $OutDrive = $PlottableOutDrives | ? { $_.FreeSpace -eq $max}
                $OutDriveLetter = $OutDrive.DriveLetter

                Write-Host "PlotoSpawner @"(Get-Date)": Found most suitable Out Drive:"
                Write-Host $OutDrive | ft
        
                #stitch together ArgumentsList for chia.exe
                $ArgumentList = "plots create -k 32 -t "+$PlottableTempDrive.DriveLetter+"\ -d "+$OutDriveLetter+"\ -e"

                Write-Host "PlotoSpawner @"(Get-Date)": Using the following Arguments for Chia.exe:"
                Write-Host $ArgumentList | ft

                $PathToChia = "$env:LOCALAPPDATA\chia-blockchain\app-1.1.1\resources\app.asar.unpacked\daemon\"

                Write-Host "PlotoSpawner @"(Get-Date)": Using the following Path to chia.exe: "$PathToChia
                Write-Host "PlotoSpawner @"(Get-Date)": Starting plotting using chia.exe."

            
                #Fire off chia
                try 
                    {
                        cd $PathToChia
                        Start-Process .\chia.exe -ArgumentList $ArgumentList
                    }
                catch
                    {
                        Write-Host "PlotoSpawner @"(Get-Date)": ERROR! Could not launch chia.exe. Check chiapath and arguments (make sure version is set correctly!)"
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

                Write-Host "PlotoSpawner @"(Get-Date)": The following Job was initiated:"
                Write-Host $PlotJob | ft

                $collectionWithPlotJobs.Add($PlotJob) | Out-Null

                Write-Host "--------------------------------------------------------------------"
                Start-Sleep 900

            }
    
    }
else
    {
        Write-Host "PlotoSpawner @"(Get-Date)": No available Temp and or Out Disks found."
    }

   return $collectionWithPlotJobs
}
