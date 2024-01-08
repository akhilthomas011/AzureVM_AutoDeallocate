function Get-UserSession {
    [cmdletbinding()]
    Param(
        [switch]$parseIdleTime,

        [validaterange(0, 120)]$timeout = 60
    )             
    
    $computer = "localhost"
        
    #build temp file to store results.  Loop until this works
    Do {
        $tempFile = [System.IO.Path]::GetTempFileName()
        start-sleep -Milliseconds 300
    }
    Until(test-path $tempfile)

    $startTime = Get-Date
    $p = Start-Process -FilePath C:\windows\system32\cmd.exe -ArgumentList "/c query user /server:$computer > $tempfile" -WindowStyle hidden -passthru

    $stopprocessing = $false
    do {
                    
        #check if process has exited
        $hasExited = $p.HasExited
                
        #check if there is still a record of the process
        Try { $proc = get-process -id $p.id -ErrorAction stop }
        Catch { $proc = $null }

        #sleep a bit
        start-sleep -seconds .5

        #check if we have timed out, unless the process has exited
        if ( ( (Get-Date) - $startTime ).totalseconds -gt $timeout -and -not $hasExited -and $proc) {
            $p.kill()
            $stopprocessing = $true
            #remove-item $tempfile -force
            Write-Error "$computer`: Query.exe took longer than $timeout seconds to execute"
        }
    }
    until($hasexited -or $stopProcessing -or -not $proc)
    if ($stopprocessing) { Continue }

    #if we are still processing, read the output!
    $sessions = get-content $tempfile
        
    #handle no results
    if ($sessions) {

        1..($sessions.count - 1) | % {
            
            #Start to build the custom object
            $temp = "" | Select ComputerName, Username, SessionName, Id, State, IdleTime, LogonTime
            $temp.ComputerName = $computer

            #The output of query.exe is dynamic. 
            #strings should be 82 chars by default, but could reach higher depending on idle time.
            #we use arrays to handle the latter.

            if ($sessions[$_].length -gt 5) {
                #if the length is normal, parse substrings
                if ($sessions[$_].length -le 82) {
                           
                    $temp.Username = $sessions[$_].Substring(1, 22).trim()
                    $temp.SessionName = $sessions[$_].Substring(23, 19).trim()
                    $temp.Id = $sessions[$_].Substring(42, 4).trim()
                    $temp.State = $sessions[$_].Substring(46, 8).trim()
                    $temp.IdleTime = $sessions[$_].Substring(54, 11).trim()
                    $logonTimeLength = $sessions[$_].length - 65
                    try {
                        $temp.LogonTime = get-date $sessions[$_].Substring(65, $logonTimeLength).trim()
                    }
                    catch {
                        $temp.LogonTime = $sessions[$_].Substring(65, $logonTimeLength).trim() | out-null
                    }

                }
                #Otherwise, create array and parse
                else {                                       
                    $array = $sessions[$_] -replace "\s+", " " -split " "
                    $temp.Username = $array[1]
                
                    #in some cases the array will be missing the session name.  array indices change
                    if ($array.count -lt 9) {
                        $temp.SessionName = ""
                        $temp.Id = $array[2]
                        $temp.State = $array[3]
                        $temp.IdleTime = $array[4]
                        $temp.LogonTime = get-date $($array[5] + " " + $array[6] + " " + $array[7])
                    }
                    else {
                        $temp.SessionName = $array[2]
                        $temp.Id = $array[3]
                        $temp.State = $array[4]
                        $temp.IdleTime = $array[5]
                        $temp.LogonTime = get-date $($array[6] + " " + $array[7] + " " + $array[8])
                    }
                }

                #if specified, parse idle time to timespan
                if ($parseIdleTime) {
                    $string = $temp.idletime
                
                    #quick function to handle minutes or hours:minutes
                    function convert-shortIdle {
                        param($string)
                        if ($string -match "\:") {
                            [timespan]$string
                        }
                        else {
                            New-TimeSpan -minutes $string
                        }
                    }
                
                    #to the left of + is days
                    if ($string -match "\+") {
                        $days = new-timespan -days ($string -split "\+")[0]
                        $hourMin = convert-shortIdle ($string -split "\+")[1]
                        $temp.idletime = $days + $hourMin
                    }
                    #. means less than a minute
                    elseif ($string -like "." -or $string -like "none") {
                        $temp.idletime = [timespan]"0:00"
                    }
                    #hours and minutes
                    else {
                        $temp.idletime = convert-shortIdle $string
                    }
                }
                
                #Output the result
                $temp
            }
        }
    }            
    else { Write-warning "$computer`: No sessions found" }
}