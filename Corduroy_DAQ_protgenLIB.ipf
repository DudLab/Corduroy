#pragma rtGlobals=2		// Use modern global access method.

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 	CORDUROY_DAQ_protgenLIB
// 		Please see READ-ME for relevant notes and information
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_PG_STEP_execute(seg_name,generate,protIndex)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string seg_name
	variable generate // flag specifying whether to create the executable call or actually generate waves; 1 to generate
	variable protIndex 
	
// Reference common global variables (values in ms and pA)
	NVAR sweeplength = root:DAQ:ProtGen:Current:sweeplength
	NVAR numsweep = root:DAQ:ProtGen:Current:numsweep
	NVAR SampleRate = root:DAQ:ProtGen:Current:samplerate
	NVAR STEP_amp = root:DAQ:ProtGen:Current:STEP_amp
	NVAR STEP_factor = root:DAQ:ProtGen:Current:STEP_factor
	NVAR STEP_off = root:DAQ:ProtGen:Current:STEP_off
	NVAR STEP_on = root:DAQ:ProtGen:Current:STEP_on
	
// Reference specific global variables
	// None for STEP


// Main creation loop
	if(generate)

		if(STEP_off>sweeplength)
			Abort "Please change time off to be <= sweeplength"
		endif

		WAVE VarWave = VarWave
		SVAR IndWave = IndWave

		if(VarWave[2]>sweeplength)
			Abort "Please change sweeplength to be greater than "+num2str(VarWave[2])+", before generating the protocol with these segments."
		endif
	
		// Change the data folder to the segment data folder
		string segDF = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		SetDataFolder $segDF

		variable index=0
		string IndWaveName = ""
			
		for(index=0;index<=(numsweep-1);index+=1)

			IndWaveName = "seg_"+num2str(index)+"_"+num2str(protIndex)
			Make/O/N=(sweeplength*SampleRate) $IndWaveName=0
			WAVE Local = $IndWaveName

		// START specific parameter description //

			Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)] = VarWave[0] + (VarWave[1]*index) 

		// END specific parameter description //
		
			// Move the newly created segment wave to the protocol directory
			MoveWave $IndWaveName, root:DAQ:ProtGen:Current:

		endfor	

	else

		// Create segments within a standard folder in the DA data folder
		string seg_folder = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		NewDataFolder/O/S $seg_folder
		
		// Store necessary variables into a variable wave and an indexing list for retrieval
		Make/O VarWave = {STEP_amp,STEP_factor,STEP_off,STEP_on}
		String/G IndWave = "STEP_amp;STEP_factor;STEP_off;STEP_on"
		String/G GenerateString = "CORD_PG_STEP_execute(\""+seg_name+"\",1,"

		// Save the segment as a single data file
		CORD_SaveSegToDisk(seg_name,1) // 1 for a DA segment

	endif
	
End // STEP


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_PG_FUNC_execute(seg_name,generate,protIndex)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string seg_name
	variable generate // flag specifying whether to create the executable call or actually generate waves; 1 to generate
	variable protIndex

// Reference common global variables (values in ms and pA)
	NVAR sweeplength = root:DAQ:ProtGen:Current:sweeplength
	NVAR numsweep = root:DAQ:ProtGen:Current:numsweep
	NVAR SampleRate = root:DAQ:ProtGen:Current:samplerate
	NVAR STEP_amp = root:DAQ:ProtGen:Current:STEP_amp
	NVAR STEP_factor = root:DAQ:ProtGen:Current:STEP_factor
	NVAR STEP_off = root:DAQ:ProtGen:Current:STEP_off
	NVAR STEP_on = root:DAQ:ProtGen:Current:STEP_on
	
// Reference specific global variables
	SVAR FUNC_type_gstr = root:DAQ:ProtGen:Current:FUNC_type_gstr
	NVAR FUNC_freq = root:DAQ:ProtGen:Current:FUNC_freq
	// FUNC_p1 -> parameter one describing the distribution -> frequency multiplier (Steps with ascending or descending frequencies)
	NVAR FUNC_p1 = root:DAQ:ProtGen:Current:FUNC_p1
	// FUNC_p2 -> parameter one describing the distribution -> linear change in frequency (ZAP functions)
	NVAR FUNC_p2 = root:DAQ:ProtGen:Current:FUNC_p2

// Begin code for generation and saving of segment
	if(generate)
	
		if(STEP_off>sweeplength)
			Abort "Please change time off to be <= sweeplength"
		endif

		WAVE VarWave = VarWave
		SVAR IndWave = IndWave
		WAVE/T StrWave = StrWave

		if(VarWave[2]>sweeplength)
			Abort "Please change sweeplength to be greater than "+num2str(VarWave[2])+", before generating the protocol with these segments."
		endif
	
		// Change the data folder to the segment data folder
		string segDF = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		SetDataFolder $segDF

		variable index=0
		string IndWaveName = ""

		for(index=0;index<=(numsweep-1);index+=1)

			IndWaveName = "seg_"+num2str(index)+"_"+num2str(protIndex)
			Make/O/N=(sweeplength*SampleRate) $IndWaveName=0
			WAVE Local = $IndWaveName

		// START specific parameter description //
			strswitch(StrWave[0])
			////////////// p1 and p2 NOT used ///////////////
				case "Sine":
					Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)] = ( VarWave[0] * sin(VarWave[4] * ((x-VarWave[3])*((2 * pi)/(SampleRate*1000)))) ) + (VarWave[1]*index)
					break	
				case "Cosine":
					Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)] = (VarWave[0] * cos(VarWave[4] * ((x-VarWave[3])*((2 * pi)/(SampleRate*1000)))) ) + (VarWave[1]*index)
					break
				case "Saw":
					Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)] = (VarWave[0] * sawtooth(VarWave[4] * ((x-VarWave[3])*((2 * pi)/(SampleRate*1000)))) ) + (VarWave[1]*index)
					break
				default:
					abort "Selected function is not currently supported"
			Endswitch
		// END specific parameter description //

			// Move the newly created segment wave to the protocol directory
			MoveWave $IndWaveName, root:DAQ:ProtGen:Current:

		endfor	

	else

		// Create segments within a standard folder in the DA data folder
		string seg_folder = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		NewDataFolder/O/S $seg_folder
		
		// Store necessary variables into a variable wave and an indexing list for retrieval
		Make/O VarWave = {STEP_amp,STEP_factor,STEP_off,STEP_on,FUNC_freq,FUNC_p1,FUNC_p2}
		String/G IndWave = "STEP_amp;STEP_factor;STEP_off;STEP_on;FUNC_freq;FUNC_p1;FUNC_p2"
		Make/O/T StrWave = {FUNC_type_gstr}
		String/G GenerateString = "CORD_PG_FUNC_execute(\""+seg_name+"\",1,"

		// Save the segment as a single data file
		CORD_SaveSegToDisk(seg_name,1) // 1 for a DA segment

	endif
	
End // FUNC


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_PG_SIMS_execute(seg_name,generate,protIndex)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string seg_name
	variable generate // flag specifying whether to create the executable call or actually generate waves; 1 to generate
	variable protIndex

// Reference common global variables (values in ms and pA)
	NVAR sweeplength = root:DAQ:ProtGen:Current:sweeplength
	NVAR numsweep = root:DAQ:ProtGen:Current:numsweep
	NVAR SampleRate = root:DAQ:ProtGen:Current:samplerate
	NVAR STEP_amp = root:DAQ:ProtGen:Current:STEP_amp
	NVAR STEP_factor = root:DAQ:ProtGen:Current:STEP_factor
	NVAR STEP_off = root:DAQ:ProtGen:Current:STEP_off
	NVAR STEP_on = root:DAQ:ProtGen:Current:STEP_on

// Reference specific global variables
	// SIMS_tau -> describes the rise and decay of biexponential synaptic input, solution truncated at 8*tau (ms)
	NVAR SIMS_tau1 = root:DAQ:ProtGen:Current:SIMS_tau1
	NVAR SIMS_tau2 = root:DAQ:ProtGen:Current:SIMS_tau2	
	// SIMS_amp -> parameter describing the height of an individual sEPSP (pA)
	NVAR SIMS_amp = root:DAQ:ProtGen:Current:SIMS_amp
	// SIMS_p1 -> parameter one describing the distribution -> average frequency (Hz)
	NVAR SIMS_p1 = root:DAQ:ProtGen:Current:SIMS_p1
	// SIMS_p2 -> parameter one describing the distribution -> order of kappa distribution, not valid for linear or poisson distributions
	NVAR SIMS_p2 = root:DAQ:ProtGen:Current:SIMS_p2
	// SIMS_type -> type of distribution. Currently Linear, Poisson, and Kappa distributions are supported
	SVAR SIMS_type_gstr = root:DAQ:ProtGen:Current:SIMS_type_gstr
	// SIMS_dynamic -> for random distributions new random distributions can be generated for each wave or maintained
	SVAR SIMS_dynamic_gstr = root:DAQ:ProtGen:Current:SIMS_dynamic_gstr
	variable dynamic = 0
		if(stringmatch(SIMS_dynamic_gstr,"Yes"))
			dynamic = 1
		endif

	if(generate)
	
		if(STEP_off>sweeplength)
			Abort "Please change time off to be <= sweeplength"
		endif

		WAVE VarWave = VarWave
		SVAR IndWave = IndWave
		WAVE/T StrWave = StrWave
		if(stringmatch(StrWave[1],"Yes"))
			dynamic = 1
		endif

		if(VarWave[2]>sweeplength)
			Abort "Please change sweeplength to be greater than "+num2str(VarWave[2])+", before generating the protocol with these segments."
		endif
	
		// Change the data folder to the segment data folder
		string segDF = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		SetDataFolder $segDF

		variable index=0
		string IndWaveName = ""
			
		for(index=0;index<=(numsweep-1);index+=1)

			IndWaveName = "seg_"+num2str(index)+"_"+num2str(protIndex)
			Make/O/N=(sweeplength*SampleRate) $IndWaveName=0
			WAVE Local = $IndWaveName

		// START specific parameter description //

//			// Create list of times from specified distribution
//			string DeltaTimes
//			DeltaTimes = CORD_CreateDeltaFunction(StrWave[0],VarWave[7],VarWave[8],SampleRate,(VarWave[2]-VarWave[3]),dynamic,0)
//
//			// Create the delta wave without pulses
//			Make/O/N=(sweeplength*SampleRate) delta=0

//			// Step through list and enter unit pulse (delta function) at specified points
//			variable Dindex = 0
//			for(Dindex=0;Dindex<ItemsInList(DeltaTimes);Dindex+=1)
//				delta[str2num(StringFromList(Dindex,DeltaTimes))] = 1
//			endfor

//			CORD_CreateDelta2(length,sampleRate,eventType,eventP1,eventP2)
			CORD_CreateDelta2((VarWave[2]-VarWave[3]),SampleRate,StrWave[0],VarWave[7],VarWave[8]) // this function directly returns delta
			WAVE delta=delta

			// Create wave of individual synaptic potential
			Make/O/N=(VarWave[5]*8*SampleRate) synWave // Let the synaptic decay for 8 tau
			synWave = (1-exp(-x/(VarWave[4]*SampleRate)))*(exp(-x/(VarWave[5]*SampleRate)))
			WaveStats/Q/Z synWave
			synWave = (synWave / V_max) * VarWave[6] // scale the synaptic to a value of 1 before multiplying by amplitude 

			// Convolve delta function with simsyn parameter wave
			Convolve synWave, delta 

			// Truncate to sweep length and add offset if required
//			Duplicate /O/R=((VarWave[3]*SampleRate),(VarWave[2]*SampleRate)) delta, holdingwave
//			Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)]=holdingwave[x-(VarWave[3]*SampleRate)]

			Local[(VarWave[3]*SampleRate),]=delta[p-(VarWave[3]*SampleRate)]
			if(VarWave[0]>0 && VarWave[1]>0)
				Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)] += VarWave[0] + (VarWave[1]*index)
			endif
			
		// END specific parameter description //

			// Move the newly created segment wave to the protocol directory
			MoveWave $IndWaveName, root:DAQ:ProtGen:Current:

		endfor	

	else

		// Create segments within a standard folder in the DA data folder
		string seg_folder = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		NewDataFolder/O/S $seg_folder
		
		// Store necessary variables into a variable wave and an indexing list for retrieval
		Make/O VarWave = {STEP_amp,STEP_factor,STEP_off,STEP_on,SIMS_tau1,SIMS_tau2,SIMS_amp,SIMS_p1,SIMS_p2}
		String/G IndWave = "STEP_amp;STEP_factor;STEP_off;STEP_on;SIMS_tau1;SIMS_tau2;SIMS_amp,SIMS_p1;SIMS_p2"
		Make/O/T StrWave = {SIMS_type_gstr,SIMS_dynamic_gstr}
		String/G GenerateString = "CORD_PG_SIMS_execute(\""+seg_name+"\",1,"
		
		// Save the segment as a single data file
		CORD_SaveSegToDisk(seg_name,1) // 1 for a DA segment

	endif
	
End // SIMS


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_PG_TTL_execute(seg_name,generate,protIndex)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string seg_name
	variable generate // flag specifying whether to create the executable call or actually generate waves; 1 to generate
	variable protIndex

// Reference common global variables (values in ms and pA)
	NVAR sweeplength = root:DAQ:ProtGen:Current:sweeplength
	NVAR numsweep = root:DAQ:ProtGen:Current:numsweep
	NVAR SampleRate = root:DAQ:ProtGen:Current:samplerate
	NVAR STEP_amp = root:DAQ:ProtGen:Current:STEP_amp
	NVAR STEP_factor = root:DAQ:ProtGen:Current:STEP_factor
	NVAR STEP_off = root:DAQ:ProtGen:Current:STEP_off
	NVAR STEP_on = root:DAQ:ProtGen:Current:STEP_on

// Reference specific global variables
// TTL_w&h -> describes the shape of the TTL pulse
	NVAR TTL_w = root:DAQ:ProtGen:Current:TTL_w
	NVAR TTL_h = root:DAQ:ProtGen:Current:TTL_h	
// TTL_p1 -> parameter one describing the distribution - average frequency
	NVAR TTL_p1 = root:DAQ:ProtGen:Current:TTL_p1
// TTL_p2 -> parameter one describing the distribution - order of kappa distribution, not valid for linear or poisson distributions
	NVAR TTL_p2 = root:DAQ:ProtGen:Current:TTL_p2
// TTL_type -> type of distribution. See documentation for support or the CreateDelta function
	SVAR TTL_type_gstr = root:DAQ:ProtGen:Current:TTL_type_gstr
// TTL_dynamic -> for random distributions new random distributions can be generated for each wave or maintained
	SVAR TTL_dynamic_gstr = root:DAQ:ProtGen:Current:TTL_dynamic_gstr
	variable dynamic = 0
		if(stringmatch(TTL_dynamic_gstr,"Yes"))
			dynamic = 1
		endif


	if(generate)
	
		if(STEP_off>sweeplength)
			Abort "Please change time off to be <= sweeplength"
		endif

		WAVE VarWave = VarWave
		SVAR IndWave = IndWave
		WAVE/T StrWave = StrWave
		if(stringmatch(StrWave[1],"Yes"))
			dynamic = 1
		endif

		if(VarWave[2]>sweeplength)
			Abort "Please change sweeplength to be greater than "+num2str(VarWave[2])+", before generating the protocol with these segments."
		endif
	
		// Change the data folder to the segment data folder
		string segDF = "root:DAQ:ProtGen:Segments:TTL:"+seg_name
		SetDataFolder $segDF

		variable index=0
		string IndWaveName = ""

		for(index=0;index<=(numsweep-1);index+=1)

			IndWaveName = "seg_"+num2str(index)+"_"+num2str(protIndex)
			Make/O/N=(sweeplength*SampleRate) $IndWaveName=0
			WAVE Local = $IndWaveName

		// START specific parameter description //

			// Create list of times from specified distribution
			string DeltaTimes
			DeltaTimes = CORD_CreateDeltaFunction(StrWave[0],VarWave[6],VarWave[7],SampleRate,((VarWave[2]-VarWave[3])*SampleRate),dynamic,0)

			// Create the delta wave without pulses
			Make/O/N=(sweeplength*SampleRate) delta=0

			// Step through list and enter unit pulse (delta function) at specified points
			variable Dindex = 0
			for(Dindex=0;Dindex<ItemsInList(DeltaTimes);Dindex+=1)
				delta[str2num(StringFromList(Dindex,DeltaTimes))] = 1
			endfor

			// Create wave of individual ttl pulse
			Make/O/N=((VarWave[4]*SampleRate)+2) ttlWave
			ttlWave[1,(numpnts(ttlWave)-2)] = VarWave[5]

			// Convolve delta function with a single ttl pulse
			Convolve delta, ttlWave

			// Truncate to sweep length and add offset if required
			Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)]=ttlwave[x-(VarWave[3]*SampleRate)]
			if(VarWave[0]>0 && VarWave[1]>0)
				Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)] += VarWave[0] + (VarWave[1]*index)
			endif

		// END specific parameter description //

			// Move the newly created segment wave to the protocol directory
			MoveWave $IndWaveName, root:DAQ:ProtGen:Current:

		endfor

	else

		// Create segments within a standard folder in the DA data folder
		string seg_folder = "root:DAQ:ProtGen:Segments:TTL:"+seg_name
		NewDataFolder/O/S $seg_folder

		// Store necessary variables into a variable wave and an indexing list for retrieval
		Make/O VarWave = {STEP_amp,STEP_factor,STEP_off,STEP_on,TTL_w,TTL_h,TTL_p1,TTL_p2}
		String/G IndWave = "STEP_amp;STEP_factor;STEP_off;STEP_on;TTL_w;TTL_h;TTL_p1;TTL_p2"
		Make/O/T StrWave = {TTL_type_gstr,TTL_dynamic_gstr}
		String/G GenerateString = "CORD_PG_TTL_execute(\""+seg_name+"\",1,"

		// Save the segment as a single data file
		CORD_SaveSegToDisk(seg_name,0) // 1 for a DA segment

	endif
	
End // TTL


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_PG_SQUARE_execute(seg_name,generate,protIndex)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string seg_name
	variable generate // flag specifying whether to create the executable call or actually generate waves; 1 to generate
	variable protIndex

// Reference common global variables (values in ms and pA)
	NVAR sweeplength = root:DAQ:ProtGen:Current:sweeplength
	NVAR numsweep = root:DAQ:ProtGen:Current:numsweep
	NVAR SampleRate = root:DAQ:ProtGen:Current:samplerate
	NVAR STEP_amp = root:DAQ:ProtGen:Current:STEP_amp
	NVAR STEP_factor = root:DAQ:ProtGen:Current:STEP_factor
	NVAR STEP_off = root:DAQ:ProtGen:Current:STEP_off
	NVAR STEP_on = root:DAQ:ProtGen:Current:STEP_on

// Reference specific global variables
// SQUARE_w&h -> describes the shape of the TTL pulse
	NVAR SQUARE_w = root:DAQ:ProtGen:Current:SQUARE_w
	NVAR SQUARE_h = root:DAQ:ProtGen:Current:SQUARE_h	
// SQUARE_p1 -> parameter one describing the distribution - average frequency
	NVAR SQUARE_p1 = root:DAQ:ProtGen:Current:SQUARE_p1
// SQUARE_p2 -> parameter one describing the distribution - order of kappa distribution, not valid for linear or poisson distributions
	NVAR SQUARE_p2 = root:DAQ:ProtGen:Current:SQUARE_p2
// SQUARE_type -> type of distribution. See documentation for support or the CreateDelta function
	SVAR SQUARE_type_gstr = root:DAQ:ProtGen:Current:SQUARE_type_gstr
// SQUARE_dynamic -> for random distributions new random distributions can be generated for each wave or maintained
	SVAR SQUARE_dynamic_gstr = root:DAQ:ProtGen:Current:SQUARE_dynamic_gstr
	variable dynamic = 0
		if(stringmatch(SQUARE_dynamic_gstr,"Yes"))
			dynamic = 1
		endif


	if(generate)
	
		if(STEP_off>sweeplength)
			Abort "Please change time off to be <= sweeplength"
		endif

		WAVE VarWave = VarWave
		SVAR IndWave = IndWave
		WAVE/T StrWave = StrWave
		if(stringmatch(StrWave[1],"Yes"))
			dynamic = 1
		endif

		if(VarWave[2]>sweeplength)
			Abort "Please change sweeplength to be greater than "+num2str(VarWave[2])+", before generating the protocol with these segments."
		endif
	
		// Change the data folder to the segment data folder
		string segDF = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		SetDataFolder $segDF

		variable index=0
		string IndWaveName = ""

		for(index=0;index<=(numsweep-1);index+=1)

			IndWaveName = "seg_"+num2str(index)+"_"+num2str(protIndex)
			Make/O/N=(sweeplength*SampleRate) $IndWaveName=0
			WAVE Local = $IndWaveName

		// START specific parameter description //

			// Create list of times from specified distribution
			string DeltaTimes=""
			DeltaTimes = CORD_CreateDeltaFunction(StrWave[0],VarWave[6],VarWave[7],SampleRate,((VarWave[2]-VarWave[3])*SampleRate),dynamic,0)

			// Create the delta wave without pulses
			Make/O/N=(sweeplength*SampleRate) delta=0

			// Step through list and enter unit pulse (delta function) at specified points
			variable Dindex = 0
			for(Dindex=0;Dindex<ItemsInList(DeltaTimes);Dindex+=1)
				delta[str2num(StringFromList(Dindex,DeltaTimes))] = 1
			endfor

			// Create wave of individual ttl pulse
			Make/O/N=((VarWave[4]*SampleRate)+2) ttlWave
			ttlWave[1,(numpnts(ttlWave)-2)] = VarWave[5]

			// Convolve delta function with a single ttl pulse
			Convolve delta, ttlWave

			// Truncate to sweep length and add offset if required
			Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)]=ttlwave[x-(VarWave[3]*SampleRate)]
			if(VarWave[0]>0 && VarWave[1]>0)
				Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)] += VarWave[0] + (VarWave[1]*index)
			endif

		// END specific parameter description //

			// Move the newly created segment wave to the protocol directory
			MoveWave $IndWaveName, root:DAQ:ProtGen:Current:

		endfor

	else

		// Create segments within a standard folder in the DA data folder
		string seg_folder = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		NewDataFolder/O/S $seg_folder

		// Store necessary variables into a variable wave and an indexing list for retrieval
		Make/O VarWave = {STEP_amp,STEP_factor,STEP_off,STEP_on,SQUARE_w,SQUARE_h,SQUARE_p1,SQUARE_p2}
		String/G IndWave = "STEP_amp;STEP_factor;STEP_off;STEP_on;SQUARE_w;SQUARE_h;SQUARE_p1;SQUARE_p2"
		Make/O/T StrWave = {SQUARE_type_gstr,SQUARE_dynamic_gstr}
		String/G GenerateString = "CORD_PG_SQUARE_execute(\""+seg_name+"\",1,"

		// Save the segment as a single data file
		CORD_SaveSegToDisk(seg_name,1) // 1 for a DA segment

	endif
	
End // SQUARE




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_PG_BURST_execute(seg_name,generate,protIndex)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string seg_name
	variable generate // flag specifying whether to create the executable call or actually generate waves; 1 to generate
	variable protIndex

// Reference common global variables (values in ms and pA)
	NVAR sweeplength = root:DAQ:ProtGen:Current:sweeplength
	NVAR numsweep = root:DAQ:ProtGen:Current:numsweep
	NVAR SampleRate = root:DAQ:ProtGen:Current:samplerate
	NVAR STEP_amp = root:DAQ:ProtGen:Current:STEP_amp
	NVAR STEP_factor = root:DAQ:ProtGen:Current:STEP_factor
	NVAR STEP_off = root:DAQ:ProtGen:Current:STEP_off
	NVAR STEP_on = root:DAQ:ProtGen:Current:STEP_on

// Reference specific global variables
// BURST_w&h -> describes the shape of the TTL pulse
	NVAR BURST_w = root:DAQ:ProtGen:Current:BURST_w
	NVAR BURST_h = root:DAQ:ProtGen:Current:BURST_h	
// BURST_p1 -> parameter one describing the frequency of stimulation in the burst
	NVAR BURST_p1 = root:DAQ:ProtGen:Current:BURST_p1
// BURST_p2 -> parameter describing length of each burst
	NVAR BURST_p2 = root:DAQ:ProtGen:Current:BURST_p2
// BURST_p3 -> parameter describing the gap between each burst
	NVAR BURST_p3 = root:DAQ:ProtGen:Current:BURST_p3

	if(generate)
	
		if(STEP_off>sweeplength)
			Abort "Please change time off to be <= sweeplength"
		endif

		WAVE VarWave = VarWave
		SVAR IndWave = IndWave

		if(VarWave[2]>sweeplength)
			Abort "Please change sweeplength to be greater than "+num2str(VarWave[2])+", before generating the protocol with these segments."
		endif
	
		// Change the data folder to the segment data folder
		string segDF = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		SetDataFolder $segDF

		variable index=0
		string IndWaveName = ""

		for(index=0;index<=(numsweep-1);index+=1)

			IndWaveName = "seg_"+num2str(index)+"_"+num2str(protIndex)
			Make/O/N=(sweeplength*SampleRate) $IndWaveName=0
			WAVE Local = $IndWaveName

		// START specific parameter description //

			// Create list of times from specified distribution
			string DeltaTimes=""
			DeltaTimes = CORD_CreateDeltaFunction("Burst",VarWave[6],VarWave[7],SampleRate,((VarWave[2]-VarWave[3])*SampleRate),0,0)

			// Create the delta wave without pulses
			Make/O/N=(sweeplength*SampleRate) delta=0

			// Step through list and enter unit pulse (delta function) at specified points
			variable Dindex = 0
			for(Dindex=0;Dindex<ItemsInList(DeltaTimes);Dindex+=1)
				delta[str2num(StringFromList(Dindex,DeltaTimes))] = 1
			endfor

			// Create wave of individual ttl pulse
			Make/O/N=((VarWave[4]*SampleRate)+2) ttlWave
			ttlWave[1,(numpnts(ttlWave)-2)] = VarWave[5]

			// Convolve delta function with a single ttl pulse
			Convolve delta, ttlWave

			// Truncate to sweep length and add offset if required
			Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)]=ttlwave[x-(VarWave[3]*SampleRate)]
			if(VarWave[0]>0 && VarWave[1]>0)
				Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)] += VarWave[0] + (VarWave[1]*index)
			endif

		// END specific parameter description //

			// Move the newly created segment wave to the protocol directory
			MoveWave $IndWaveName, root:DAQ:ProtGen:Current:

		endfor

	else

		// Create segments within a standard folder in the DA data folder
		string seg_folder = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		NewDataFolder/O/S $seg_folder

		// Store necessary variables into a variable wave and an indexing list for retrieval
		Make/O VarWave = {STEP_amp,STEP_factor,STEP_off,STEP_on,BURST_w,BURST_h,BURST_p1,BURST_p2}
		String/G IndWave = "STEP_amp;STEP_factor;STEP_off;STEP_on;BURST_w;BURST_h;BURST_p1;BURST_p2"
		Make/O/T StrWave = ""
		String/G GenerateString = "CORD_PG_BURST_execute(\""+seg_name+"\",1,"

		// Save the segment as a single data file
		CORD_SaveSegToDisk(seg_name,1) // 1 for a DA segment

	endif
	
End // BURST



///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_PG_ARB_execute(seg_name,generate,protIndex)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string seg_name
	variable generate // flag specifying whether to create the executable call or actually generate waves; 1 to generate
	variable protIndex

// NOTE: It is the user's responsibility in using this function to load waves with appropriate numbers of points. 
//            Units are the same as with all other functions, pA and mV for IC and VC respectively.

// Reference common global variables (values in ms and pA)
	NVAR sweeplength = root:DAQ:ProtGen:Current:sweeplength
	NVAR numsweep = root:DAQ:ProtGen:Current:numsweep
	NVAR SampleRate = root:DAQ:ProtGen:Current:samplerate
	NVAR STEP_amp = root:DAQ:ProtGen:Current:STEP_amp
	NVAR STEP_factor = root:DAQ:ProtGen:Current:STEP_factor
	NVAR STEP_off = root:DAQ:ProtGen:Current:STEP_off
	NVAR STEP_on = root:DAQ:ProtGen:Current:STEP_on

// Reference specific global variables
	NVAR ARB_scale = root:DAQ:ProtGen:Current:ARB_scale
	NVAR ARB_offset = root:DAQ:ProtGen:Current:ARB_offset
	NVAR ARB_filter = root:DAQ:ProtGen:Current:ARB_filter

// Main creation loop
	if(generate)

		if(STEP_off>sweeplength)
			Abort "Please change time off to be <= sweeplength"
		endif

		WAVE VarWave = VarWave
		SVAR IndWave = IndWave

		if(VarWave[2]>sweeplength)
			Abort "Please change sweeplength to be greater than "+num2str(VarWave[2])+", before generating the protocol with these segments."
		endif
	
		// Change the data folder to the segment data folder
		string segDF = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		SetDataFolder $segDF

		variable index=0
		string IndWaveName = ""
		string ArbWaveName = ""
			
		for(index=0;index<=(numsweep-1);index+=1)

			IndWaveName = "seg_"+num2str(index)+"_"+num2str(protIndex)
			Make/O/N=(sweeplength*SampleRate) $IndWaveName=0
			WAVE Local = $IndWaveName

		// START specific parameter description //
			// find/load the arb wave
			ArbWaveName = "ArbWave"+num2str(index)
			Wave CurrentArb = $ArbWaveName

			// do you want to filter the loaded wave?
			if(VarWave[5]>0)
				// run filtering here // NOT YET IMPLEMENTED
			endif
			
			// scale and offset the wave
//			Duplicate/O $ArbWaveName, Local 		// SIMPLE VERSION

			Local[(VarWave[3]*SampleRate),(VarWave[2]*SampleRate)] = CurrentArb[x-(VarWave[3]*SampleRate)]

			if(VarWave[4]>0)
				Local = Local * VarWave[4]
			endif
		// END specific parameter description //

			// Move the newly created segment wave to the protocol directory
			MoveWave $IndWaveName, root:DAQ:ProtGen:Current:

		endfor	

	else

		// Create segments within a standard folder in the DA data folder
		string seg_folder = "root:DAQ:ProtGen:Segments:DA:"+seg_name
		NewDataFolder/O/S $seg_folder
		
		// Store necessary variables into a variable wave and an indexing list for retrieval
		Make/O VarWave = {STEP_amp,STEP_factor,STEP_off,STEP_on,ARB_scale,ARB_filter}
		String/G IndWave = "STEP_amp;STEP_factor;STEP_off;STEP_on;ARB_scale;ARB_filter"
		String/G GenerateString = "CORD_PG_ARB_execute(\""+seg_name+"\",1,"

		// Save the segment as a single data file
		CORD_SaveSegToDisk(seg_name,1) // 1 for a DA segment
		
		print "User must move arbitary waves to the Current directory and name them ArbWave0, ArbWave1, etc."

	endif
	
End // ARB


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_PG_NRN_execute(seg_name,generate)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string seg_name
	variable generate // flag specifying whether to create the executable call or actually generate waves; 1 to generate

// NOTE: This feature should only be used by advanced users. It requires a detailed understanding of both the NEURON simulation
//		  and Applescript, in addition to a good understanding of using Corduroy. Please email j.dudman@gmail.com for help.

//Current ideas for design:
//	Have a series of hoc files that run the simulation recording the net current at the base of the dendrite that will enter the soma
//	There should be a single, very minimal hoc file that determines the stimulus vector (spike times) to inject for each synapse
//	This single hoc file can be opened and edited by this code in neuron
//	In addition there should be a straightforward indexing of the file that holds the values for the current that will be injected through Corduroy

End // NRN

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_CreateDelta2(length,sampleRate,eventType,eventP1,eventP2)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	variable length //total duration of the delta train in ms
	variable sampleRate // in kHz
	string eventType // from the switch below
	variable eventP1 // rate
	variable eventP2 // varies by type: Linear-nothing; Poisson-nothing; PoissonR-renewal; Gaussian-sd; Gamma-b
	
	variable numSamples = (length/1000)*(SampleRate*1000)
	variable index, pSpike
		
	strswitch(eventType)	// string switch

		case "Linear":		// execute if case matches expression
			Make/O/N=(numSamples) delta=0
			variable msBtwnEvents = 1000/eventP1
			variable sampsBtwnEvents = msBtwnEvents * SampleRate
			print sampsBtwnEvents
			for(index=0;index<numSamples;index+=sampsBtwnEvents)
				delta[index] = 1
			endfor
			break

		case "Poisson":		// execute if case matches expression
			pSpike = eventP1 * (1/(SampleRate*1000))
			print pSpike
			Make/O/N=(numSamples) delta=0
			delta = enoise(0.5)+0.5
			for(index=0;index<numSamples;index+=1)
				if(delta[index]<pSpike)
					delta[index]=1
				else
					delta[index]=0
				endif
			endfor
			break

		case "PoissonR":		// execute if case matches expression
			pSpike = eventP1 * (1/(SampleRate*1000))
			print pSpike
			Make/O/N=(numSamples) delta=0
			delta = enoise(0.5)+0.5
			for(index=0;index<numSamples;index+=eventP2)
				if(delta[index]<pSpike)
					delta[index]=1
					delta[index+1,index+eventP2-1]=0
				else
					delta[index,index+eventP2-1]=0
				endif
			endfor
			break

		case "Gaussian":		// execute if case matches expression
			pSpike = eventP1 * (1/(SampleRate*1000))
			print pSpike
			Make/O/N=(numSamples) delta=0
			do
				index+= (1000/(eventP1+gnoise(eventP2))) * SampleRate
				delta[index]=1	
			while (index<numSamples)				// as long as expression is TRUE
			break

		case "Gamma":		// execute if case matches expression
			pSpike = eventP1 * (1/(SampleRate*1000))
			print pSpike
			Make/O/N=(numSamples) delta=0
			do
				index+= (1000/gammaNoise(eventP1,eventP2)) * SampleRate
				delta[index]=1	
			while (index<numSamples)				// as long as expression is TRUE
			break

	endswitch
end

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function/S CORD_CreateDeltaFunction(type,p1,p2,SampleRate,length_in_ms,dynamic,plot)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string type // random distribution string description
	variable p1 // average rate for most distributions
	variable p2 // generally the order of the distribution or the renewal period
	variable SampleRate // in kHz
	variable length_in_ms // in ms
	variable dynamic // create new random distribution for each sweep?
	variable plot
	
	variable length = length_in_ms*SampleRate*1000
	
// Make a random number wave for the generation of random number
	if(dynamic)
		Make/O/N=(length) RandWave = enoise(0.5) + 0.5
	else
		SetRandomSeed 0.5 // This call gives the same "random" sequence
		Make/O/N=(length) RandWave = enoise(0.5) + 0.5
	endif
// initialize variables for loops
	variable index=0
	string DeltaTimes=""
	variable prob, count,tmpPoint

// Decide how to look for relevant points based upon the chosen distribution
	strswitch(type)

		case "Linear":

			do
				tmpPoint = index*((SampleRate*1000)/p1)
				if(tmpPoint>length)
					break
				else
					DeltaTimes += num2str(tmpPoint)+";"
				endif
				index+=1			
			while(1)
			break

		case "Poisson":
			// For a perfect poisson the probability of a spike is given by p = r*dt
			
			prob = p1 / (SampleRate*1000) // [events/s] / ([sample/ms] * [ms/s]) = [events/sample]
			for(index=0;index<=length;index+=1)
				if(RandWave[index] <= prob)
					DeltaTimes += num2str(index)+";"
				endif
			endfor
			break

		case "PoissonR":
			// Equivalent to a poisson process, but with renewal determined by p2 (ms) where the rate goes to zero
			do
				if(index>length)
					break
				endif
				
				prob = p1 / (SampleRate*1000) // [events/s] / ([sample/ms] * [ms/s]) = [events/sample]
				
				if(RandWave[index] <= prob)
					DeltaTimes += num2str(index)+";"
					count +=1
					index += p2*SampleRate
				else // no event detected check next point
					index+=1
				endif				
			while(1)

			break
			
		case "PoissonRexp":
			variable previousindex=0, tauinsamples=0
			// Equivalent to a poisson process, but with renewal determined by tau = p2 (ms) where the rate goes to zero
			do
				if(index>length)
					break
				endif
				
				prob = p1 / (SampleRate*1000) // [events/s] / ([sample/ms] * [ms/s]) = [events/sample]
				previousindex = str2num(StringFromList(count-1,DeltaTimes))
				tauinsamples = p2 * SampleRate // assuming p2 in ms (whereas p1 is in sec)
				
				if(RandWave[index]<=(prob*(1-exp(-((index-previousindex)/ tauinsamples)))))
					DeltaTimes += num2str(index)+";"
					count +=1
					index += p2*SampleRate
				else // no event detected check next point
					index+=1
				endif		
			while(1)

			break
		
		case "Gamma":
			variable order = ((SampleRate*1000)/p1), jindex=0, CumPnts
			do
				CumPnts += round(gammanoise(order))
				if(CumPnts>length)
					break
				endif
				DeltaTimes += num2str(CumPnts)+";"
				jindex+=1
			while(1)
			
			break
			
		case "Burst":
		
			NVAR p3 = root:DAQ:ProtGen:Current:BURST_p3
			
			do

				tmpPoint = index*((SampleRate*1000)/p1)

				if(tmpPoint>length)
					break
				else

					if(index==0)
						variable burst_init = tmpPoint
					endif
					
					if(tmpPoint<burst_init+(p2 * SampleRate))
						DeltaTimes += num2str(tmpPoint)+";"					
					endif
	
					if(tmpPoint>=burst_init+(p2 * SampleRate)+(p3 * SampleRate))
						burst_init = tmpPoint
						DeltaTimes += num2str(tmpPoint)+";"
					endif
	
				endif
				index+=1			

			while(1)
			
			break

	endswitch
	
	if(plot)
		CORD_DisplayDeltaTimes(DeltaTimes,SampleRate,length)
	endif

	return DeltaTimes

End


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Function CORD_DisplayDeltaTimes(DeltaTimes,SampleRate,Points)
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	string DeltaTimes
	variable SampleRate
	variable Points
	
	variable NumSpikes = ItemsInList(DeltaTimes)
	print "Total spikes: "+num2str(NumSpikes)
	
	Make/O/N=(Points) DeltaWave = 0
	SetScale /P x, 0, (1/SampleRate),"ms",DeltaWave
	string CurrentSpike
	variable index=0
	
	for(index=0;index<NumSpikes;index+=1)
		CurrentSpike = StringFromList(index,DeltaTimes)
		DeltaWave[str2num(CurrentSpike)] = 1
	endfor

	DoWindow/K SpikeTimeDisplay
	Display/K=1 DeltaWave as "Spike Times"
	DoWindow/C SpikeTimeDisplay

End
