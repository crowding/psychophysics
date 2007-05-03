/*
	SCREENBlendEquation.c	
  
	AUTHORS:

		Peter Meilstrup peterm@shadlen.org 
  
	PLATFORMS:	
	
		Only OS X for now.  
    
	HISTORY:

		04/30/07 Wrote it, based on SCREENBlendFunction.c
 
	DESCRIPTION:
	
		Set the GL blending equation using glBlendEquation() for a specific window.
  
*/


#include "Screen.h"

// If you change the useString then also change the corresponding synopsis string in ScreenSynopsis.c
static char useString[] = "[blendEquationOld]=('BlendEquation', windowIndex, [blendEquationNew]);";
//                                                              1             2
static char synopsisString[] = 
	"Set the equation used in alpha blending. If new settings are supplied, 'BlendEquation'  "
	"invokes the OpenGL function glBlendEquation() within the glContext of windowIndex. This "
	"works in conjunction with Screen('BlendFunction') and determines how the source and "
	"destinations colors are combined after the blend factors have been applied. The default "
	"is GL_FUNC_ADD. Other values are GL_FUNC_SUBTRACT, GL_FUNC_REVERSE_SUBTRACT, GL_MIN, "
	"and GL_MAX.";

static char seeAlsoString[] = "DrawDots, DrawLines, DrawTexture, BlendFunction";	 

PsychError SCREENBlendEquation(void)
{
	PsychWindowRecordType 	*windowRecord;
	GLenum					oldEqn, newEqn;
	char					*oldEqnStr, *newEqnStr;
	int						oldEqnStrSize, newEqnStrSize, isStringValid;
	Boolean					isEqnSupplied, isEqnValid;
	
	//all subfunctions should have these two lines.  
	PsychPushHelp(useString, synopsisString, seeAlsoString);
	if(PsychIsGiveHelp()){PsychGiveHelp();return(PsychError_none);};
	
	PsychErrorExit(PsychCapNumInputArgs(2));   //The maximum number of inputs
	PsychErrorExit(PsychRequireNumInputArgs(1));   //The minimum number of inputs
	PsychErrorExit(PsychCapNumOutputArgs(1));  //The maximum number of outputs
	
	//Get the window record or exit with an error if the windex was bogus.
	PsychAllocInWindowRecordArg(kPsychUseDefaultArgPosition, TRUE, &windowRecord);
	
	//Retreive the old source and destination factors and return them from the Screen call as strings
	PsychGetAlphaBlendingEquationFromWindow(windowRecord, &oldEqn); 
	
	oldEqnStrSize=PsychGetAlphaBlendingEquationStringFromConstant(oldEqn, NULL);
	oldEqnStr=(char *)malloc(sizeof(char) * oldEqnStrSize);
	PsychGetAlphaBlendingEquationStringFromConstant(oldEqn, oldEqnStr);
	PsychCopyOutCharArg(1, kPsychArgOptional, oldEqnStr);
	free((void *)oldEqnStr);
	
	//Get the new settings if they are present and set them.
	newEqn=oldEqn;
	isEqnSupplied = PsychAllocInCharArg(2, kPsychArgOptional, &newEqnStr);
	if(isEqnSupplied){
		isEqnValid = PsychGetAlphaBlendingEquationConstantFromString(newEqnStr, &newEqn);
		if(!isEqnValid)
			PsychErrorExitMsg(PsychError_user, "Supplied string argument 'blendEquationNew' is invalid");

		PsychStoreAlphaBlendingEquationForWindow(windowRecord, newEqn);
	}
	
	return(PsychError_none);	
}



