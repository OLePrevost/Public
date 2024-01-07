try {     
                # Set reg key
                New-Item -Path HKLM:\SOFTWARE\Microsoft -Name "Teams" 
                $registryPath = "HKLM:\SOFTWARE\Microsoft\Teams"
                $registryKey = "IsWVDEnvironment"
                $registryValue = "1"
                Set-RegKey -registryPath $registryPath -registryKey $registryKey -registryValue $registryValue 
                
                # Install the latest version of the Microsoft Visual C++ Redistributable
                Write-host "AVD AIB Customization: Teams Optimization - Starting the installation of latest Microsoft Visual C++ Redistributable"
                $appName = 'teams'
                $drive = 'C:\'
                New-Item -Path $drive -Name $appName  -ItemType Directory -ErrorAction SilentlyContinue
                $LocalPath = $drive + '\' + $appName 
                Set-Location $LocalPath
                $VCRedistExe = 'vc_redist.x64.exe'
                $outputPath = $LocalPath + '\' + $VCRedistExe
                Invoke-WebRequest -Uri $VCRedistributableLink -OutFile $outputPath
                Start-Process -FilePath $outputPath -Args "/install /quiet /norestart /log vcdist.log" -Wait
                Write-host "AVD AIB Customization: Teams Optimization - Finished the installation of latest Microsoft Visual C++ Redistributable"

                # Install the Remote Desktop WebRTC Redirector Service
                $webRTCMSI = 'webSocketSvc.msi'
                $outputPath = $LocalPath + '\' + $webRTCMSI
                Invoke-WebRequest -Uri $WebRTCInstaller -OutFile $outputPath
                Start-Process -FilePath msiexec.exe -Args "/I $outputPath /quiet /norestart /log webSocket.log" -Wait
                Write-host "AVD AIB Customization: Teams Optimization - Finished the installation of the Teams WebSocket Service"

                # Define the directory path
                $directoryPath = "C:\Resolution\Teams"

                # Check if the directory exists
                if (!(Test-Path -Path $directoryPath)) {
                    # Create the directory if it doesn't exist
                    New-Item -Path $directoryPath -ItemType Directory
                }

                #Download the .exe Installer for TeamsBootstrapper
                $bootStrapperUrl = "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409"
                $bootStrapperFile = "teamsbootstrapper.exe"
                $bootStrapperDestination = "$directoryPath\$bootStrapperFile"

                Invoke-WebRequest -uri $bootStrapperUrl -OutFile $bootStrapperDestination

                #Download the 64-bit MSIX Folder
                $msixUrl = "https://go.microsoft.com/fwlink/?linkid=2196106"
                $msixFile = "MSTeams-x64.msix"
                $msixDestination = "$directoryPath\$msixFile"

                Invoke-WebRequest -uri $msixUrl -OutFile $msixDestination

                #Install new Teams for AVD Client
                cd $directoryPath

                .\$bootStrapperFile -p -o "$msixFile"
}

catch {
                Write-Host "*** AVD New Teams Client ***  Teams Optimization  - Exception occured  *** : [$($_.Exception.Message)]"
}    
