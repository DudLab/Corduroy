#pragma rtGlobals=2	 // Use modern global access method.

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 	CORDUROY_DAQ_utilityplot
// 		Please see READ-ME for relevant notes and information
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Window UtilityPulsePanel() : Panel
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Get the variables necessary to customize panel
	variable left = root:DAQ:Classes:UtilityPlot:left
	variable top = root:DAQ:Classes:UtilityPlot:top
	variable right = root:DAQ:Classes:UtilityPlot:right
	variable bottom = root:DAQ:Classes:UtilityPlot:bottom

// Display function defines this string
	PauseUpdate; Silent 1 // building the window...
	NewPanel/W=(left,top,right,bottom)/K=1 as "UtilityPlot"
	DoWindow/C UtilityPlot
	SetDrawLayer UserBack

// Create the graph for test pulses and bridge balance pulses
//	Make/O/N=(1000) testPulse
//	testPulse = 0
//	testPulse[250,750] = -5 // in mV/V
//	SetScale x, 0, 0.05, "s", testPulse
//	Display /HOST=UtilityPlot /K=1 /W=(0.05,0.15,0.95,0.95) testPulse
//	ModifyGraph live=1

// Create the relevant panel items for monitoring seal resistance and bridge balance
SetDrawEnv fname="Verdana", fstyle=0, fsize=10, linefgc=(65278,55512,34438),textrgb=(65278,47802,17219)
GroupBox ControlGroup,pos={10,5},size={(right-left-20),(0.13*(bottom-top))},title="",fColor=(20000,40000,60000),fstyle=0,fsize=11,labelBack=(20000,40000,60000)
	PopupMenu UP_CG_Popup1,bodyWidth=100,font="Verdana",proc=UP_SwitchMode,pos={115,18},title="Mode:",value="Test Pulse;Bridge Balance", font="Verdana", fsize=10
	PopupMenu UP_CG_Popup2,bodyWidth=100,font="Verdana",proc=UP_SwitchChan,pos={115,43},title="Chan:",value="Channel_A;Channel_B;Channel_C;Channel_D", font="Verdana", fsize=10
	ValDisplay UP_CG_ValDisp1,pos={185,20},size={140,20},title="R_seal (1e6):",font="Verdana",fsize=10
	ValDisplay UP_CG_ValDisp1,limits={-Inf,Inf,0}, frame=2, value=root:DAQ:Classes:UtilityPlot:resistance
	ValDisplay UP_CG_ValDisp2,pos={185,45},size={140,20},title="Fit error (arb):",font="Verdana",fsize=10
	ValDisplay UP_CG_ValDisp2,limits={-Inf,Inf,0}, frame=2, value=root:DAQ:Classes:UtilityPlot:fiterr
	Button UP_CG_Butt1, pos={338,18},font="Verdana",size={40,40}, proc=CORD_ToggleTest, title="Start", help={"Press to start/stop test pulse"}
ResumeUpdate
EndMacro //UtilityPulsePanel

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_CreateTestPulsePanel()
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	DoWindow/F UtilityPlot
	if (V_Flag!=0)
		return 0
	endif
	string restoreDF = GetDataFolder(1)
	SetDataFolder root:
// Create globals that will need to be accessed by the panel
	NewDataFolder/O root:DAQ
	NewDataFolder/O root:DAQ:Classes
	NewDataFolder/O root:DAQ:Classes:UtilityPlot
// Create necessary variables for the panel, and initialize popup menu values
	SetDataFolder root:DAQ:Classes:UtilityPlot:
	variable/G testType = 1
	variable/G UtilG = 0
	variable/G root:DAQ:Classes:UtilityPlot:counter = 0
	string/G SwitchChan = "Channel_A"
	CORD_CreateUtilityCoords()
// Launch the panel
	DefaultFont/U "Verdana"
	DoWindow/K UtilityPlot
	Execute "UtilityPulsePanel()"
	ModifyPanel /W=UtilityPlot cbRGB = (20000,20000,20000) //set background color
// Restore initial data folder
	SetDataFolder restoreDF
End //CreateTestPulsePanel

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_CreateUtilityCoords()
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string restoreDF = GetDataFolder(1)
	SetDataFolder root:DAQ:Classes:UtilityPlot:
	variable/G left = 0
	variable/G right = 400
	variable/G bottom = 1140
	variable/G top = 640
	variable/G resistance = 0
	variable/G fiterr = 0
	SetDataFolder restoreDF
End //CreateUtilityCoords

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function UP_SwitchMode(cntrlName,popNum,popStr) : PopupMenuControl
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string cntrlName
	variable popNum
	string popStr
	NVAR testType = root:DAQ:Classes:UtilityPlot:testType
	testType = popNum
End //UP_SwitchMode

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function UP_SwitchChan(cntrlName,popNum,popStr) : PopupMenuControl
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string cntrlName
	variable popNum
	string popStr
	SVAR SwitchChan = root:DAQ:Classes:UtilityPlot:SwitchChan
	SwitchChan = popStr
End //UP_SwitchChan


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_ToggleTest(ctrlName) : ButtonControl
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Similar to the main acquisition call, but instead this call is designed to execute and update more rapidly, no save ability	
	string ctrlName
	
// What channel is this?
	SVAR SwitchChan = root:DAQ:Classes:UtilityPlot:SwitchChan

// Start or Stop
	NVAR UtilG = root:DAQ:Classes:UtilityPlot:UtilG
	
// Call the testpulseACQ function
	UtilG = !UtilG

	CORD_testACQ(UtilG,SwitchChan)
	string Titles = "Start;Stop"
	Button $ctrlName title=StringFromList(UtilG,Titles)
	
End //StartTest

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_testACQ(Flag,channel)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	variable Flag
	string channel
	
	if(Flag)
		
		NVAR testFlag = root:DAQ:Classes:UtilityPlot:testType
		NVAR UtilG = root:DAQ:Classes:UtilityPlot:UtilG
		NVAR counter = root:DAQ:Classes:UtilityPlot:counter
		
	// Create the test pulse to be injected	
		CORD_CreateTestPulse(testFlag,channel)

		SetDataFolder root:DAQ:Classes:UtilityPlot:
		
		
		string ChanInName = "test_"+channel
		Duplicate /O testPulse, $ChanInName
		WAVE local = $ChanInName		

		string ReadInWaves = ChanInName+", 0;"
		string ExStr = ""
		
	 // Make sure to turn off the FIFO to prevent an error
 		FIFOStatus /Q TheFIFO
 		if(V_FIFORunning!=0)
 			fDAQmx_ScanStop("Dev1")
			CtrlFIFO TheFIFO, stop
		endif
		
		switch(testFlag)
		
			case 1:
				ExStr = "CORD_InitialDisplayHook("+ChanInName+",counter)"

				strswitch(channel)	// string switch
					case "Channel_A":		// execute if case matches expression
						ReadInWaves = ChanInName+", 0;"
						DAQmx_Scan /DEV="Dev1" /TRIG={"/Dev1/Ctr0InternalOutput"} /EOSH="CORD_InitialDisplayHook(test_Channel_A,counter)" /RPT /BKG WAVES=ReadInWaves
						DAQmx_WaveformGen /DEV="dev1"  /TRIG={"/Dev1/Ctr0InternalOutput"} "testPulse, 0;"
						break						// exit from switch
					case "Channel_B":
						ReadInWaves = ChanInName+", 1;"
						DAQmx_Scan /DEV="Dev1" /TRIG={"/Dev1/Ctr0InternalOutput"} /EOSH="CORD_InitialDisplayHook(test_Channel_B,counter)" /RPT /BKG WAVES=ReadInWaves
						DAQmx_WaveformGen /DEV="dev1"  /TRIG={"/Dev1/Ctr0InternalOutput"} "testPulse, 1;"
						break
				endswitch

				DAQmx_CTR_OutputPulse /DEV="Dev1" /FREQ={40, 0.1} /NPLS=100000 0
				break
	
			case 2:
				ExStr = "CORD_InitialDisplayHook("+ChanInName+",counter)"
				
				strswitch(channel)	// string switch
					case "Channel_A":		// execute if case matches expression
						ReadInWaves = ChanInName+", 0;"
						DAQmx_Scan /DEV="Dev1" /TRIG={"/Dev1/Ctr0InternalOutput"} /EOSH="CORD_InitialDisplayHook(test_Channel_A,counter)" /RPT /BKG WAVES=ReadInWaves
						DAQmx_WaveformGen /DEV="dev1"  /TRIG={"/Dev1/Ctr0InternalOutput"} "testPulse, 0;"
						break						// exit from switch
					case "Channel_B":
						ReadInWaves = ChanInName+", 1;"
						DAQmx_Scan /DEV="Dev1" /TRIG={"/Dev1/Ctr0InternalOutput"} /EOSH="CORD_InitialDisplayHook(test_Channel_B,counter)" /RPT /BKG WAVES=ReadInWaves
						DAQmx_WaveformGen /DEV="dev1"  /TRIG={"/Dev1/Ctr0InternalOutput"} "testPulse, 1;"
						break
				endswitch				
				
				DAQmx_CTR_OutputPulse /DEV="Dev1" /FREQ={10, 0.1} /NPLS=100000 0
				break
				
		endswitch	

	else

		fDAQmx_CTR_Finished("Dev1", 0)
		fDAQmx_ScanStop("Dev1")
		fDAQmx_WaveformStop("Dev1")
		fDAQmx_WriteChan("Dev1", 0, 0.0, -0.1,1)
		fDAQmx_WriteChan("Dev1", 1, 0.0, -0.1,1)

	endif
	
End

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_InitialDisplayHook(local,counter)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	WAVE local
	variable counter
	
	//WAVE local = $wave_name
	
	if(counter==0)
		Display /HOST=UtilityPlot /K=1 /W=(0.05,0.15,0.95,0.95) local
		ModifyGraph live=1
		counter+=1
	endif
	
	// Restore online analysis functionality to estimate resistance
//	CORD_testOnlineAnalysis(testFlag,testWaveName,testPulse,channel)
	
End



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_CreateTestPulse(testFlag,channel)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	variable testFlag
	string channel
	
	string WaveRef = "root:DAQ:Classes:Amplifiers:"+channel+"_gains"
	
	if(WaveExists($WaveRef))
		WAVE scaling = $WaveRef	
	else
		Abort "Cannot find the appropriate amplifier gains. Need to setup using the Channel Configuration button."
	endif
	
	SetDataFolder root:DAQ:Classes:UtilityPlot
	
	switch(testFlag)
		case 1:
		// make the VC test pulse
			Make/O/N=(500) testPulse
			testPulse = 0
			testPulse[100,400] = -0.25 // in mV/V
			SetScale x, 0, 0.025, "s", testPulse
			break

		case 2:
		// make the CC bridge test pulse
			Make/O/N=(2000) testPulse
			testPulse = 0
			testPulse[500,1500] = -0.25 // in pA/V
			SetScale x, 0, 0.1, "s", testPulse
			break
			
	endswitch

End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_testOnlineAnalysis(testFlag,testWaveName,testPulse,channel)
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	variable testFlag
	string testWaveName
	WAVE testPulse
	string channel
	
	string WaveRef = "root:DAQ:Classes:Amplifiers:"+channel+"_gains"
	WAVE scaling = $WaveRef
	variable MohmConv = 1, base, step, errstep

	Wave local = $testWaveName
	
	NVAR Ri = root:DAQ:Classes:UtilityPlot:resistance
	NVAR Err = root:DAQ:Classes:UtilityPlot:fiterr
			
	switch(testFlag)
		case 1:
		// measure the Ri of the VC test pulse
			base = mean(local,0,50) // units are pA
			step = mean(local,350,400)
			Ri = abs(testPulse[1000]/scaling[2]) / abs(step-base) / 1000 // units are MOhm
			Err = 0
			break
			
		case 2:
		// measure the Ri and use a short step to guess the series resistance
			base = mean(local,0,10)
			step = mean(local,59.75,60)
			Ri = 1000 * abs(step-base) / abs(testPulse[2000] / scaling[3]) 
			errstep = mean(local,20.2,20.3)
			Err = 1000 * (errstep-base)
			break
			
	endswitch

	ControlUpdate/A /W=UtilityPulsePanel

End

