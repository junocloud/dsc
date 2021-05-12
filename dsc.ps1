
# create a DSC configuration to install IIS and support remote management
Configuration IISConfig {

    #define input parameter
    param(
        [string[]]$ComputerName = 'localhost'
    )

    # target machine(s) based on input param
    node $ComputerName {

        # configure the LCM
        LocalConfigurationManager {
            ConfigurationMode = "ApplyandAutoCorrect"
            ConfigurationModeFrequencyMins = 15
            RefreshMode = "Push"
        }                    
        
        # install the IIS server role
        WindowsFeature IIS {
            Ensure = "Present"
            Name = "Web-Server"
        }

        # install the IIS remote management service
        Windows Feature IISManagement {
            Name = 'Web-Mgmt-Service'
            Ensure = 'Present'
            DependsOn = @('[WindowsFeature]ISS')
        }

        # enable IIS remote management
        Registry RemoteManagement {
            Key = 'HKLM:\SOFTWARE\Microsoft\WebManagement\Server'
            ValueName = 'EnableRemoteManagement'
            ValueType = 'Dword'
            ValueData = '1'
            DependsOn = @('[WindowsFeature]IIS','[WindowsFeature]IISManagement')
        }

        # configure remote management service
        Service WMSVC {
            Name = 'WMSVC'
            StartupType = 'Automatic'
            State = 'Running'
            DependsOn = '[Registry]RemoteManagement'
        }

    }

}

# create the configuration (.mof)
IISConfig -ComputerName Bubina -OutputPath c:\bubinalab

# push the configuration to Bubina
Start-DscConfiguration -Path c:\bubinalab -Wait -Verbose


# enter poweshell remote session
Enter-PSSession -ComputerName Bubina

# view installed features
Get-WindowsFeature | Where-Object Installed -EQ True

# view LCM properties
Get-DscLocalConfigurationManager

# view configuration state
Get-DscConfigurationStatus

# test configuration drift
Test-DscConfiguration

# exit powershell remote session
Exit-PSSession