# Ploto
A Windows PowerShell based Chia Plotting Manager.

# How it works
Ploto checks periodically, if a TempDrive and OutDrive is available for plotting. 
If there is no TempDrive available, or no OutDrive, Ploto checks again in 3600 seconds.

When there is one available, Ploto determines the best OutDrive (most free space) and calls chia.exe to start the plot.
Ploto iterates once through all available TempDrives and spawns a plot per each TempDrive (as long as enough OutDrive space is given).
After that, Ploto checks if amount Spawned is equal as defined as input. If not, Ploto keeps going until it is.

# Config
TempDrives and OutDrives are the key-concept used by Ploto.
You can edit the definition of Temp & OutDrives directly in the scripts hardocded variable.

# FAQ
Can I shut down the script when I dont want Ploto to spawn more Plots?
Yep. The individual Chia Plot Jobs wont be affected by that.
