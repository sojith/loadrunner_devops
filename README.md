# loadrunner_devops

These 3 powershell scripts will help integrate your Loadrunner Enterprise Test execution into the wider DEVOPS process

Booked.ps1 will pick the load tests from planned.xml and book these load tests. This script will first run a smoke test on all your scripts (Shakedown tests). If the scripts pass then it will update your MS Team channel, and it will book your load test

Running.ps1 will update your MS Team channel soon as your load test begins to run

Completed.ps1 will 1) update your MS Team channel with the smoke test results 2)  If the smoke test fails then it will delete the corresponding load test 3) it will publish the laod test results

So all that is required is for these scripts to run in the background, and get your release process the planned.xml

This is how to fill the planned.xml
1) Provide a test name \<TestName>QuoteSMEAutomatonTEST\</TestName>
2)  Provide the Load test instance ID - \<LoadTestInstanceID>548\</LoadTestInstanceID>. 
3)  Provide the Shakedown test's Load test instance ID - \<ShakedownInstanceID>568\</ShakedownInstanceID>
4)  Provide the start date of the shakedown test - \<ShakeDownStartTime>2023-06-02T05:41:00\</ShakeDownStartTime>
5)  Leave this tag empty - \<LoadTestStartTime>\</LoadTestStartTime>
6)  Provide duration of the Shakedown test - \<ShakeDownDurationInMinutes>30\</ShakeDownDurationInMinutes>
7)  Provide duration of the Load test - \<LoadTestDurationInMinutes>30\</LoadTestDurationInMinutes>
8)  Provide the LRE project name - \<MicrofocusProjectName>JAVA\</MicrofocusProjectName>
9)  Update this tag to booked - \<LoadTestStatus>Booked\</LoadTestStatus>
10)  Update this tag to Booked - \<ShakeDownStatus>Booked\</ShakeDownStatus>
