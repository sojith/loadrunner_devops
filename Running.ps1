$ms_team_address = "<enter ms team incoming webhook link>"

    #Function to send Message in Ms Team
    function Send-Message ([string]$Body){
        #Send-MailMessage -From $from_email_address -To $ms_team_address -Subject "$($load_test_booking_name) Load Test" -BodyAsHtml $Body  -SmtpServer $smtp_server
        Invoke-WebRequest -Method POST -ContentType "application/json" -Uri $ms_team_address -Body "{'text': '$($Body)'}"

    }


## Script scans the runs from the last 15 mins and then publishes them on MS Team that they are running
cls
## Login 
## Run API to get the runs in the past 30 mins

#Login
$auth_response = Invoke-WebRequest -Method GET -ContentType “application/json” -Uri “http://pm823172/Admin/rest/authentication-point/authenticate” -Headers @{"Authorization"="Basic c29qaXRoX3M6V2VsY29tZTEyMw=="} -SessionVariable session2

$current_time = Get-Date
$start_time = $current_time.ToUniversalTime().AddMinutes(-1440).ToString("yyyy-MM-dd") + "%20" + $current_time.ToUniversalTime().AddMinutes(-1440).ToString("hh:mm:ss")
echo $start_time

#$get_runs_response = Invoke-WebRequest -Method GET -ContentType “application/xml” -Uri “http://pm823172/Admin/rest/v1/runs?query={StartDate[>'2023-06-06%2010:02:00']}” -WebSession $session2
$get_runs_response = Invoke-WebRequest -Method GET -ContentType “application/xml” -Uri “http://pm823172/Admin/rest/v1/runs?query={StartDate[>'$start_time']}” -WebSession $session2
$get_runs = [xml]$get_runs_response.Content

if ($get_runs.LabRuns.ChildNodes.Count -gt 1){

    for ($i=0; $i -lt $get_runs.LabRuns.ChildNodes.Count; $i++){
        $ms_team_msg = "<table bordercolor=`"black`" border= `"2`"><tbody ><tr><td>Test Name</td><td>$($get_runs.LabRuns.LabRun[$i].TestName.ToString())</td></tr><tr><td>Start Time</td><td>$($get_runs.LabRuns.LabRun[$i].StartDate.ToString())</td></tr><tr><td>End Time</td><td>$($get_runs.LabRuns.LabRun[$i].EndDate.ToString())</td></tr><tr><td>Run ID</td><td>$($get_runs.LabRuns.LabRun[$i].RunID.ToString())</td></tr><tr><td>Timeslot IF</td><td>$($get_runs.LabRuns.LabRun[$i].TimeslotID.ToString())</td></tr><tr><td>Run By</td><td>$($get_runs.LabRuns.LabRun[$i].UserName.ToString())</td></tr><tr><td>Status</td><td>$($get_runs.LabRuns.LabRun[$i].RunState.ToString())</td></tr><tr><td>Controllers</td><td>$($get_runs.LabRuns.LabRun[$i].ControllerName.ToString())</td></tr><tr><td>Load Generators</td><td>$($get_runs.LabRuns.LabRun[$i].LoadGenerators.ToString())</td></tr></tbody></table>"
        Send-Message($ms_team_msg)
    }
}

if ($get_runs.LabRuns.ChildNodes.Count -eq 1){
    $ms_team_msg = "<table bordercolor=`"black`" border= `"2`"><tbody ><tr><td>Test Name</td><td>$($get_runs.LabRuns.LabRun.TestName.ToString())</td></tr><tr><td>Start Time</td><td>$($get_runs.LabRuns.LabRun.StartDate.ToString())</td></tr><tr><td>End Time</td><td>$($get_runs.LabRuns.LabRun.EndDate.ToString())</td></tr><tr><td>Run ID</td><td>$($get_runs.LabRuns.LabRun.RunID.ToString())</td></tr><tr><td>Timeslot IF</td><td>$($get_runs.LabRuns.LabRun.TimeslotID.ToString())</td></tr><tr><td>Run By</td><td>$($get_runs.LabRuns.LabRun.UserName.ToString())</td></tr><tr><td>Status</td><td>$($get_runs.LabRuns.LabRun.RunState.ToString())</td></tr><tr><td>Controllers</td><td>$($get_runs.LabRuns.LabRun.ControllerName.ToString())</td></tr><tr><td>Load Generators</td><td>$($get_runs.LabRuns.LabRun.LoadGenerators.ToString())</td></tr></tbody></table>"
    Send-Message($ms_team_msg)    
}

## Publish result in MS Team 

$logout_response = Invoke-WebRequest -Method GET -ContentType "application/json" -Uri "http://pm823172/Admin/rest/authentication-point/Logout" -WebSession $session2


