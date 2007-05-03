/*
PsychAlphaBlending.h

PLATFORMS:	

	Only OS X for now.  
			
AUTHORS:
	
	Allen Ingling		awi		Allen.Ingling@nyu.edu
	Peter Meilstrup		pbm		peterm@shadlen.org

HISTORY:
	
	1/7/04		awi		Wrote it 
	5/2/04		pbm		added blend equation
						
DESCRIPTION:

	Functions for getting and setting the alpha blending rule in windows.  To assure consistent treatement of state ONLY functions in this file should
	be used as a gateway to modify Screen state.
	

*/

//include once
#ifndef PSYCH_IS_INCLUDED_PsychAlphaBlending
#define PSYCH_IS_INCLUDED_PsychAlphaBlending

#include "Screen.h"

int PsychGetAlphaBlendingFactorConstantFromString(char *blendString, GLenum *blendConstant);
int PsychGetAlphaBlendingFactorStringFromConstant(GLenum blendConstant, char *blendString);
void PsychInitWindowRecordAlphaBlendingFactors(PsychWindowRecordType *winRec);
Boolean PsychValidateBlendingConstantForSource(GLenum sourceFactor);
Boolean PsychValidateBlendingConstantForDestination(GLenum destinationFactor);
void PsychGetAlphaBlendingFactorsFromWindow(PsychWindowRecordType *winRec, GLenum *oldSource, GLenum *oldDestination);
void PsychStoreAlphaBlendingFactorsForWindow(PsychWindowRecordType *winRec, GLenum sourceBlendConstant, GLenum destinationBlendConstant);
void PsychUpdateAlphaBlendingFactorLazily(PsychWindowRecordType *winRec);

int PsychGetAlphaBlendingEquationFromWindow(PsychWindowRecordType *winRec, GLenum *oldEqn);
int PsychGetAlphaBlendingEquationConstantFromString(char *blendString, GLenum *blendConstant);
int PsychGetAlphaBlendingEquationStringFromConstant(GLenum blendConstant, char *blendString);
int PsychGetAlphaBlendingEquationFromWindow(PsychWindowRecordType *winRec, GLenum *oldEqn);
Boolean PsychValidateBlendEquation(GLenum blendEqn);

//end include once
#endif



