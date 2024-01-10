[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location $PSScriptRoot
$ErrorActionPreference = "Stop"

$TaskName = "Auto_Shutdown_Scheduler"
$argument = '-ExecutionPolicy Bypass -File "' + $PSScriptRoot + '\SystemShutdownInitiator.ps1"'

#config xml for task scheduler
$taskxml = [xml]'<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <CalendarTrigger>
      <Repetition>
        <Interval>PT1M</Interval>
        <Duration>P1D</Duration>
        <StopAtDurationEnd>true</StopAtDurationEnd>
      </Repetition>
      <StartBoundary>2019-08-18T17:15:46</StartBoundary>
      <ExecutionTimeLimit>P3D</ExecutionTimeLimit>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell</Command>
      <Arguments>-File "C:\session.ps1"</Arguments>
    </Exec>
  </Actions>
</Task>'

#Create the scheduled task
try {
  Register-ScheduledTask -Xml $taskxml.InnerXml -TaskName $TaskName -User "NT AUTHORITY\SYSTEM"
  $Action = New-ScheduledTaskAction -Execute "powershell" -Argument $argument -WorkingDirectory "$PSScriptRoot"
  Set-ScheduledTask -TaskName $TaskName -Action $Action -User "NT AUTHORITY\SYSTEM"
} 
catch {
  Write-Host "Couldn't register the Scheduled Task"
  exit 1
}

