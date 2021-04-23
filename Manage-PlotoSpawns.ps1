function Manage-PlotoSpawns
{
    $InputAmountToSpawn = 12
    $SpawnedCount = 0

    Do
    {
        Write-Host "Initiating Spawning..."
 
        $SpawnedPlots = Spawn-PlotoPlots
        $SpawnedCount + $SpawnedPlots.Count | Out-Null
        Write-Host "Amount of spawned Plots in this iteration: " $SpawnedPlots.Count
        Write-Host "Overall spawned Plots since start of script: "$SpawnedCount
        

        Write-Host "Entering Sleep for 3600, then checking again for available temp and out drives"
        Start-Sleep 3600
    }
    
    Until ($SpawnedCount -ne $InputAmountToSpawn)
}
