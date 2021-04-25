function Boot-Ploto
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
                        Import-Module $PathToModule

                        Copy-Item -Path $PlotoModule -Destination "C:\Windows\System32\WindowsPowerShell\v1.0\Modules"

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



$ModuleUp = Boot-Ploto
if ($ModuleUp -eq $true)
    {
      $Mover = Start-Job -ScriptBlock {Start-PlotoMove -DestinationDrive "J:" -OutDriveDenom "out"}
      $Spawner = Start-Job -ScriptBlock {Start-PlotoSpawns -InputAmountToSpawn 36 -OutDriveDenom "out" -TempDriveDenom "plot" }

    }

else
    {
    Write-Host "ERROR! Modules arent up!" -ForegroundColor Red
    }









