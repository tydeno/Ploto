function Manage-PlotoSpawns
{
    $InputAmountToSpawn = 12
    $SpawnedCount = 0

    Do
    {
        Write-Host "PlotoManager @"(Get-Date)": Initiating Spawning..."
 
        $SpawnedPlots = Spawn-PlotoPlots

        if ($SpawnedPlots)
            {
                Write-Host "PlotoManager @"(Get-Date)": Amount of spawned Plots in this iteration: " $SpawnedPlots.Count
                Write-Host "PlotoManager @"(Get-Date)": Spawned the following plots using Ploto Spawner:" 
                Write-Host $SpawnedPlots | ft
                
            }
        else
            {
                Write-Host "PlotoManager @"(Get-Date)": No plots spawned in thy cycle, as no temp disks available"
            }


        $SpawnedCount = $SpawnedCount + $SpawnedPlots.Count 
       
        Write-Host "PlotoManager @"(Get-Date)": Overall spawned Plots since start of script: "$SpawnedCount
        Write-Host "PlotoManager @"(Get-Date)": Entering Sleep for 900, then checking again for available temp and out drives"
        Write-Host "----------------------------------------------------------------------------------------------------------------------"
        Start-Sleep 900
    }
    
    Until ($SpawnedCount -eq $InputAmountToSpawn)
}
