$ms_team_address = "<enter ms team incoming webhook link>"
$standard_storage = "M:\AutomationZip"                                              # Storage on you AVC where the outputs are saved

#Function to send Message in Ms Team
function Send-Message ([string]$Body){
    #Send-MailMessage -From $from_email_address -To $ms_team_address -Subject "$($load_test_booking_name) Load Test" -BodyAsHtml $Body  -SmtpServer $smtp_server
    Invoke-WebRequest -Method POST -ContentType "application/json" -Uri $ms_team_address -Body "{'text': '$($Body)'}"

}


function Get-Result ([string]$run_id, [string]$microfocus_project_name, [string] $test_name, [string] $start_time, [string] $end_time, [string] $timeslot_ID, [string] $run_by){
    ##Delete the standard Result storage file
    try{
        Remove-Item -Recurse -Force $standard_storage
    }
    catch{
        #Path does not exist
    }

    mkdir $standard_storage

    $auth_response = Invoke-WebRequest -Method GET -ContentType “application/json” -Uri “http://pm823172/LoadTest/rest/authentication-point/authenticate” -Headers @{"Authorization"="Basic c29qaXRoX3M6V2VsY29tZTEyMw=="} -SessionVariable session3

    ## Download Results - provide Domain, Project/ Run ID, Result ID

    #GetResult Id of HighLevelReport_#.xlsx file
    $fetch_result_names_reponse  = Invoke-WebRequest -Method GET -ContentType "application/xml" -Uri "http://pm823172/LoadTest/rest/domains/DEFAULT/projects/$($microfocus_project_name)/Runs/$($run_id)/Results" -WebSession $session3
    [xml]$result_name = $fetch_result_names_reponse.Content
    for($i=0;$i -lt  $result_name.RunResults.RunResult.Length; $i++){
        if ($result_name.RunResults.RunResult[$i].Name.Contains("HighLevelReport")){
                $high_level_report_id = $result_name.RunResults.RunResult[$i].ID
            }
    }

    echo $high_level_report_id


    $high_level_report_filepath = "$($standard_storage)\Run$($run_id)_HighLevelReportt$($high_level_report_id).xls" 


    $download_result = Invoke-WebRequest -Method GET -ContentType "application/json" -Uri "http://pm823172/LoadTest/rest/domains/DEFAULT/projects/$($microfocus_project_name)/Runs/$($run_id)/Results/$($high_level_report_id)/data" -WebSession $session3 -OutFile $high_level_report_filepath
    Send-MailMessage -from "AutomatedLoadTest <do-not-reply-loadtest@allianz.com>" -to "<email address of the ms team channel>" -subject "$($test_name) - Load Test status" -body "Name of the test : $($test_name) `nRun By : $($run_by) `nStart Time : $($start_time) `nEnd Time : $($end_time) `nRun ID : $($run_id) `nTimeslot ID : $($timeslot_ID)" -Attachment $high_level_report_filepath -smtpServer tmu.mail.allianz
       
    $logout_response = Invoke-WebRequest -Method GET -ContentType "application/json" -Uri "http://pm823172/LoadTest/rest/authentication-point/Logout" -WebSession $session3

}

## Script scans the runs from the last 15 mins and then publishes them on MS Team that they are running
cls



## Login 
## Run API to get the runs in the past 30 mins

#Login
$admin_auth_response = Invoke-WebRequest -Method GET -ContentType “application/json” -Uri “http://pm823172/Admin/rest/authentication-point/authenticate” -Headers @{"Authorization"="Basic c29qaXRoX3M6V2VsY29tZTEyMw=="} -SessionVariable session2

$current_time = Get-Date
$start_time = $current_time.ToUniversalTime().AddMinutes(-1440).ToString("yyyy-MM-dd") + "%20" + $current_time.ToUniversalTime().AddMinutes(-1440).ToString("hh:mm:ss")
echo $start_time

#$get_runs_response = Invoke-WebRequest -Method GET -ContentType “application/xml” -Uri “http://pm823172/Admin/rest/v1/runs?query={StartDate[>'2023-06-06%2010:02:00']}” -WebSession $session2
$get_runs_response = Invoke-WebRequest -Method GET -ContentType “application/xml” -Uri “http://pm823172/Admin/rest/v1/runs?query={StartDate[>'$start_time']}” -WebSession $session2
$get_runs = [xml]$get_runs_response.Content

if ($get_runs.LabRuns.ChildNodes.Count -gt 1){

    for ($i=0; $i -lt $get_runs.LabRuns.ChildNodes.Count; $i++){
        echo $i

        echo $get_runs.LabRuns.LabRun[$i]

        if ( ( $get_runs.LabRuns.LabRun[$i].TestName.Contains("Shakedown") -or $get_runs.LabRuns.LabRun[$i].TestName.Contains("shakedown") ) -and ( $get_runs.LabRuns.LabRun[$i].RunState -eq "Finished" ) ) {
            echo "This is a shakedown test"
        }
        else{
            Get-Result $get_runs.LabRuns.LabRun[$i].RunID.ToString() $get_runs.LabRuns.LabRun[$i].Project.ToString() $get_runs.LabRuns.LabRun[$i].TestName.ToString() $get_runs.LabRuns.LabRun[$i].StartDate.ToString() $get_runs.LabRuns.LabRun[$i].EndDate.ToString() $get_runs.LabRuns.LabRun[$i].TimeslotID.ToString() $get_runs.LabRuns.LabRun[$i].UserName.ToString()

  
        }
    }
}

if ($get_runs.LabRuns.ChildNodes.Count -eq 1){
    echo $get_runs.LabRuns.LabRun  
        if ( ( $get_runs.LabRuns.LabRun.TestName.Contains("Shakedown") -or $get_runs.LabRuns.LabRun.TestName.Contains("shakedown") ) -and ( $get_runs.LabRuns.LabRun.RunState -eq "Finished" ) ) {
            echo "This is a shakedown test"
        }
        else{
            Get-Result $get_runs.LabRuns.LabRun.RunID.ToString() $get_runs.LabRuns.LabRun.Project.ToString() $get_runs.LabRuns.LabRun.TestName.ToString() $get_runs.LabRuns.LabRun.StartDate.ToString() $get_runs.LabRuns.LabRun.EndDate.ToString() $get_runs.LabRuns.LabRun.TimeslotID.ToString() $get_runs.LabRuns.LabRun.UserName.ToString()
        }
}



$admin_logout_response = Invoke-WebRequest -Method GET -ContentType "application/json" -Uri "http://pm823172/Admin/rest/authentication-point/Logout" -WebSession $session2


