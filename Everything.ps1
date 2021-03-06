## Created: 08/15/2017 15:49:35
$jobs = @{}
function ForceRegKey ($path) {
    if (!(Test-path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

$definition = @"
    using System;
    using System.Runtime.InteropServices;
    namespace Win32Api
    {
        public class NtDll
        {
            [DllImport("ntdll.dll", EntryPoint="RtlAdjustPrivilege")]
            public static extern int RtlAdjustPrivilege(ulong Privilege, bool Enable, bool CurrentThread, ref bool Enabled);
        }
    }
"@
                     
if (-not ("Win32Api.NtDll" -as [type])) 
{
    Add-Type -TypeDefinition $definition -PassThru | out-null
}
else
{
    ("Win32Api.NtDll" -as [type]) | Out-Null
}

function TakeownRegistry($key) {

    # Enable SeTakeOwnershipPrivilege
    $bEnabled = $false
    $res = [Win32Api.NtDll]::RtlAdjustPrivilege(9, $true, $false, [ref]$bEnabled)

    $firstPart = $key.split('\')[0]
    $hive = $null
    $subkey = $null
    switch ($firstPart) {
        "HKEY_CLASSES_ROOT" {
            $hive = [Microsoft.Win32.Registry]::ClassesRoot
            $subkey = $key.substring($firstPart.length + 1)
        }
        "HKEY_CURRENT_USER" {
            $hive = [Microsoft.Win32.Registry]::CurrentUser
            $subkey = $key.substring($firstPart.length + 1)
        }
        "HKEY_LOCAL_MACHINE" {
            $hive = [Microsoft.Win32.Registry]::LocalMachine
            $subkey = $key.substring($firstPart.length + 1)
        }
    }

    # get administraor group
    $admins = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    $admins = $admins.Translate([System.Security.Principal.NTAccount])

    # set owner
    $key = $hive.OpenSubKey($subkey, "ReadWriteSubTree", "TakeOwnership")
    $acl = $key.GetAccessControl()
    $acl.SetOwner($admins)
    $key.SetAccessControl($acl)

    # set FullControl
    $acl = $key.GetAccessControl()
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($admins, "FullControl", "Allow")
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)

}



## Job: ChangePSExecutionPolicty, C:\dev\VM_Setup\00_Windows\ChangePSExecutionPolicty.ps1
$jobs.Add("\00_Windows\ChangePSExecutionPolicty.ps1", {
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force 
})


## Job: DisableAutomaticProxyCache, C:\dev\VM_Setup\00_Windows\DisableAutomaticProxyCache.ps1
$jobs.Add("\00_Windows\DisableAutomaticProxyCache.ps1", {
#Disable Automatic Proxy Result Cache
$key = "HKCU:\Software\Policies\Microsoft\Windows\CurrentVersion\Internet Settings"
ForceRegKey($key)
Set-ItemProperty -Path  $key -Name EnableAutoproxyResultCache -Type DWORD -Value 0x0 -Force

})


## Job: DisableErrorReporting, C:\dev\VM_Setup\00_Windows\DisableErrorReporting.ps1
$jobs.Add("\00_Windows\DisableErrorReporting.ps1", {

# Disable Windows Error Reporting
ForceRegKey("HKLM:\Software\Policies\Microsoft\PCHealth\ErrorReporting")
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\PCHealth\ErrorReporting" -Name DoReport -Type DWORD -Value 0x0 -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\Windows Error Reporting" -Name Disabled -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\AeDebug" -Name Auto -Type String -Value 1 -Force

})


## Job: DisableFirewall, C:\dev\VM_Setup\00_Windows\DisableFirewall.ps1
$jobs.Add("\00_Windows\DisableFirewall.ps1", {
# Disable Firewall
netsh advfirewall set AllProfiles state off

})


## Job: DisableFontLogging, C:\dev\VM_Setup\00_Windows\DisableFontLogging.ps1
$jobs.Add("\00_Windows\DisableFontLogging.ps1", {
$key = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\MitigationOptions'
ForceRegKey($key)
Set-ItemProperty -Path $key -Name 'MitigationOptions_FontBocking' -Value 2000000000000 -ea SilentlyContinue 
})


## Job: DisableIPv6, C:\dev\VM_Setup\00_Windows\DisableIPv6.ps1
$jobs.Add("\00_Windows\DisableIPv6.ps1", {
# Disable IPv6
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name DisabledComponents -Value 0xff -Force

})


## Job: DisableLLMNR, C:\dev\VM_Setup\00_Windows\DisableLLMNR.ps1
$jobs.Add("\00_Windows\DisableLLMNR.ps1", {
#Disable LLMNR
$key = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
ForceRegKey($key)
Set-ItemProperty -Path $key -Name EnableMulticast -Type DWORD -Value 0x0 -Force

})


## Job: DisableNetBios, C:\dev\VM_Setup\00_Windows\DisableNetBios.ps1
$jobs.Add("\00_Windows\DisableNetBios.ps1", {

#Disable NetBios
Stop-Service -Name lmhosts -Force
Set-Service -Name lmhosts -StartupType Disabled
$key = "HKLM:\System\CurrentControlSet\Services\VxD\MSTCP"
ForceRegkey($key)
Set-ItemProperty -Path $key -Name EnableDNS -Type String -Value 0 -Force

})


## Job: DisableNetworkAwareness, C:\dev\VM_Setup\00_Windows\DisableNetworkAwareness.ps1
$jobs.Add("\00_Windows\DisableNetworkAwareness.ps1", {

# Disable Network Awareness
$key = "HKLM:\System\CurrentControlSet\Services\NlaSvc\Parameters\Internet"
ForceRegKey($key)
Set-ItemProperty -Path $key -Name EnableActiveProbing -Value 0x0 -Force


})


## Job: DisableSSDP, C:\dev\VM_Setup\00_Windows\DisableSSDP.ps1
$jobs.Add("\00_Windows\DisableSSDP.ps1", {
# Disable SSDP
Stop-Service -Name SSDPSRV -Force
Set-Service -Name SSDPSRV -StartupType Disabled

})


## Job: DisableSystemRestore, C:\dev\VM_Setup\00_Windows\DisableSystemRestore.ps1
$jobs.Add("\00_Windows\DisableSystemRestore.ps1", {
$key = "HKLM:\Software\Policies\Microsoft\Windows NT\SystemRestore"
ForceRegKey($key)
Set-ItemProperty -Path $key -Name 'DisableSR' -Value 1 -Force
})


## Job: DisableTeredo, C:\dev\VM_Setup\00_Windows\DisableTeredo.ps1
$jobs.Add("\00_Windows\DisableTeredo.ps1", {
#Disable Teredo
netsh interface teredo set state disabled

})


## Job: DisableTimeService, C:\dev\VM_Setup\00_Windows\DisableTimeService.ps1
$jobs.Add("\00_Windows\DisableTimeService.ps1", {

#Disable Time Service
Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Services\W32Time\Parameters" -Name Type -Type String -Value NoSync -Force


})


## Job: DisableWindowsDefender, C:\dev\VM_Setup\00_Windows\DisableWindowsDefender.ps1
$jobs.Add("\00_Windows\DisableWindowsDefender.ps1", {
# Disable Windows Defender

Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Type DWord -Value 1



$tasks = @(
    "\Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance"
    "\Microsoft\Windows\Windows Defender\Windows Defender Cleanup"
    "\Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan"
    "\Microsoft\Windows\Windows Defender\Windows Defender Verification"
)

foreach ($task in $tasks) {
    $parts = $task.split('\')
    $name = $parts[-1]
    $path = $parts[0..($parts.length-2)] -join '\'
    
    Disable-ScheduledTask -TaskName "$name" -TaskPath "$path"
}

#"Disabling Windows Defender via Group Policies"
ForceRegKey "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Type DWord -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender" -Name "DisableRoutinelyTakingAction" -Type DWord -Value 1
ForceRegKey "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender\Real-Time Protection"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Type DWord -Value 1

#"Disabling Windows Defender Services"
TakeownRegistry("HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\WinDefend")
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" "Start" 4
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WinDefend" "AutorunsDisabled" 3
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc" "Start" 4
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WdNisSvc" "AutorunsDisabled" 3
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Sense" "Start" 4
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Sense" "AutorunsDisabled" 3

#"Removing Windows Defender context menu item"
Set-Item -Path "HKLM:\SOFTWARE\Classes\CLSID\{09A47860-11B0-4DA5-AFA5-26D86198A780}\InprocServer32" -Value ""

#"Removing Windows Defender GUI / tray from autorun"
Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "WindowsDefender" -ea 0
})


## Job: DisableWPAD, C:\dev\VM_Setup\00_Windows\DisableWPAD.ps1
$jobs.Add("\00_Windows\DisableWPAD.ps1", {
#Disable WPAD
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" -Name WpadOverride -Type DWORD -Value 0x1 -Force

})


## Job: EnableCommandLineLoggingOnProcessStart, C:\dev\VM_Setup\00_Windows\EnableCommandLineLoggingOnProcessStart.ps1
$jobs.Add("\00_Windows\EnableCommandLineLoggingOnProcessStart.ps1", {
$key = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit'
#Create the key if missing 
ForceRegKey $key

#Enable the Policy
Set-ItemProperty -Path $key -Name 'ProcessCreationIncludeCmdLine_Enabled' -Value 1 -ea SilentlyContinue 
})


## Job: misc, C:\dev\VM_Setup\00_Windows\misc.ps1
$jobs.Add("\00_Windows\misc.ps1", {

#Disable Several Windows options for Internet access via Policy
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\SQMClient\Windows" -Name CEIPEnable -Type DWORD -Value 0x0 -Force
#Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\WindowsUpdate" -Name DisableWindowsUpdateAccess -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\NetworkConnectivityStatusIndicator" -Name NoActiveProbe -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\DriverSearching" -Name DontSearchWindowsUpdate -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\SearchCompanion" -Name DisableContentFileUpdates -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoInternetOpenWith -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoWebServices -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\TabletPC" -Name PreventHandwritingDataSharing -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Messenger\Client" -Name CEIP -Type DWORD -Value 0x0 -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoPublishingWizard -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name NoOnlinePrintsWizard -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Registration Wizard Control" -Name NoRegistration -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\Internet Connection Wizard" -Name ExitOnMSICW -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\PCHealth\HelpSvc" -Name MicrosoftKBSearch -Type DWORD -Value 0x0 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\PCHealth\HelpSvc" -Name Headlines -Type DWORD -Value 0x0 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\HandwritingErrorReports" -Name PreventHandwritingErrorReports -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Printers" -Name DisableHTTPPrinting -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows NT\Printers" -Name DisableWebPnPDownload -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\EventViewer" -Name MicrosoftEventVwrDisableLinks -Type DWORD -Value 0x1 -Force
Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\SystemCertificates\AuthRoot" -Name DisableRootAutoUpdate /DWORD -Value 0x1 -Force


})


## Job: DisableJavaUpdateScheduler, C:\dev\VM_Setup\01_Java\DisableJavaUpdateScheduler.ps1
$jobs.Add("\01_Java\DisableJavaUpdateScheduler.ps1", {

Remove-Item -Path "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" -Name "SunJavaUpdateSched" -Force
Remove-Item -Path "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" -Name "SunJavaUpdateSched" -Force

$jusched="C:\Program Files\Common Files\Java\Java Update\jusched.exe"

if (Test-Path $jusched) {
	Rename-Item -Path $jusched -NewName ($jusched + ".bak")
}

$jusched="C:\Program Files (86)\Common Files\Java\Java Update\jusched.exe"
if (Test-Path $jusched) {
	Rename-Item -Path $jusched -NewName ($jusched + ".bak")
}




})


## Job: DisableActiveXFiltering, C:\dev\VM_Setup\02_InternetExplorer\DisableActiveXFiltering.ps1
$jobs.Add("\02_InternetExplorer\DisableActiveXFiltering.ps1", {
#Create the key if missing 
$key = 'HKLM:\Software\Policies\Microsoft\Internet Explorer\Safety\ActiveXFiltering'
ForceRegkey($key)
#Disable the Policy 
Set-ItemProperty -Path $key -Name 'IsEnabled' -Value 0 -Force

})


## Job: DisableAutoCrashRecovery, C:\dev\VM_Setup\02_InternetExplorer\DisableAutoCrashRecovery.ps1
$jobs.Add("\02_InternetExplorer\DisableAutoCrashRecovery.ps1", {
#Create the key if missing 
$key = 'HKLM:\Software\Policies\Microsoft\Internet Explorer\Recovery'
ForceRegkey($key)

#Enable the Policy
Set-ItemProperty -Path $key -Name 'AutoRecover' -Value 2 -ea SilentlyContinue 
})


## Job: DisableBrowserGeolocation, C:\dev\VM_Setup\02_InternetExplorer\DisableBrowserGeolocation.ps1
$jobs.Add("\02_InternetExplorer\DisableBrowserGeolocation.ps1", {
#Create the key if missing 
$key = 'HKLM:\Software\Policies\Microsoft\Internet Explorer\Geolocation'
ForceRegKey($key)
#Enable the Policy
Set-ItemProperty -Path $key -Name 'PolicyDisableGeolocation' -Value 1 -Force
})


## Job: DisablePerfCheck, C:\dev\VM_Setup\02_InternetExplorer\DisablePerfCheck.ps1
$jobs.Add("\02_InternetExplorer\DisablePerfCheck.ps1", {
#Create the key if missing 
$key = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Ext"
ForceRegKey($key)
#Enable the Policy
Set-ItemProperty -Path $key -Name 'DisableAddonLoadTimePerformanceNotifications' -Value 1 -Force
})


## Job: DisableSecuritySettingsCheck, C:\dev\VM_Setup\02_InternetExplorer\DisableSecuritySettingsCheck.ps1
$jobs.Add("\02_InternetExplorer\DisableSecuritySettingsCheck.ps1", {
#Create the key if missing 
$key = "HKLM:\Software\Policies\Microsoft\Internet Explorer\Security"
ForceRegKey($key)
#Enable the Policy
Set-ItemProperty -Path $key -Name 'DisableSecuritySettingsCheck' -Value 1 -Force
})


## Job: DisableSmartScreen, C:\dev\VM_Setup\02_InternetExplorer\DisableSmartScreen.ps1
$jobs.Add("\02_InternetExplorer\DisableSmartScreen.ps1", {
#Create the key if missing 
$key = "HKLM:\Software\Policies\Microsoft\Internet Explorer\PhishingFilter"
ForceRegKey($key)

#Settings 
Set-ItemProperty -Path $key -Name 'EnabledV8' -Value 0 -Force
})


## Job: DisableSuggestedSites, C:\dev\VM_Setup\02_InternetExplorer\DisableSuggestedSites.ps1
$jobs.Add("\02_InternetExplorer\DisableSuggestedSites.ps1", {
#Create the key if missing 
$key = "HKLM:\Software\Policies\Microsoft\Internet Explorer\Suggested Sites"
ForceRegKey($key)

#Disable the Policy 
Set-ItemProperty -Path $key -Name 'Enabled' -Value 0 -Force
})


## Job: DisableUpdateCheck, C:\dev\VM_Setup\02_InternetExplorer\DisableUpdateCheck.ps1
$jobs.Add("\02_InternetExplorer\DisableUpdateCheck.ps1", {
#Create the key if missing 
$key = "HKLM:\Software\Policies\Microsoft\Internet Explorer\Infodelivery\Restrictions"
ForceRegKey($key)
#Enable the Policy
Set-ItemProperty -Path $key -Name 'NoUpdateCheck' -Value 1 -Force


#Create the key if missing 
$key = "HKLM:\Software\Policies\Microsoft\Internet Explorer\Main"
ForceRegKey($key)
#Disable the Policy 
Set-ItemProperty -Path $key -Name 'EnableAutoUpgrade' -Value 0 -ea SilentlyContinue 

})


## Job: EnableActiveX, C:\dev\VM_Setup\02_InternetExplorer\EnableActiveX.ps1
$jobs.Add("\02_InternetExplorer\EnableActiveX.ps1", {
#Create the key if missing 
$key = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\Ext"
ForceRegkey($key)
#Enable the Policy
Set-ItemProperty -Path $key -Name 'NoFirsttimeprompt' -Value 1 -ea SilentlyContinue 

})


## Job: EnablePopUps, C:\dev\VM_Setup\02_InternetExplorer\EnablePopUps.ps1
$jobs.Add("\02_InternetExplorer\EnablePopUps.ps1", {
#Create the key if missing 
$key ="HKLM:\Software\Policies\Microsoft\Internet Explorer\Restrictions"
ForceRegkey($key)

#Enable the Policy
Set-ItemProperty -Path $key -Name 'NoPopupManagement' -Value 1 -ea SilentlyContinue 

})


## Job: fakeIEHistory, C:\dev\VM_Setup\02_InternetExplorer\fakeIEHistory.ps1
$jobs.Add("\02_InternetExplorer\fakeIEHistory.ps1", {
if (Test-NetConnection) {
    1..100 | % {
        [System.Diagnostics.Process]::Start("http://www.randomwebsite.com/cgi-bin/random.pl")
    }
} else {
    ##TODO: How to fake IE history while offline
}

})


## Job: SetNewTabPage, C:\dev\VM_Setup\02_InternetExplorer\SetNewTabPage.ps1
$jobs.Add("\02_InternetExplorer\SetNewTabPage.ps1", {
#Create the key if missing 
$key = "HKLM:\Software\Policies\Microsoft\Internet Explorer\TabbedBrowsing"
ForceRegKey($key)

#Settings 
Set-ItemProperty -Path $key -Name 'NewTabPageShow' -Value 0 -ea SilentlyContinue 
})


## Job: AcceptEULA, C:\dev\VM_Setup\03_Acrobat\AcceptEULA.ps1
$jobs.Add("\03_Acrobat\AcceptEULA.ps1", {
#Create the key if missing 
If((Test-Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\AdobeViewer') -eq $false ) { New-Item -Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\AdobeViewer' -force -ea SilentlyContinue } 

#Enable the Policy
Set-ItemProperty -Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\AdobeViewer' -Name 'EULA' -Value 1 -ea SilentlyContinue 

})


## Job: DisableAutomaticUpdates, C:\dev\VM_Setup\03_Acrobat\DisableAutomaticUpdates.ps1
$jobs.Add("\03_Acrobat\DisableAutomaticUpdates.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown') -eq $false ) { New-Item -Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown' -force -Force } 

#Enable the Policy
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown' -Name 'bUpdater' -Value 1 -Force
})


## Job: DisableFeedback, C:\dev\VM_Setup\03_Acrobat\DisableFeedback.ps1
$jobs.Add("\03_Acrobat\DisableFeedback.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown') -eq $false ) { New-Item -Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown' -force -Force } 

#Disable the Policy 
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown' -Name 'bUsageMeasurement' -Value 0 -Force
})


## Job: DisableInDocMessages, C:\dev\VM_Setup\03_Acrobat\DisableInDocMessages.ps1
$jobs.Add("\03_Acrobat\DisableInDocMessages.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown\cIPM') -eq $false ) { New-Item -Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown\cIPM' -force -Force } 

#Disable the Policy 
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown\cIPM' -Name 'bDontShowMsgWhenViewingDoc' -Value 0 -Force 
})


## Job: DisableProtectedMode, C:\dev\VM_Setup\03_Acrobat\DisableProtectedMode.ps1
$jobs.Add("\03_Acrobat\DisableProtectedMode.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown') -eq $false ) { New-Item -Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown' -force -Force } 

#Disable the Policy 
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown' -Name 'bProtectedMode' -Value 0 -Force 

})


## Job: DisableSpashScreen, C:\dev\VM_Setup\03_Acrobat\DisableSpashScreen.ps1
$jobs.Add("\03_Acrobat\DisableSpashScreen.ps1", {
#Create the key if missing 
If((Test-Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\Originals') -eq $false ) { New-Item -Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\Originals' -force -ea SilentlyContinue } 

#Disable the Policy 
Set-ItemProperty -Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\Originals' -Name 'bDisplayAboutDialog' -Value 0 -ea SilentlyContinue 

})


## Job: DisableStartUpMessages, C:\dev\VM_Setup\03_Acrobat\DisableStartUpMessages.ps1
$jobs.Add("\03_Acrobat\DisableStartUpMessages.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown\cIPM') -eq $false ) { New-Item -Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown\cIPM' -force -Force } 

#Disable the Policy 
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Adobe\Acrobat Reader\2017\FeatureLockdown\cIPM' -Name 'bShowMsgAtLaunch' -Value 0 -Force 
})


## Job: EnableJS, C:\dev\VM_Setup\03_Acrobat\EnableJS.ps1
$jobs.Add("\03_Acrobat\EnableJS.ps1", {
#Create the key if missing 
If((Test-Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\JSPrefs') -eq $false ) { New-Item -Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\JSPrefs' -force -ea SilentlyContinue } 

#Enable the Policy
Set-ItemProperty -Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\JSPrefs' -Name 'bEnableJS' -Value 1 -ea SilentlyContinue 

})


## Job: TrustWindowsZones, C:\dev\VM_Setup\03_Acrobat\TrustWindowsZones.ps1
$jobs.Add("\03_Acrobat\TrustWindowsZones.ps1", {
#Create the key if missing 
If((Test-Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\TrustManager') -eq $false ) { New-Item -Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\TrustManager' -force -ea SilentlyContinue } 

#Enable the Policy
Set-ItemProperty -Path 'HKCU:\Software\Adobe\Acrobat Reader\2017\TrustManager' -Name 'bTrustOSTrustedSites' -Value 1 -ea SilentlyContinue 

})


## Job: DisableBuiltinDNS, C:\dev\VM_Setup\03_Chrome\DisableBuiltinDNS.ps1
$jobs.Add("\03_Chrome\DisableBuiltinDNS.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\Software\Policies\Google\Chrome') -eq $false ) { New-Item -Path 'HKLM:\Software\Policies\Google\Chrome' -force -Force } 

#Disable the Policy 
Set-ItemProperty -Path 'HKLM:\Software\Policies\Google\Chrome' -Name 'BuiltInDnsClientEnabled' -Value 0 -Force 
})


## Job: DisableSafeBrowsing, C:\dev\VM_Setup\03_Chrome\DisableSafeBrowsing.ps1
$jobs.Add("\03_Chrome\DisableSafeBrowsing.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\Software\Policies\Google\Chrome') -eq $false ) { New-Item -Path 'HKLM:\Software\Policies\Google\Chrome' -force -Force } 

#Disable the Policy 
Set-ItemProperty -Path 'HKLM:\Software\Policies\Google\Chrome' -Name 'SafeBrowsingEnabled' -Value 0 -Force 
})


## Job: DisableSafeSearch, C:\dev\VM_Setup\03_Chrome\DisableSafeSearch.ps1
$jobs.Add("\03_Chrome\DisableSafeSearch.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\Software\Policies\Google\Chrome') -eq $false ) { New-Item -Path 'HKLM:\Software\Policies\Google\Chrome' -force -Force } 

#Disable the Policy 
Set-ItemProperty -Path 'HKLM:\Software\Policies\Google\Chrome' -Name 'ForceGoogleSafeSearch' -Value 0 -Force 

})


## Job: DisableUpdates, C:\dev\VM_Setup\03_Chrome\DisableUpdates.ps1
$jobs.Add("\03_Chrome\DisableUpdates.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\Software\Policies\Google\Update') -eq $false ) { New-Item -Path 'HKLM:\Software\Policies\Google\Update' -force} 

#Settings 
Set-ItemProperty -Path 'HKLM:\Software\Policies\Google\Update' -Name 'UpdateDefault' -Value 0 -Force

#Settings 
Set-ItemProperty -Path 'HKLM:\Software\Policies\Google\Update' -Name 'AutoUpdateCheckPeriodMinutes' -Value 0 -Force
})


## Job: DisableAddOnWizard, C:\dev\VM_Setup\03_Firefox\DisableAddOnWizard.ps1
$jobs.Add("\03_Firefox\DisableAddOnWizard.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\Software\Policies\Mozilla\Firefox') -eq $false ) { New-Item -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -force -ea SilentlyContinue } 

#Enable the Policy
Set-ItemProperty -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -Name 'DisableAddonWizard' -Value 1 -ea SilentlyContinue 
})


## Job: DisableAutomaticUpdates, C:\dev\VM_Setup\03_Firefox\DisableAutomaticUpdates.ps1
$jobs.Add("\03_Firefox\DisableAutomaticUpdates.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\Software\Policies\Mozilla\Firefox') -eq $false ) { New-Item -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -force -ea SilentlyContinue } 

#Settings 
Set-ItemProperty -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -Name 'DisableUpdate' -Value 1 -ea SilentlyContinue 
Set-ItemProperty -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -Name 'DisableExtensionsUpdate' -Value 1 -ea SilentlyContinue 
Set-ItemProperty -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -Name 'DisableSearchUpdate' -Value 1 -ea SilentlyContinue 

})


## Job: DisableDefaultBrowserCheck, C:\dev\VM_Setup\03_Firefox\DisableDefaultBrowserCheck.ps1
$jobs.Add("\03_Firefox\DisableDefaultBrowserCheck.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\Software\Policies\Mozilla\Firefox') -eq $false ) { New-Item -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -force -ea SilentlyContinue } 

#Enable the Policy
Set-ItemProperty -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -Name 'DisableDefaultCheck' -Value 1 -ea SilentlyContinue 

})


## Job: DisableKnowYourRights, C:\dev\VM_Setup\03_Firefox\DisableKnowYourRights.ps1
$jobs.Add("\03_Firefox\DisableKnowYourRights.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\Software\Policies\Mozilla\Firefox') -eq $false ) { New-Item -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -force -ea SilentlyContinue } 

#Enable the Policy
Set-ItemProperty -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -Name 'DisableRights' -Value 1 -ea SilentlyContinue 

})


## Job: DisableTelemetry, C:\dev\VM_Setup\03_Firefox\DisableTelemetry.ps1
$jobs.Add("\03_Firefox\DisableTelemetry.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\Software\Policies\Mozilla\Firefox') -eq $false ) { New-Item -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -force -ea SilentlyContinue } 

#Enable the Policy
Set-ItemProperty -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -Name 'DisableTelemetry' -Value 1 -ea SilentlyContinue 

})


## Job: DisableWhatsNew, C:\dev\VM_Setup\03_Firefox\DisableWhatsNew.ps1
$jobs.Add("\03_Firefox\DisableWhatsNew.ps1", {
#Create the key if missing 
If((Test-Path 'HKLM:\Software\Policies\Mozilla\Firefox') -eq $false ) { New-Item -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -force -ea SilentlyContinue } 

#Enable the Policy
Set-ItemProperty -Path 'HKLM:\Software\Policies\Mozilla\Firefox' -Name 'SupressUpdatePage' -Value 1 -ea SilentlyContinue 

})

$OfficeVersions = Get-ChildItem -Path "HKCU:\Software\Microsoft\Office\" | Where-Object {$_.Name.Contains('.0')} | ForEach-Object { $_.PSChildName }



## Job: AllowOpeningCDRFiles, C:\dev\VM_Setup\03_Office\AllowOpeningCDRFiles.ps1
$jobs.Add("\03_Office\AllowOpeningCDRFiles.ps1", {
$key = "HKCU:\Software\Microsoft\Office\Shared Tools\Graphics Filters\Import\CDR"
ForceRegKey($key)
Set-ItemProperty -Path $key -Type DWORD -Value 0x1 -Force
})


## Job: DisableAppSecurity, C:\dev\VM_Setup\03_Office\DisableAppSecurity.ps1
$jobs.Add("\03_Office\DisableAppSecurity.ps1", {
$OfficeVersions | ForEach-Object {
    $key = "HKCU:\Software\Microsoft\Office\" + $_ + "\Common\Security"
    ForceRegKey($key)
    Set-ItemProperty -Path $key -Name "Disable" -Type DWORD -Value 0x1 -Force
}



})


## Job: DisableDEP, C:\dev\VM_Setup\03_Office\DisableDEP.ps1
$jobs.Add("\03_Office\DisableDEP.ps1", {

@("Word", "Excel", "PowerPoint") | ForEach-Object {
    $app = $_
    $OfficeVersions | ForEach-Object {
        $version = $_
        $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\Security"
        ForceRegKey($key)
        Set-ItemProperty -Path $key -Name "EnableDEP" -Type DWORD -Value 0x0 -Force
    }
}


})


## Job: DisableDRMPropertyEncryption, C:\dev\VM_Setup\03_Office\DisableDRMPropertyEncryption.ps1
$jobs.Add("\03_Office\DisableDRMPropertyEncryption.ps1", {
$OfficeVersions | ForEach-Object {
    $key = "HKCU:\Software\Microsoft\Office\" + $_ + "\Common\Security"
    ForceRegKey($key)
    Set-ItemProperty -Path $key -Name "DRMEncryptProperty" -Type DWORD -Value 0x0 -Force
}

})


## Job: DisableFileBlock, C:\dev\VM_Setup\03_Office\DisableFileBlock.ps1
$jobs.Add("\03_Office\DisableFileBlock.ps1", {
@("Word", "Excel", "PowerPoint") | ForEach-Object {
    $app = $_
    $OfficeVersions | ForEach-Object {
        $version = $_
        
        ## Disable File Blocking by Version
        $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\Security"        
        ForceRegKey($key)
        Set-ItemProperty -Path $key -Name "FilesBeforeVersion" -Type DWORD -Value 0x0 -Force


        ## Disable File Blocking by Type

        if ($app -eq "PowerPoint") { 
            $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\Security\FileOpenBlock" 
        } else {
            #This isn't always correct (some versions of Office name it differently)
            $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\Security\FileBlock"
        }
        ForceRegKey($key)
        switch ($app) {
            "Word" {
                Set-ItemProperty -Path $key -Name "Word95Files" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "Word60Files" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "Word2Files" -Type DWORD -Value 0x0 -Force                
            }
            "Excel" {
                Set-ItemProperty -Path $key -Name "XL4Workbooks" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "XL4Worksheets" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "XL3Worksheets" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "XL2Worksheets" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "XL4Macros" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "XL3Macros" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "XL2Macros" -Type DWORD -Value 0x0 -Force
            }
            "PowerPoint" {
                Set-ItemProperty -Path $key -Name "FilesBeforePowerPoint97" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "BinaryFiles" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "HTMLFiles" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "GraphicFilters" -Type DWORD -Value 0x0 -Force
                Set-ItemProperty -Path $key -Name "Outlines" -Type DWORD -Value 0x0 -Force
            }
        }        
    }
}





})


## Job: DisableFileValidationReporting, C:\dev\VM_Setup\03_Office\DisableFileValidationReporting.ps1
$jobs.Add("\03_Office\DisableFileValidationReporting.ps1", {

$OfficeVersions | ForEach-Object {
    $key = "HKCU:\Software\Microsoft\Office\" + $_ + "\Common\Security\FileValidation"
    ForceRegKey($key)
    Set-ItemProperty -Path $key -Name DisableReporting -Type DWORD -Value 0x1 -Force
}

})


## Job: DisableFirstRun, C:\dev\VM_Setup\03_Office\DisableFirstRun.ps1
$jobs.Add("\03_Office\DisableFirstRun.ps1", {
$OfficeVersions | ForEach-Object {
    $version = $_
    $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\FirstRun"
    ForceRegKey($key)
    Set-ItemProperty -Path $key -Name "disablemovie" -Type DWORD -Value 0x1 -Force
    Set-ItemProperty -Path $key -Name "bootedrtm" -Type DWORD -Value 0x1 -Force
}
})


## Job: DisableHyperlinkWarning, C:\dev\VM_Setup\03_Office\DisableHyperlinkWarning.ps1
$jobs.Add("\03_Office\DisableHyperlinkWarning.ps1", {
$OfficeVersions | ForEach-Object {
    $key = "HKCU:\Software\Microsoft\Office\" + $_ + "\Common\Security"
    ForceRegKey($key)
    Set-ItemProperty -Path $key -Name "DisableHyperlinkWarning" -Type DWORD -Value 0x1 -Force
}

})


## Job: DisableProtectedView, C:\dev\VM_Setup\03_Office\DisableProtectedView.ps1
$jobs.Add("\03_Office\DisableProtectedView.ps1", {
@("Word", "Excel", "PowerPoint") | ForEach-Object {
    $app = $_
    $OfficeVersions | ForEach-Object {
        $version = $_
        $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\Security\ProtectedView"
        ForceRegKey($key)
        Set-ItemProperty -Path $key -Name "DisableInternetFilesInPV" -Type DWORD -Value 0x1 -Force
        Set-ItemProperty -Path $key -Name "DisableAttachementsInPV" -Type DWORD -Value 0x1 -Force
        Set-ItemProperty -Path $key -Name "DisableUnsafeLocationsInPV" -Type DWORD -Value 0x1 -Force
    }
}

})


## Job: DisableReliabilityUpdate, C:\dev\VM_Setup\03_Office\DisableReliabilityUpdate.ps1
$jobs.Add("\03_Office\DisableReliabilityUpdate.ps1", {

$OfficeVersions | ForEach-Object {
    $key = "HKCU:\Software\Microsoft\Office\" + $_ + "\Common"
    ForceRegKey($key)
    Set-ItemProperty -Path $key -Name "UpdateReliabilityData" -Type DWORD -Value 0x0 -Force
}

})


## Job: DisableVBAWarnings, C:\dev\VM_Setup\03_Office\DisableVBAWarnings.ps1
$jobs.Add("\03_Office\DisableVBAWarnings.ps1", {

@("Word", "Excel", "PowerPoint", "Publisher", "MS Project", "Visio") | ForEach-Object {
    $app = $_
    $OfficeVersions | ForEach-Object {
        $version = $_
        $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\Security"
        ForceRegKey($key)
        Set-ItemProperty -Path $key -Name "VBAWarnings" -Type DWORD -Value 0x1 -Force
    }
}

})


## Job: EnableAccessVBOM, C:\dev\VM_Setup\03_Office\EnableAccessVBOM.ps1
$jobs.Add("\03_Office\EnableAccessVBOM.ps1", {
@("Word", "Excel", "PowerPoint") | ForEach-Object {
    $app = $_
    $OfficeVersions | ForEach-Object {
        $version = $_
        $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\Security"
        ForceRegKey($key)
        Set-ItemProperty -Path $key -Name "AccessVBOM" -Type DWORD -Value 0x1 -Force
    }
}

})


## Job: EnableExcelDataConnections, C:\dev\VM_Setup\03_Office\EnableExcelDataConnections.ps1
$jobs.Add("\03_Office\EnableExcelDataConnections.ps1", {
$OfficeVersions | ForEach-Object {
    $key = "HKCU:\Software\Microsoft\Office\" + $_ + "\Excel\Security"
    ForceRegKey($key)
    Set-ItemProperty -Path $key -Name "DataConnectionWarnings" -Type DWORD -Value 0x0 -Force
}

})


## Job: EnableExcelLinkedWorkbooks, C:\dev\VM_Setup\03_Office\EnableExcelLinkedWorkbooks.ps1
$jobs.Add("\03_Office\EnableExcelLinkedWorkbooks.ps1", {
$OfficeVersions | ForEach-Object {
    $key = "HKCU:\Software\Microsoft\Office\" + $_ + "\Excel\Security"
    ForceRegKey($key)
    Set-ItemProperty -Path $key -Name "WorkbookLinkWarnings" -Type DWORD -Value 0x0 -Force
}

})


## Job: EnableFileValidationLogging, C:\dev\VM_Setup\03_Office\EnableFileValidationLogging.ps1
$jobs.Add("\03_Office\EnableFileValidationLogging.ps1", {
$OfficeVersions | ForEach-Object {
    $key = "HKCU:\Software\Microsoft\Office\" + $_ + "\Common"
    ForceRegKey($key)
    Set-ItemProperty -Path $key -Name EnableGKLogging -Type DWORD -Value 0x3 -Force
}
})


## Job: EnableFileValidationOnLoad, C:\dev\VM_Setup\03_Office\EnableFileValidationOnLoad.ps1
$jobs.Add("\03_Office\EnableFileValidationOnLoad.ps1", {
@("Word", "Excel", "PowerPoint") | ForEach-Object {
    $app = $_
    $OfficeVersions | ForEach-Object {
        $version = $_
        $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\Security"
        ForceRegKey($key)
        Set-ItemProperty -Path $key -Name EnableGKOnLoad -Type DWORD -Value 0x3 -Force
    }
}

})


## Job: EnableFileValidationOnSave, C:\dev\VM_Setup\03_Office\EnableFileValidationOnSave.ps1
$jobs.Add("\03_Office\EnableFileValidationOnSave.ps1", {
@("Word", "Excel", "PowerPoint") | ForEach-Object {
    $app = $_
    $OfficeVersions | ForEach-Object {
        $version = $_
        $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\Security"
        ForceRegKey($key)
        Set-ItemProperty -Path $key -Name EnableGKOnSave -Type DWORD -Value 0x3 -Force
    }
}

})


## Job: EnableMacros, C:\dev\VM_Setup\03_Office\EnableMacros.ps1
$jobs.Add("\03_Office\EnableMacros.ps1", {
$key = "HKCU:\Software\Policies\Microsoft\Office\Common\Security"
ForceRegKey($key)
Set-ItemProperty -Path $key -Name "automationsecurity" -value 1 -Force
})


## Job: EnableVBA, C:\dev\VM_Setup\03_Office\EnableVBA.ps1
$jobs.Add("\03_Office\EnableVBA.ps1", {


 $OfficeVersions | ForEach-Object {
    $version = $_
    $key = "HKCU:\Software\Microsoft\Office\" + $version + "\Common"
    ForceRegKey($key)
    Set-ItemProperty -Path $key -Name "vbaoff" -Type DWORD -Value 0 -Force
}

})


## Job: FakeOfficeMRU, C:\dev\VM_Setup\03_Office\FakeOfficeMRU.ps1
$jobs.Add("\03_Office\FakeOfficeMRU.ps1", {

$apps = @("Word", "Excel", "PowerPoint")

$baseFolder = Join-Path $home "Documents"

function RandomId {
    return [String]::Join('',(1..15 | % {"0123456789ABCDEF".ToCharArray() | Get-Random}))
}

function RandomFileName {
    return [String]::Join('',(1..20 | % {"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890".ToCharArray() | Get-Random})) + ".bin"
}


$OfficeVersions| % {
    $v = $_
    $apps | % { 
        $a = $_
        $key_File = "HKCU:\Software\Microsoft\Office\" + $v + "\" + $a + "\File MRU"
        $key_Place = "HKCU:\Software\Microsoft\Office\" + $v + "\" + $a + "\Place MRU"

        1..(Get-Random -Minimum 15 -Maximum 30)| % {
            $i = $_
            $id = RandomId
            $filename = RandomFileName
            $val = "[F00000000][T0" + $id + "][O00000000]*" + $baseFolder + "\" + $filename
            New-ItemProperty $key_File -Name ("Item " + $i) -Value $val -PropertyType String
        }
    
        1..(Get-Random -Minimum 5 -Maximum 10)| % {
            $i = $_
            $id = RandomId
            $val = "[F00000000][T0" + $id + "][O00000000]*" + $baseFolder + "\"
            New-ItemProperty $key_Place -Name ("Item " + $i) -Value $val -PropertyType String
        }
    }
}



})


## Job: SetSecurityLevel, C:\dev\VM_Setup\03_Office\SetSecurityLevel.ps1
$jobs.Add("\03_Office\SetSecurityLevel.ps1", {

@("Word", "Excel", "PowerPoint", "Publisher", "MS Project", "Visio") | ForEach-Object {
    $app = $_
    $OfficeVersions | ForEach-Object {
        $version = $_
        $key = "HKCU:\Software\Microsoft\Office\" + $version + "\" + $app + "\Security"
        ForceRegKey($key)
        Set-ItemProperty -Path $key -Name "Level" -Type DWORD -Value 0x0 -Force
    }
}

})

#Process All Jobs
Write-Progress -Activity "Processing Jobs" -Status "Starting..."
$i = 0
$jobs.Keys | % {
    $key = $_
    $i++
    Write-Progress -Activity "Processing Jobs" -Status $key -PercentComplete ($i / $jobs.Count * 100)
    Invoke-Command -ScriptBlock $jobs[$key] -ErrorAction Stop
}
Write-Progress -Activity "Processing Jobs" -Completed


