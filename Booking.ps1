## Function Declarations
$ms_team_address = "enter ms team incoming webhook link"

    #Function to send Message in Ms Team
    function Send-Message ([string]$Body){
        #Send-MailMessage -From $from_email_address -To $ms_team_address -Subject "$($load_test_booking_name) Load Test" -BodyAsHtml $Body  -SmtpServer $smtp_server
        Invoke-WebRequest -Method POST -ContentType "application/json" -Uri $ms_team_address -Body "{'text': '$($Body)'}"

    }

    #Function to Book Timeslot
              
     function Book-Timeslot($test_start_time, $test_duration, $test_name, $test_InstanceId, $microfocus_project_name) {


        # Post Data required to book a timeslot
        $xml_book_timeslot = "<Timeslot xmlns='http://www.hp.com/PC/REST/API'>
                                            <StartTime>$($test_start_time)Z</StartTime>
                                            <DurationInMinutes>$($test_duration)</DurationInMinutes>
                                            <Description>Booking Timeslot via automated script</Description>
                                            <Name>$($test_name)</Name>  
                                            <LoadTestInstanceID>$($test_InstanceId)</LoadTestInstanceID>
                                            <IsTestAutostart>true</IsTestAutostart>
                                            <PostRunAction>CollateAnalyze</PostRunAction>
                                        </Timeslot>"


        try{
            $timeslot_booking_response = Invoke-WebRequest -Method POST -ContentType "application/xml" -Uri "http://pm823172/LoadTest/rest/domains/DEFAULT/projects/$microfocus_project_name/timeslots" -WebSession $session1 -Body $xml_book_timeslot
            return $timeslot_booking_response.Content
        }
        catch{
            $test_start_time1 = [datetime]$test_start_time
            $test_start_time1 = $test_start_time1.AddMinutes(15)
            Book-Timeslot $test_start_time1.ToString("yyyy-MM-ddTHH:mm:ss") $test_duration $test_name $test_InstanceId $microfocus_project_name   
        }




    }





while(1){
    # 1. Read planned.xml, running.xml
    $planned_test_file = "X:\Automation\LRESchedule\Planned\Planned.xml"
    $planned_test_xml = [xml](Get-Content -Raw -Path $planned_test_file)

    $running_test_file = "X:\Automation\LRESchedule\Running\Running.xml"
    $running_test_xml = [xml](Get-Content -Raw -Path $running_test_file)

    # 2. From the list of Test Details, select the test with the earliest start time

    #Search Start Time. If it is less than current time then ignore, else proceed. if it is less than current time + 5 then proceed
    $current_time = Get-Date
    $check_time = $current_time.ToUniversalTime().AddHours(1000)
    $first_test_index = "1000" #index of the first test. defaulted to a value 1000 not expected

    for ($i=1; $i -lt $planned_test_xml.TESTS.TestDetails.Count; $i++){
        $current_time = Get-Date
        $test_time = [datetime]$planned_test_xml.TESTS.TestDetails[$i].ShakeDownStartTime
        if ($test_time -ge $current_time.ToUniversalTime())
        {
            if ($test_time -le $check_time){        
                $first_test_index = $i
                $check_time = $test_time
            }
        }
    }


    #echo $first_test_index
    #echo $planned_test_xml.TESTS.TestDetails[$first_test_index].ShakeDownStartTime

    if ($first_test_index -ne "1000"){
        # 3. Login
            $auth_response = Invoke-WebRequest -Method GET -ContentType “application/json” -Uri “http://pm823172/LoadTest/rest/authentication-point/authenticate” -Headers @{"Authorization"="Basic c29qaXRoX3M6V2VsY29tZTEyMw=="} -SessionVariable session1 
    
        # 4. Book the slot for the test if it is within 5 mins of current time]

            # 4a - Check if the first test to be booked is within the next 5 mins
            $current_time = Get-Date

            while ([datetime]$planned_test_xml.TESTS.TestDetails[$first_test_index].ShakeDownStartTime -ge $current_time.AddMinutes(5).ToUniversalTime() )
            {        
                echo "Test is after 5 mins"
                sleep(60)
                $current_time = Get-Date
        
            }
                echo "Test is within 5 mins"
        
            # 4.b. Book Shakedown Test - Call Function Booking with the essential params (Start Time.....)
    
            $shake_test_name = $planned_test_xml.TESTS.TestDetails[$first_test_index].TestName
            $shake_test_name = $("$shake_test_name Shakedown")
            [xml]$book_timeslot_response = Book-Timeslot $planned_test_xml.TESTS.TestDetails[$first_test_index].ShakeDownStartTime $planned_test_xml.TESTS.TestDetails[$first_test_index].ShakeDownDurationInMinutes $shake_test_name $planned_test_xml.TESTS.TestDetails[$first_test_index].ShakedownInstanceID $planned_test_xml.TESTS.TestDetails[$first_test_index].MicrofocusProjectName
            $mail_msg_body = "<p><b>Booked</b></p><p>Test Name : $($book_timeslot_response.Timeslot.Name.ToString())</p><p>Start Time : $($book_timeslot_response.Timeslot.StartTime.ToString())</p><p>End Time : $($book_timeslot_response.Timeslot.EndTime.ToString())</p><p>Time Slot ID : $($book_timeslot_response.Timeslot.ID.ToString())</p><p>Created By : $($book_timeslot_response.Timeslot.CreatedBy.ToString())</p>"
                
            Send-Message($mail_msg_body)

            if ($book_timeslot_response -ne $null){
                # 4.c  update planned.xml with new start time (under the tag StartTime) and TimeslotID of the shakedown test.
                $planned_test_xml.TESTS.TestDetails[$first_test_index].ShakeDownStartTime = $book_timeslot_response.Timeslot.StartTime.Replace("+00","")
                $planned_test_xml.TESTS.TestDetails[$first_test_index].ShakeDownTimeslotID = $book_timeslot_response.Timeslot.ID

                $planned_test_xml.Save($planned_test_file)


                # 4.d Book Load Test - Call Funtion Booking with essential parameters (End Time of the Shakedown test + 10 mins)
                $load_test_start_string =  $book_timeslot_response.Timeslot.EndTime.Replace("+00","")
                $load_test_start_time = [datetime]$load_test_start_string
                $load_test_start_time = $load_test_start_time.AddMinutes(10)

                $load_test_name = $planned_test_xml.TESTS.TestDetails[$first_test_index].TestName
                $load_test_name = $("$load_test_name Load Test")
                [xml]$book_load_timeslot_response = Book-Timeslot $load_test_start_time.ToString("yyyy-MM-ddTHH:mm:ss") $planned_test_xml.TESTS.TestDetails[$first_test_index].LoadTestDurationInMinutes $load_test_name  $planned_test_xml.TESTS.TestDetails[$first_test_index].LoadTestInstanceID $planned_test_xml.TESTS.TestDetails[$first_test_index].MicrofocusProjectName

                $mail_msg_body = "<p><b>Booked</b></p><p>Test Name : $($book_load_timeslot_response.Timeslot.Name.ToString())</p><p>Start Time : $($book_load_timeslot_response.Timeslot.StartTime.ToString())</p><p>End Time : $($book_load_timeslot_response.Timeslot.EndTime.ToString())</p><p>Time Slot ID : $($book_load_timeslot_response.Timeslot.ID.ToString())</p><p>Created By : $($book_load_timeslot_response.Timeslot.CreatedBy.ToString())</p>"                
                Send-Message($mail_msg_body)

                # 4.e Post Booking , the end time of the load test is returned. 
                # 4.e.i Check if the end time of the load test is on the same day
                $get_load_date =  [datetime]$book_load_timeslot_response.Timeslot.StartTime.Replace("+00","") ## Aparna was right. Trim is required here
                $get_shakedown_date =  [datetime]$book_timeslot_response.Timeslot.StartTime.Replace("+00","")

                # 4.e.ii  If the End time is the same day then update planned.xml with timeslot ID and start time of the load test. Remove the entire booking from planned.xml and move it running.xml
                if ($get_load_date.Day -eq $get_shakedown_date.Day){    

                    ##If the End time is the same day then update planned.xml with timeslot ID and start time of the load test.
                    $planned_test_xml.TESTS.TestDetails[$first_test_index].LoadTestStartTime = $book_load_timeslot_response.Timeslot.StartTime.Replace("+00","")
                    $planned_test_xml.TESTS.TestDetails[$first_test_index].LoadTestTimeslotID = $book_load_timeslot_response.Timeslot.ID
                    $planned_test_xml.TESTS.TestDetails[$first_test_index].ShakeDownStatus = "Booked"
                    $planned_test_xml.TESTS.TestDetails[$first_test_index].LoadTestStatus = "Booked"
                    $planned_test_xml.Save($planned_test_file)
        
                    ##Remove the entire booking from planned.xml and move it running.xml
                    $node = $planned_test_xml.SelectSingleNode("//TESTS/TestDetails[$first_test_index+1]")
                    $newNode = $running_test_xml.ImportNode($node, $true)
                    $running_test_xml.DocumentElement.AppendChild($newnode)
                    $running_test_xml.Save( $running_test_file )

                    $planned_test_xml.DocumentElement.RemoveChild($node)
                    $planned_test_xml.Save( $planned_test_file )

                }
        
                # 4.e.iii If it is not on the same day then delete the load test and the shakdown test bookings. Update Planned.xml - shakedown test start time to next day (05:00 am UK time).
                if ($get_load_date.Day -gt $get_shakedown_date.Day){   
        

                    ##Update Planned.xml - shakedown test start time to next day (05:00 am UK time)
                    $shakedown_date_buffer = [datetime]$planned_test_xml.TESTS.TestDetails[$first_test_index].ShakeDownStartTime
                    $shakedown_date_buffer = $shakedown_date_buffer.AddDays(1)
                    $planned_test_xml.TESTS.TestDetails[$first_test_index].ShakeDownStartTime = $shakedown_date_buffer.ToString("yyyy-MM-ddT05:00:00")
                    $planned_test_xml.TESTS.TestDetails[$first_test_index].LoadTestStartTime = ""
                    $planned_test_xml.TESTS.TestDetails[$first_test_index].ShakeDownStatus = "Planned"
                    $planned_test_xml.TESTS.TestDetails[$first_test_index].LoadTestStatus = "Planned"
                    $planned_test_xml.Save( $planned_test_file )
       
                    ##If it is not on the same day then delete the load test and the shakdown test bookings
                    #Delete Shakedown Test
                    Invoke-WebRequest -Method DELETE -ContentType "application/xml" -Uri "http://sm823172/LoadTest/rest/domains/DEFAULT/projects/LAB_PROJECT/timeslots/$($book_timeslot_response.Timeslot.ID)" -WebSession $session1
                    #Delete Load Test
                    Invoke-WebRequest -Method DELETE -ContentType "application/xml" -Uri "http://sm823172/LoadTest/rest/domains/DEFAULT/projects/LAB_PROJECT/timeslots/$($book_load_timeslot_response.Timeslot.ID)" -WebSession $session1

                }   
            }
    

   

        #Log out
        $logout_response = Invoke-WebRequest -Method GET -ContentType "application/json" -Uri "http://pm823172/LoadTest/rest/authentication-point/logout" -WebSession $session1
    }
}
