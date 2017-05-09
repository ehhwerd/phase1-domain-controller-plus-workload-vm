configuration CreateADPDC 
{ 
   param 
   ( 
        [Parameter(Mandatory)]
        [String]$DomainName,

        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]$Admincreds,

        [Int]$RetryCount=20,
        [Int]$RetryIntervalSec=30
    ) 
    
    Import-DscResource -ModuleName xActiveDirectory,xDisk, xNetworking, cDisk, PSDesiredStateConfiguration
    [System.Management.Automation.PSCredential ]$DomainCreds = New-Object System.Management.Automation.PSCredential ("${DomainName}\$($Admincreds.UserName)", $Admincreds.Password)
    $Interface=Get-NetAdapter|Where Name -Like "Ethernet*"|Select-Object -First 1
    $InterfaceAlias=$($Interface.Name)

    Node localhost
    {
    	
		Script createScriptFile
    {
        GetScript = {
            $File = 'C:\GetADConnect.ps1'
            $Content = 'wget https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi -O "C:\AzureADConnect.msi" ; Start-Process C:\AzureADConnect.msi'
            $Results = @{}
            $Results['FileExists'] = Test-path $File
            $Results['ContentMatches'] = Select-String -Path $File -SimpleMatch $Content -Quiet
 
            $Results
        }
        SetScript = {
            'wget https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi -O "C:\AzureADConnect.msi" ; Start-Process C:\AzureADConnect.msi' | Out-File C:\GetADConnect.ps1
        }
        TestScript = {
            $File = 'C:\GetADConnect.ps1'
            $Content = 'wget https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi -O "C:\AzureADConnect.msi" ; Start-Process C:\AzureADConnect.msi'
 
            If ((Test-path $File) -and (Select-String -Path $File -SimpleMatch $Content -Quiet)) {
                Write-Verbose 'Both File and Content Match'
                $True
            }
            Else {
                Write-Verbose 'Either File and/or content do not match'
                $False
            }
 
        }
    }

       Script runScriptFile
    {
        DependsOn = "[Script]script1"
        GetScript = {
            $File = 'C:\AzureADConnect.msi'
            $Results = @{}
            $Results['FileExists'] = Test-path $File
             
            $Results
        }
        SetScript = {
            Invoke-Expression C:\GetADConnect.ps1
        }
        TestScript = {
            $File = 'C:\AzureADConnect.msi'
             
            If ((Test-path $File)) {
                Write-Verbose 'AzureADConnect.msi Exists'
                $True
            }
            Else {
                Write-Verbose 'AzureADConnect.msi does not exist'
                $False
            }
 
        }
    }

    Script runADConnectFile
    {
        DependsOn = "[Script]script2"
        GetScript = {
            $File = 'C:\Program Files\Microsoft Azure Active Directory Connect\AzureADConnect.exe'
            $Results = @{}
            $Results['FileExists'] = Test-path $File
             
            $Results
        }
        SetScript = {
            Start-Process C:\AzureADConnect.msi
        }
        TestScript = {
            $File = 'C:\Program Files\Microsoft Azure Active Directory Connect\AzureADConnect.exe'
             
            If ((Test-path $File)) {
                Write-Verbose 'AzureADConnect.exe Exists'
                $True
            }
            Else {
                Write-Verbose 'AzureADConnect.exe does not exist'
                $False
            }
 
        }
    }
    
		Script AddADDSFeature {
            SetScript = {
                Add-WindowsFeature "AD-Domain-Services" -ErrorAction SilentlyContinue   
            }
            GetScript =  { @{} }
            TestScript = { $false }
        }
	
	    WindowsFeature DNS 
        { 
            Ensure = "Present" 
            Name = "DNS"		
        }

        Script script1
	    {
      	    SetScript =  { 
		        Set-DnsServerDiagnostics -All $true
                Write-Verbose -Verbose "Enabling DNS client diagnostics" 
            }
            GetScript =  { @{} }
            TestScript = { $false }
	        DependsOn = "[WindowsFeature]DNS"
        }

	    WindowsFeature DnsTools
	    {
	        Ensure = "Present"
            Name = "RSAT-DNS-Server"
	    }

        xDnsServerAddress DnsServerAddress 
        { 
            Address        = '127.0.0.1' 
            InterfaceAlias = $InterfaceAlias
            AddressFamily  = 'IPv4'
	        DependsOn = "[WindowsFeature]DNS"
        }

        xWaitforDisk Disk2
        {
             DiskNumber = 2
             RetryIntervalSec =$RetryIntervalSec
             RetryCount = $RetryCount
        }

        cDiskNoRestart ADDataDisk
        {
            DiskNumber = 2
            DriveLetter = "F"
        }

        WindowsFeature ADDSInstall 
        { 
            Ensure = "Present" 
            Name = "AD-Domain-Services"
	        DependsOn="[cDiskNoRestart]ADDataDisk", "[Script]AddADDSFeature"
        } 
         
        xADDomain FirstDS 
        {
            DomainName = $DomainName
            DomainAdministratorCredential = $DomainCreds
            SafemodeAdministratorPassword = $DomainCreds
            DatabasePath = "F:\NTDS"
            LogPath = "F:\NTDS"
            SysvolPath = "F:\SYSVOL"
	        DependsOn = "[WindowsFeature]ADDSInstall"
        } 
		
		# Optional GUI tools            
        WindowsFeature ADDSTools            
        {             
            Ensure = "Present"             
            Name = "RSAT-ADDS"             
        }    

        LocalConfigurationManager 
        {
            ConfigurationMode = 'ApplyOnly'
            RebootNodeIfNeeded = $true
        }
   }
} 