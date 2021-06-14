Skip to content
Search or jump to…

Pull requests
Issues
Marketplace
Explore
 
@tydeno 
tydeno
/
Ploto
4
254
Code
Issues
9
Pull requests
Actions
Projects
1
Wiki
Security
Insights
Settings
Ploto
/
Install-Ploto.ps1
in
testing-stotikmadmax
 

Spaces

1

No wrap
1
<#
2
.SYNOPSIS
3
Name: Ploto
4
Version: 0.621
5
Author: Tydeno
6
​
7
​
8
.DESCRIPTION
9
"Installs" Ploto from your downloaded clone of Ploto. 
10
A basic Windows PowerShell based Chia Plotting Manager. Cause I was tired of spawning them myself. Basically spawns and moves Plots around.
11
https://github.com/tydeno/Ploto
12
#>
13
​
14
​
15
Write-Host "InstallPloto @"(Get-Date)": Hello there! My Name is Ploto. This script guides you trough the setup of myself." -ForegroundColor Magenta
16
​
17
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
18
​
19
Write-Verbose ("InstallPloto @"+(Get-Date)+": Path I got launched from: "+$scriptPath)
20
​
21
$PathToPloto = $scriptPath+"\Ploto.psm1"
22
Write-Verbose ("PlotoSpawner @ "+(Get-Date)+": Found available temp drives.")
23
​
24
Write-Verbose ("InstallPloto @"+(Get-Date)+": Path I calculated for where Ploto Module has to be:"+$scriptPath)
25
​
26
Write-Verbose ("InstallPloto @"+(Get-Date)+": Stitching together Module form source...")
27
​
28
#Get Version of ploto in source for folder name (posh structure)
29
$Pattern = "Version:"
30
$PlotoVersionInSource = (Get-Content $PathToPloto | Select-String $pattern).Line.Trimstart("Version: ")
31
​
32
Write-Host "InstallPloto @"(Get-Date)": Installing Version: $PlotoVersionInSource of Ploto on this machine." 
33
 
34
$DestinationForModule = $Env:ProgramFiles+"\WindowsPowerShell\Modules\"
35
$DestinationContainer = $Env:ProgramFiles+"\WindowsPowerShell\Modules\Ploto"
36
$DestinationFullPathForModule = $Env:ProgramFiles+"\WindowsPowerShell\Modules\Ploto.psm1"
37
​
38
Write-Host "InstallPloto @"(Get-Date)": Lets check if a version of Ploto is installed in:"$Env:ProgramFiles"\WindowsPowerShell\Modules" -ForegroundColor Cyan
39
​
40
If (Test-Path $DestinationContainer)
41
    {
42
        Write-Host "InstallPloto @"(Get-Date)": There is a version of Ploto installed in:"$Env:ProgramFiles"\WindowsPowerShell\Modules" -ForegroundColor Cyan
43
​
44
        #Lets get version of Script
45
        $PlotoVersionInstalled = (Get-Content $DestinationContainer"\Ploto.psm1" | Select-String $pattern).Line.Trimstart("Version: ")
@tydeno
Commit changes
Commit summary
Create Install-Ploto.ps1
Optional extended description
Add an optional extended description…
 Commit directly to the testing-stotikmadmax branch.
 Create a new branch for this commit and start a pull request. Learn more about pull requests.
 
© 2021 GitHub, Inc.
Terms
Privacy
Security
Status
Docs
Contact GitHub
Pricing
API
Training
Blog
About
