function Manage-PlotoSpawns
{
	Param(
	[parameter(Mandatory=$true)]
	$InputAmountToSpawn,
	[parameter(Mandatory=$true)]
	$OutDriveDenom,
	[parameter(Mandatory=$true)]
	$TempDriveDenom
)

    $SpawnedCount = 0

    Do
    {
        Write-Host "PlotoManager @"(Get-Date)": Initiating PlotoManager..."
        $SpawnedPlots = Spawn-PlotoPlots -OutDriveDenom $OutDriveDenom -TempDriveDenom $TempDriveDenom

        if ($SpawnedPlots)
            {
                Write-Host "PlotoManager @"(Get-Date)": Amount of spawned Plots in this iteration: " $SpawnedPlots.Count
                Write-Host "PlotoManager @"(Get-Date)": Spawned the following plots using Ploto Spawner: "$SpawnedPlots -ForegroundColor Green 
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
