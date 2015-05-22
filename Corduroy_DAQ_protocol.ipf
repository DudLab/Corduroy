#pragma rtGlobals=2	 // Use modern global access method.

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 	CORDUROY_DAQ_protocol
// 		Please see READ-ME for relevant notes and information
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Window CORD_ProtocolPanel() : Panel
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Main protocol panel:
	PauseUpdate; Silent 1 // building the window...
	variable dispX = str2num(StringFromList(3, StringByKey("SCREEN1", IgorInfo(0)),","))
	variable dispY = str2num(StringFromList(4, StringByKey("SCREEN1", IgorInfo(0)),","))
	
	NewPanel/W=(10,510,185,660)/K=1 as "Protocols"
	SetDrawLayer ProgBack
	Print "DAQ Protocol Panel launched at  "+time()+" on "+date()
	SetDrawLayer UserBack
GroupBox ActiveProt,pos={3,3},size={169,140},font="Verdana",title="Stimulus Protocol",fColor=(20000,40000,60000),fstyle=0,labelBack=(20000,40000,60000),fsize=10
	Button APButton1,pos={15,23},size={145,20}, font="Verdana",proc=CORD_LoadProtocolButton,title="LOAD Protocol",fsize=10
	PopupMenu APpopup1,bodyWidth=90,font="Verdana",proc=CORD_ActiveProtPopup,pos={110,53},title="Set Active",value=root:DAQ:ProtocolPanel:ProtocolList,fsize=10
	Button APButton2,pos={15,83},size={145,20}, font="Verdana",proc=CORD_DisplayProtButton,title="VIEW Active Protocol",fsize=10
	Button APButton3,pos={15,113},size={145,20}, font="Verdana",proc=CORD_EditProtButton,title="EDIT Active Protocol",fsize=10

//	SetDrawEnv fname="Arial", fstyle=0, fsize=18, linefgc=(65278,55512,34438),textrgb=(65278,47802,17219),textxjust=1
//	DrawText 85,208,". : DATA LOG : ."
//	SetDrawEnv fstyle=2, fsize=10
//GroupBox AddMark,pos={3,210},size={169,80},font="Verdana",title="Insert mark"
//	PopupMenu AMpopup1,bodyWidth=90,font="Verdana",proc=CORD_SetDLMark,pos={110,230},title="Type  ",value="Whole-cell;Bridge adjusted;Current injected;New cell;Notes",fsize=10
//	Button AMButton1,pos={15,260},size={145,20}, font="Verdana",proc=CORD_MarkDataLog,title="MARK Data Log",fsize=10

EndMacro


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_SetDLMark(cntrlName,popNum,popStr) : PopupMenuControl
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	String cntrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr	
	SVAR gdlmark = root:DAQ:General:gdlmark
	gdlmark = popStr
	print "Mark string: \""+gdlmark+"\""
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_MarkDataLog(cntrlName) : ButtonControl
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string cntrlName
// Get the basename for various important references
	SVAR gdlmark = root:DAQ:General:gdlmark
	SVAR baseName = root:DAQ:General:baseName
// Create the notebook name
	string nbname = baseName+"NB"
	string marktext=""
	strswitch(gdlmark)
	case "Whole-cell":
		marktext="Whole cell configuration obtained at "
		break
	case "Bridge adjusted":
		marktext="Bridge balance adjusted to {} at "
		break
	case "Current injected":
		marktext="{} injected to maintain membrane potential at "
		break	
	case "New cell":
		marktext="Recording from a new cell -- "
		break
	case "Notes":
		marktext="User entered a note at "
		break
	endswitch
	print marktext
// Finally print the text to the notebook
	Notebook $nbname, text=marktext+time()+"\r"
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_DisplayProtocolPanel()
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Create globals that will need to be accessed by the panel
	String thisDF = GetDataFolder(1)
	NewDataFolder/O root:DAQ
	NewDataFolder/O root:DAQ:Protocols
	NewDataFolder/O root:DAQ:DynamicClamp
	NewDataFolder/O/S root:DAQ:ProtocolPanel
	CORD_ListProtocols()

	SetDataFolder root:DAQ:ProtocolPanel
	String activeProtDef = StrVarOrDefault(":activeProt","none")
	String/G activeProt = activeProtDef
	String activeTrigDef = StrVarOrDefault(":activeTrig","none")
	String/G activeTrig = activeTrigDef
	Variable applyTrigDef = NumVarOrDefault(":applyTrig",0)
	Variable/G applyTrig = applyTrigDef
	variable/G SaveToggle = 0
// Launch the panel
	DoWindow/F CORD_ProtocolPanel
	if (V_Flag!=0)
		DoWindow/K CORD_ProtocolPanel
	endif
	Execute "CORD_ProtocolPanel()"
	Execute "ModifyPanel cbRGB = (20000,20000,20000)"
// Restore initial data folder
	SetDataFolder thisDF

End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_LoadProtocolButton(cntrlName) : ButtonControl
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string cntrlName
	CORD_LoadProtocol()

End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_ActiveProtPopup(cntrlName,popNum,popStr) : PopupMenuControl
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	String cntrlName
	Variable popNum	// which item is currently selected (1-based)
	String popStr		// contents of current popup item as string

	string thisDF = GetDataFolder(1)
	
	SVAR name2 = root:DAQ:ProtocolPanel:activeProt
	SVAR name = root:DAQ:General:gactiveprot	
	SVAR chanIn = root:DAQ:General:gactivechanIn
	SVAR chanOut = root:DAQ:General:gactivechanOut	
	SVAR sweeps = root:DAQ:General:gactivesweeps
	SVAR associatedmod = root:DAQ:General:associatedmod

	if(stringmatch(popStr, "None"))
		
		name = popStr
		name2 = popStr
		chanIn = "0"
		chanOut = "0"
		sweeps = "1"
		associatedmod = "none"
	
	else
	
		SetDataFolder root:DAQ:ProtocolPanel

		string/G activeProt = popStr
		print "Active protocol is "+popStr

		string ActProtLoc = "root:DAQ:Protocols:"+popStr
		SetDataFolder $ActProtLoc
		
		string swaveref = popStr+"_svar"
		string nwaveref = popStr+"_nvar"
		WAVE/T SVAR_Wave = $swaveref
		WAVE NVAR_Wave = $nwaveref
		
		name = SVAR_Wave[0]
		name2 = SVAR_Wave[0]
		chanOut = SVAR_Wave[1]
		chanIn = SVAR_Wave[2]
		sweeps = num2str(NVAR_Wave[0])
		associatedmod = SVAR_Wave[3]
		
	endif
	
	SetDataFolder root:
			
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_ListProtocols()
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string oldDF=GetDataFolder(1)
	variable AllFolders = CountObjects("root:DAQ:Protocols:",4)
	string tmp1 = ""
	SetDataFolder root:DAQ:ProtocolPanel

	string/G ProtocolList = ""
	variable index=0
	do
		if (index > AllFolders)
			break
		endif
		tmp1= GetIndexedObjName("root:DAQ:Protocols:",4,index)
//		print tmp1
		if(index==0)
			ProtocolList = "None;"+tmp1
		else
			ProtocolList = ProtocolList+";"+tmp1
		endif
		index+=1
	while(1)
	
	if(strlen(ProtocolList) == 0)
		ProtocolList = "None;"
	endif

	DoUpdate
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_EditProtButton(cntrlName) : ButtonControl
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string cntrlName
	
	SVAR active = root:DAQ:General:gactiveprot
	CORD_DisplayProtGenPanel(active)

End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_DisplayProtButton(cntrlName) : ButtonControl
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string cntrlName
	CORD_DisplayProtocol()
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_DisplayProtocol()
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	SVAR active = root:DAQ:ProtocolPanel:activeProt
	string ChannelList = "A;B;C;D"

	if(stringmatch(active, "None"))
		Abort "No active protocol is selected."
	else
		SetDataFolder root:DAQ:Protocols:$active
	endif
	
	string ProtTraceWC = "seg_*"
	string ProtTraces = WaveList(ProtTraceWC,";","")
	variable NumTraces = ItemsInList(ProtTraces)
	
	NVAR numChanOut = numChanOut

	variable protTypeFlag
	SVAR protstate = protstate
	strswitch(protstate)
		case "IC":
			protTypeFlag = 3
			break
		case "VC":
			protTypeFlag = 2
			break		
	endswitch
	
	string ToDisplay="", gainCall="",tmpWaveName="", graphName=""
	variable index, index1

	if(numChanOut==1)

		index = 0
		do
			if(index==NumTraces)
				break
			endif
			
			ToDisplay = StringFromList(index,ProtTraces)
			WAVE local2 = $ToDisplay
	
			tmpWaveName = "tmp0_"+num2str(index)
			Duplicate /O local2, $tmpWaveName
			WAVE local = $tmpWaveName
			
			gainCall = "root:DAQ:Classes:Amplifiers:Channel_"+StringFromList(index1,ChannelList)+"_gains"
			WAVE gains = $gainCall
			local = local / gains[protTypeFlag] // Unscale the protocol wave for display

			if(index==0)
				DoWindow/K DA
				Display/K=1/W=(550,500,900,700) local as "DA"
				DoWindow/C DA
				strswitch(protstate)
					case "IC":
						Label left "Amplitude (pA)"
						break
					case "VC":
						Label left "Amplitude mV)"
						break		
				endswitch
				Label bottom "Time (s)\\u#2"		
			else
				AppendToGraph/W=DA local
			endif

			index+=1
		while(1)
	
	else
	
		for(index1=0;index1<numChanOut;index1+=1)
			
			ProtTraceWC = "seg_*_"+num2str(index1)		
			ProtTraces = WaveList(ProtTraceWC,";","")
			NumTraces = ItemsInList(ProtTraces)

			index = 0
			
			do
				if(index==NumTraces)
					break
				endif
				
				ToDisplay = StringFromList(index,ProtTraces)
				WAVE local2 = $ToDisplay
		
				tmpWaveName = "tmp0_"+num2str(index)
				Duplicate /O local2, $tmpWaveName
				WAVE local = $tmpWaveName
				
				gainCall = "root:DAQ:Classes:Amplifiers:Channel_"+StringFromList(index1,ChannelList)+"_gains"
				WAVE gains = $gainCall
				local = local / gains[protTypeFlag] // Unscale the protocol wave for display
	
				if(index==0)
					graphName = "DA_"+num2str(index1)
					DoWindow/K $graphName
					Display/K=1/W=(550,100+(200*index1),900,300+(200*index1)) local as graphName
					DoWindow /C $graphName
		
					strswitch(protstate)
						case "IC":
							Label left "Amplitude (pA)"
							break
						case "VC":
							Label left "Amplitude mV)"
							break		
					endswitch
					Label bottom "Time (s)\\u#2"		
				else
					AppendToGraph/W=$graphName local
				endif
	
				index+=1
			while(1)
			
		endfor
		
	endif

End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_LoadProtocol()
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	NewDataFolder/O root:DAQ
	NewDataFolder/O/S root:DAQ:protocols
	String/G LastProtLoaded

// Set a symbolic path to locate protocol directory
	PathInfo ProtocolDir
	if (V_flag == 0)
		SVAR PathBase = root:DAQ:General:PathBase
		string NewPathName = PathBase + "Protocols:"
		NewPath ProtocolDir,  NewPathName
	else
		Print "ProtocolDir path exists as "+S_path
	endif

// Load into a temporary data folder
	NewDataFolder/O root:DAQ:protocols:temp
	SetDataFolder root:DAQ:protocols:temp
	
// Open file browser to load protocol
	LoadData/D/I/L=1/P=ProtocolDir/Q

// Unpack the object specifier waves into global variables and strings
	variable/G numsweep,interlude,sweeplength,samplerate,flag,numChanIn,numChanOut, dynamic
	string/G DASeq, ADSeq, TTLSeq
	string nvarwave = WaveList("*_nvar",";","")
	wave nvarw = $(StringFromList(0,nvarwave))
	numsweep = 	nvarw[0]
	interlude = 		nvarw[1]
	sweeplength = 	nvarw[2]
	samplerate =	nvarw[3]
	flag = 			nvarw[4]
	numChanIn =	nvarw[5]
	numChanOut = 	nvarw[6]
	dynamic = 		nvarw[7]
	
	string/G protname="", DASeq="", ADSeq="", associatedmod="", protstate=""
	string svarwave = WaveList("*_svar",";","")
	wave/T svarw = $(StringFromList(0,svarwave))
	protname = 		svarw[0]
	DASeq = 		svarw[1]
	ADSeq = 		svarw[2]
	associatedmod = svarw[3]
	protstate = 		svarw[4]

// Give some update in the history window of the protocol actions
	print "Now loading... "+protname
	LastProtLoaded = protname

// Rename the folder to the protocol name
	DuplicateDataFolder root:DAQ:protocols:temp, root:DAQ:protocols:$protname
	KillDataFolder root:DAQ:protocols:temp

// Finally, update the list of protocols
	CORD_ListProtocols()
	DoUpdate
End


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_UnloadProt()
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	if(DataFolderExists("root:DAQ:protocols"))
		KillDataFolder root:DAQ:protocols
		CORD_DisplayProtocolPanel()
	endif

End