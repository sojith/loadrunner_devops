# loadrunner_devops

These 3 powershell scripts will help integrate your Loadrunner Enterprise Test execution into the wider DEVOPS process

Get your Release process to update the planned.xml

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
