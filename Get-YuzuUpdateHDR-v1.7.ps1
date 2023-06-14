#Author - Nothing Loud/lionellion/ /u/Ok_Excitement5874
#Credits - Heavily inspired/borrowed code from /u/Takia_Gecko
#Special Thanks - Google Bard for helping with debugging and revising some code
#Use: This code automatically manages, backs-up, and updates your yuzu folders every time you run it. 
#Plus it auto-launches the latest yuzu EA from pinEApple and it even renames/converts your files to trigger Auto-HDR in Windows 11!
#If your yuzu is fully updated, then it checks that the files and folders are properly arranged and auto-launches Auto-HDR-capable yuzu EA.
#I wrote this myself. It may trigger virus software because it is unsigned. However, as you can see from the code below, there is nothing harmful to your system!
#Enjoy! :)

$yuzuRoamingFolder = Join-Path $env:APPDATA "yuzu"-ErrorAction SilentlyContinue
$configPath = Join-Path $yuzuRoamingFolder "updateConfig.txt" -ErrorAction SilentlyContinue
$yuzuFolder = Get-Content $configPath -ErrorAction SilentlyContinue

if ([string]::IsNullOrEmpty($yuzuFolder) -or (-not (Test-Path $yuzuFolder))) {
    # yuzuFolder not defined. Let user choose # of backups
    Write-Host "Please select number of yuzu backup folders desired"
    $numBfolders = Read-Host -Prompt "How many backups would you like to maintain?"
    Write-Host "Number of backups chosen is: $numBfolders"
 
    # yuzuFolder not defined. Let user choose to enable Auto-HDR or not
    $confirm = Read-Host -Prompt "Do you want to enable Auto-HDR for Windows 10/11 (Y/N)? (Make sure you enable it and select 'prefer layered on DXGI Swap Chain' on Vulkan/OpenGL Present Method in NVIDIA Control Panel)"
    Write-Host "If you want to change your Auto-HDR selection, find your AppData/Roaming/yuzu directory and clear the text in your updateConfig.txt"

    # yuzuFolder not defined. Let user choose folder
    Write-Host "Please select yuzu program folder (the folder containing yuzu.exe or 'cemu.exe' renamed and used for Auto-HDR)"
    Add-Type -AssemblyName System.Windows.Forms
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog `
      -Property @{
        Description = "Select folder containing yuzu.exe or 'cemu.exe'"
      }
    $FolderBrowser.Description = "Select folder containing yuzu.exe or 'cemu.exe'"
    $result = $FolderBrowser.ShowDialog()

    if ($result -eq [Windows.Forms.DialogResult]::OK) {
    $yuzuFolder = $FolderBrowser.SelectedPath
    }
    else {
    # user pressed cancel
    exit
    }
    # write folder location to %appdata%\yuzu\updateConfig.txt
    Set-Content $configPath -Value $yuzuFolder
}


$parentFolder = Split-Path $yuzuFolder -Parent -ErrorAction SilentlyContinue


while (-not (((Test-Path (Join-Path $yuzuFolder "yuzu.exe"))) -or ((Test-Path (Join-Path $yuzuFolder "cemu.exe"))))) {

    # yuzuFolder not defined. Let user choose folder
    Write-Host "Please select yuzu program folder (the folder containing yuzu.exe or "cemu.exe" used for Auto-HDR)"
    Add-Type -AssemblyName System.Windows.Forms
    $FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog `
      -Property @{
        Description = "Select folder containing yuzu.exe or 'cemu.exe'"
      }
    $FolderBrowser.Description = "Select folder containing yuzu.exe or 'cemu.exe'"
    $result = $FolderBrowser.ShowDialog()

    if ($result -eq [Windows.Forms.DialogResult]::OK) {
    $yuzuFolder = $FolderBrowser.SelectedPath
    }
    else {
    # user pressed cancel
    exit
    }
# write folder location to %appdata%\yuzu\updateConfig.txt
Set-Content $configPath -Value $yuzuFolder
}

Write-Host "Folder assigned as yuzu folder and will now be checked."
$originalName = Split-Path $yuzuFolder -Leaf
$exePath = Join-Path $yuzuFolder "yuzu.exe"
$version = $null

if (Test-Path $exePath) {
  Write-Host "yuzu.exe found at $exePath"
  $exeContent = Get-Content $exePath
  $version = ([regex]::match($exeContent, "\x00{3}\d{4}\x00{8}").Value)[3..6] -join ""
} else {
  $exePath = Join-Path $yuzuFolder "cemu.exe"
  if (Test-Path $exePath) {
    Write-Host "cemu.exe found at $exePath"
    $exeContent = Get-Content $exePath
    $version = ([regex]::match($exeContent, "\x00{3}\d{4}\x00{8}").Value)[3..6] -join ""
  } else {
    Write-Host "Neither yuzu.exe nor cemu.exe found"

  }
}

$bfconfirmPath = ".\backupconfirm.txt"
$bfconfirm | Out-File $bfconfirmPath

# Write the version information to the console
Write-Host "The version of yuzu is $version"

$content = Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/pineappleEA/pineapple-src/releases/latest"
$latestVersionnum = ([regex]::match($content.RawContent, "Release EA-\d\d\d\d").Value)[-4..-1] -join ""
Write-Host "The latest yuzu version $latestVersionnum"

# Check if the latest version of yuzu is available.
function Get-LatestVersion {
    # Get the latest version of yuzu from GitHub.
    $content = Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/pineappleEA/pineapple-src/releases/latest"
    $latestVersion = ([regex]::match($content.RawContent, "Release EA-\d\d\d\d").Value)[-4..-1] -join ""

    # Return the latest version.
    return $latestVersion
    }

# If the latest version of yuzu is available, download it.
if ($latestVersionnum -ne $null -and $latestVersionnum -ne $version) {
    # Write a message to the console.
    Write-Host "Updating yuzu..."

    # Check if the folder exists.
    if ($null -eq (Test-Path $yuzuFolder)) {
    # The folder does not exist, so create it.
    New-Item -Directory $yuzuFolder -Force -ErrorAction SilentlyContinue
    $yuzuFolder = Join-Path $parentFolder $originalName
    }

    # Create a new folder for the backup.
    $backupFolder = $yuzuFolder
    New-Item -ItemType Directory -Force $backupFolder
    # Copy all of the files and folders from the yuzu folder to the backup folder.
    Write-Host "Creating backup of Yuzu EA $version"
    # Collect yuzu files for later backup.
    # Copy the contents of the yuzu folder to the backup folder.
    Copy-Item $yuzuFolder -Destination $parentFolder -Recurse -Force -ErrorAction SilentlyContinue
    Rename-Item $yuzuFolder "yuzu-backup-$version" -Force -ErrorAction SilentlyContinue
    Write-Host "Backup successful!"


    # Download the latest version of yuzu
    $downloadUrl = "https://github.com/pineappleEA/pineapple-src/releases/download/EA-$latestVersionnum/Windows-Yuzu-EA-$latestVersionnum.zip"
    Write-Host("Download URL is: $downloadUrl")
    # Get the path to the download file.
    $parentFolder = Split-Path $yuzuFolder -Parent
    $downloadFilePath = Join-Path $parentFolder "yuzu-$latestVersionnum.zip"
    $downloadFile = New-Item -Force $downloadFilePath

    # Check if the download file exists.
    if (Test-Path $downloadFilePath) {
        # Download the file.
        $downloadFile = Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadFile
        Write-Host "Download of Yuzu EA $latestVersionnum successful"

    }
    # Unzip the file.
    Write-Host "Unzipping files now..."


    if (Test-Path $downloadFilePath) {
        # Check if the zip file is corrupt.
        if ((Get-Item $downloadFilePath).Length -eq 0) {
            Write-Error "The zip file is corrupt."
            return
        }

        # Expand the archive.
        Expand-Archive $downloadFilePath -Destination $parentFolder -Force -ErrorAction SilentlyContinue

        # Get the directory path of the extracted archive.
        $downloadFileExtracted = Join-Path $parentFolder "yuzu-windows-msvc-early-access"

        # Wait for the file to finish unzipping.
        Start-Sleep 5

        Write-Host "Files unzipped."
        }


        # Check if the archive was successfully expanded.
        if ($null -ne (Test-Path (Split-Path -Path $downloadFileExtracted))) {
            # The archive was successfully expanded, so rename the folder.
            $newYuzuFolder = $downloadFileExtracted
            Write-Host "The archive was successfully extracted."
            #Reorganize directories.
            Rename-Item $newYuzuFolder "yuzu"  -Force -ErrorAction SilentlyContinue
            $newYuzuFolderPath = Join-Path $parentFolder "yuzu"
            # Get the leaf node of the path.
            $newYuzuFolderName = Split-Path $newYuzuFolderPath -Leaf
            # Rename the folder.
            $newYuzuFolderContents = Get-ChildItem $newYuzuFolderPath -Recurse
        }

        Write-Host "Deleting old files and rearranging folders..."
        Remove-Item -Path $downloadFilePath -r -ErrorAction SilentlyContinue
        #Remove-Item -Path $yuzuFolder -r -ErrorAction SilentlyContinue
        
# Make sure yuzu folder is definitely named/renamed "yuzu"
Rename-Item $newYuzuFolderPath "yuzu" -Force -ErrorAction SilentlyContinue
    
Write-Host "Yuzu EA Update complete!"
$yuzuFolder = Join-Path $parentFolder $newYuzuFolderName


$reshadeFiles = Get-ChildItem -Path (Join-Path $parentFolder "yuzu-backup-$version") -Filter "reshade*" -ErrorAction SilentlyContinue
if ($reshadeFiles -ne $null) {
    Copy-Item $reshadeFiles -Destination $yuzuFolder -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "ReShade installation detected and maintained."
}

} else {
Write-Host "Update not required. Yuzu EA is already the most up-to-date version!"
# Make sure yuzu folder is definitely named/renamed "yuzu"
Rename-Item $yuzuFolder "yuzu" -Force -ErrorAction SilentlyContinue

$reshadeFiles = Get-ChildItem -Path $yuzuFolder -Filter "reshade*" -ErrorAction SilentlyContinue
if ($reshadeFiles -ne $null) {
    Write-Host "ReShade installation detected and maintained."
}
}

Write-Host "Yuzu folder is at $yuzuFolder"

Write-Host "Latest backup yuzu folder is at $backupFolder"

$bfolders = Get-ChildItem -Path $parentFolder -Filter "yuzu-backup*"
$bfconfirmPath = "$parentFolder/backupconfirm.txt"
$numBfolders | Out-File $bfconfirmPath
$numBackups = $bfolders.Count

if ($numBackups -gt $numBfolders) {
   Write-Host "There are more than $numBfolders backup folders. Removing the oldest ones."

   $oldestBackups = $bfolders | Sort-Object LastWriteTime -Descending | Select-Object -First $numBfolders -Skip $numBfolders

   foreach ($oldestBackup in $oldestBackups) {
       Remove-Item -Path "$parentFolder/$oldestBackup" -Recurse
   }
}

#enabling Auto-HDR if confirmed
    if ($confirm -eq "Y") {
        Write-Host "Now checking and/or renaming yuzu.exe files to cemu.exe to make them Auto-HDR capable"
        $exeFiles = Get-ChildItem -Path $yuzuFolder -Filter "yuzu*.exe" -ErrorAction SilentlyContinue
            if ($exeFiles -ne $null) {
                foreach($file in $exeFiles.FullName) {
                  # Get the path to the file without the parent directory.
                  $fileName = Split-Path $file -Leaf
                  # Replace the word "yuzu" with "cemu" in the file name.
                  $newName = $fileName.replace("yuzu", "cemu")

                  # Copy the file to a new location with the new file name.
                  Rename-Item $file $newName -Force -ErrorAction SilentlyContinue
                }
            }
    Write-Host "Yuzu EA (Auto-HDR enabled) check and updates successful! Ready to launch yuzu."
    # write folder location to %appdata%\yuzu\updateConfig.txt
    Set-Content $configPath -Value $yuzuFolder
    Write-Host "Starting yuzu..."
    $confirm = 'y'
    $confirmPath = ".\HDRconfirm.txt"
    $confirm | Out-File $confirmPath
    Write-Host "Closing this window in 10 seconds..."
    Start-Process (Join-Path $yuzuFolder "cemu.exe")
    } else {
      Write-Host "Auto-HDR is NOT enabled."
      Write-Host "Yuzu EA (Auto-HDR disabled) check and updates successful! Ready to launch yuzu."
      # write folder location to %appdata%\yuzu\updateConfig.txt
      Set-Content $configPath -Value $yuzuFolder 
      Write-Host "Starting yuzu..."
      $confirm = 'n'
      $confirmPath = ".\HDRconfirm.txt"
      $confirm | Out-File $confirmPath
      Write-Host "Closing this window in 10 seconds..."
      Start-Process (Join-Path $yuzuFolder "yuzu.exe")
    }
Start-Sleep -Seconds 10