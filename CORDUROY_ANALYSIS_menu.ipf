#pragma rtGlobals=1#include <Waves Average>#include <Power Spectral Density>#include "CORDUROY_ANALYSIS_gui"#include "CORDUROY_ANALYSIS_library"#include "CORDUROY_ANALYSIS_utility"#include "CORDUROY_ANALYSIS_meta"#include "CORDUROY_ANALYSIS_metalib"#include "CORDUROY_ANALYSIS_util_lib"#include "CORDUROY_ANALYSIS_personal"#include "CORDUROY_ANALYSIS_xml"MENU "Corduroy"	"Set a new path", CORD_ChangePath()	"-"	"...Corduroy Analysis..."	"-"	"Launch Analysis/1", DisplayUtilitiesControlPanel()	"'Meta' Analysis panel/2", CORD_DisplayMetaControlPanel()	"Create XML panel/3", CORD_DisplayELN()END