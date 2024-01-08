cd $PSScriptRoot
$ErrorActionPreference = "Stop"

#variables
$tags = @{}
$tagName_MinimumSessionIdleTime = 'autodeallocate_minSessionIdleTime'
$tagName_MinimumStandbyTime = 'autodeallocate_minStandbyTime'
$tagName_SessionStatusCheckInterval = 'autodeallocate_statusCheckInterval'
$tags[$tagName_MinimumSessionIdleTime] = '30'
$tags[$tagName_MinimumStandbyTime] = '30'
$tags[$tagName_SessionStatusCheckInterval] = 'PT10M'

$scheduledTaskName = "Auto_Shutdown_Scheduler"

$logFile = ".\logs\log.txt"
$lastrunTranscript = ".\logs\lastrun_transcript.txt"

Start-Transcript -Path $lastrunTranscript -Force

#function for logging
function log_ () {
    $maxLogSize = 5
    if (!(Test-Path $logFile)) {
        New-Item -Path $logFile -ItemType file -Force
    }    
    if ($(Get-Item $logFile).Length / 10KB -gt $maxLogSize){
        Remove-Item $logFile -Force
    }
    Add-Content $logFile "$(Get-Date): $args"
}


log_ "###### Begin ##########"

#Import required modules
if (Get-InstalledPSResource Az.Compute -ErrorAction SilentlyContinue) {
    Write-Host "Module 'Az.Compute' exists"
    Import-Module Az.Compute
} 
else {
    Write-Host "Module 'Az.Compute' does not exist"
    Install-PSResource Az.Compute -TrustRepository
    Import-Module Az.Compute
}

#Connect to Azure using MSI
try {
    Connect-AzAccount -Identity -Force
    log_ "Connected to Azure using MSI"
} 
catch {
    log_ "Couldn't connect to Azure using MSI. Stopping execution"
    $_.Exception | Out-File $logFile -Append
    exit 1
}

#Get VM tags
$vm = (Invoke-WebRequest -Uri 'http://169.254.169.254/metadata/instance/compute?api-version=2018-02-01' -usebasicparsing -Method GET -Headers @{Metadata = "true" }).Content | ConvertFrom-Json
$($vm.tags).Split(';') | foreach {
    if($($_.Split(':')[0]) -imatch "$tagName_MinimumSessionIdleTime") {
        $tags[$tagName_MinimumSessionIdleTime]= $_.Split(':')[1]
    }   
    if($($_.Split(':')[0]) -imatch "$tagName_MinimumStandbyTime") {
        $tags[$tagName_MinimumStandbyTime]= $_.Split(':')[1]
    }
    if($($_.Split(':')[0]) -imatch "$tagName_SessionStatusCheckInterval") {
        $tags[$tagName_SessionStatusCheckInterval]= $_.Split(':')[1]
    }
}
log_ "VM: $($vm.name); RG: $($vm.resourceGroupName); SubscriptionID: $($vm.subscriptionId)"
log_ "Minimum Session Idle Time is: $($tags[$tagName_MinimumSessionIdleTime])"
log_ "Minimum StandBy Time is: $($tags[$tagName_MinimumStandbyTime])"
log_ "Status check interval is: $($tags[$tagName_SessionStatusCheckInterval])"

#Update Status Check Interval from VM tags
$Task = Get-ScheduledTask -TaskName $scheduledTaskName
$Task.Triggers[0].Repetition.Interval = $tags[$tagName_SessionStatusCheckInterval]
$Task | Set-ScheduledTask

. .\Get-UserSessions.ps1
log_  "Session Finder script executed"
$activeSessions = Get-UserSession | ? {($_.State -eq "Active")}  #Get all Active sessions
$recentSessions = Get-UserSession -parseIdleTime | ? {($_.idletime -lt $(New-TimeSpan -minutes $tags[$tagName_MinimumSessionIdleTime])) }   #Get all recent sessions
$startTime = (Get-CimInstance -ClassName win32_operatingsystem | select lastbootuptime).lastbootuptime  #Get the time of last boot
$Uptime = (NEW-TIMESPAN -Start $startTime -End $(Get-Date)).TotalMinutes                                   #Get time since last boot

log_ "Active sesssions are : $activeSessions"
log_ "Recent sessions are : $recentSessions"
log_ "Time since last reboot is : $Uptime"

#Confirm there are no active or new sessions and time since last boot is above threshold and stop the VM
if (![boolean]$recentSessions -and ![boolean]$activeSessions -and ($Uptime -ge $tags[$tagName_MinimumStandbyTime])) {   
    log_ "Recent Sessions: '$([boolean]$recentSessions)' ; Active Sessions: '$([boolean]$activeSessions)' ; In StandBy: $($Uptime -ge $tags[$tagName_MinimumStandbyTime]) ### Deallocate VM? : FALSE"
    log_ "Preferred status of the VM : DEALLOCATED"
    log_ "VM Deallocation: Initiated"
    try {
        Stop-AzVM -ResourceGroupName $($vm.resourceGroupName) -Name $($vm.name) -Force
        log_ "VM Deallocation: SUCCESS"
    } 
    catch {
        log_ "VM Deallocation: FAILED"
        $_.Exception | Out-File $logFile -Append
        Break
    }         
}else {
    log_ "Recent Sessions: '$([boolean]$recentSessions)' ; Active Sessions: '$([boolean]$activeSessions)' ; In StandBy: $($Uptime -ge $tags[$tagName_MinimumStandbyTime]) ### Deallocate VM? : FALSE"
    log_ "Preferred status of the VM : RUNNING"
}