/*
 * pvme (un)pack functions
 *
 * Copyright (c) 1995-1999 University of Rostock, Germany,
 * Institute of Automatic Control. All rights reserved.
 *
 * See file ``Copyright'' for terms of copyright.
 *
 * Authors: S. Pawletta (1995, (u)pkmat* M4)
 *	    A. Westphal (Dec 98, (u)pkarray* M5)
 *	    A. Westphal (Jan 99, change w41 in pvmeupkmatPrPi(M5)
 *          E. Svahn    (Sep 2000, user defined object added in pvmeupkHeadRest)
 *
 */

/* patched by J. Ditterich for compatibility with MATLAB R13 */

#define V5_COMPAT /* V5 compatibility mode */

#include "pvme.h"

#include <pvm3.h>
#include <stdio.h>


#ifndef M4
/****************************************************************
 *								*
 * Packing / Unpacking M5 Arrays				*
 *								*
 ****************************************************************/
/* 
 * properties of matlab's matrix object in the order of (un)packing:
 *
 * int  	Name_Length;    length of matrix name including \0 
 * char 	Name[mxMAXNAM];	matrix name; packed as byte[Name_Length]
 *
 * int  	Precision;	only double is supported and it is checked in
 *				this function; therefore Precision is not trans-
 *				fered and pvme_upkmat() assumes double without 
 *				any check
 *
 * int  	Storage;	0-Full / 1-Sparse by mxIsSparse
 * int  	ComplexFlag;	0-REAL / 1-COMPLEX by mxIsComplex
 * int  	DisplayMode;	0-Numeric / 1-String by mxIsString
 * int  	M;		number of rows
 * int  	N;		number of columns
 *
 * int  	nzmax;		only for Sparse: max possible nonzeros
 * int*		ir;		only for Sparse: row indices for pr
 *				and pi; array of length nzmax
 * int*		jc;		only for Sparse: column index information;
 *				array of length N+1
 * double*	pr;		for Full: M*N Fortran column-order matrix
 *				array (double); the real part
 *				for Sparse: double array of length nzmax
 * double*	pi;		for Full: M*N Fortran column-order matrix
 *				array (double); the imaginary part
 *				for Sparse: double array of length nzmax
 */

static int userobj;
int static pvmepkarrayData(mxArray* pm);
int static pvmepkrecall(mxArray* pm);
int static pvmeupkrecall(mxArray **ppm); /* declaration for recursive usage */

/********************************
 *				*
 * Internal Unpack Functions 	*
 *				*
 ********************************/

static int 
pvmeupkmatHeadName(char *Name)
{
	int	Name_Length;
	int	info;

	/*
	 * unpack Name_Length and Name
	 */

	if ( (info = pvm_upkint(&Name_Length,1,1)) ) {
		printf("pvmeupkmatHeadName(): pvm_upkint() failed "
		       "while unpacking Name_Length.\n");
		return info;
	}
	/*printf("Name_Length: %i unpacked\n",Name_Length);*/


	if ( (info = pvm_upkbyte(Name,Name_Length,1)) ) {
		printf("pvmeupkmatHeadName(): pvm_upkbyte() failed "
		       "while unpacking Name.\n");
		return info;
	}

	/*printf("Name: %s unpacked\n",Name);*/


	return PvmOk;
}

static int 
pvmeupkmatHeadRest(mxArray **ppm, char *Name)
{
	int	ClassId=-1, ComplexFlag=1, ndim=2, *dims;
	/*	int     userobj=0;*/
	char    ClassName[mxMAXNAM];
	int	nzmax;
	int	info;
	int	nfields;
	char	**field_names;
	int	i;


	/* 
	 * unpack ClassId
	 */

	if ( (info = pvm_upkint(&ClassId,1,1)) ) {
		printf("pvmeupkmatHeadRest(): pvm_upkint() failed "
		       "while unpacking ClassId\n");
		return info;
	}

	/*printf("ClassId: %i unpacked. Class info: \n", ClassId);*/

        if ( mxOBJECT_CLASS == (mxClassID) ClassId ) {
	  userobj = 1;
	  if ( (info = pvmeupkmatHeadName(ClassName)) ) {
	    printf("pvme_upkmatHeadRest(): pvmeupkmatClassName() failed.\n");
	    return info;
	  }
	}


	/* 
	 * unpack ComplexFlag for non structures
	 */
	if ( !(( mxCELL_CLASS == (mxClassID) ClassId ) || 
	       ( mxOBJECT_CLASS == (mxClassID) ClassId ) || 
	       ( mxSTRUCT_CLASS == (mxClassID) ClassId )) ) {
		if ( (info = pvm_upkint(&ComplexFlag,1,1)) ) {
			printf("pvmeupkmatHeadRest(): pvm_upkint() failed "
			       "while unpacking ComplexFlag\n");
			return info;
		}

		/*printf("ComplexFlag: %i unpacked.\n", ComplexFlag);*/

	}

	/* 
	 * unpack ndim
	 */

	if ( (info = pvm_upkint(&ndim,1,1)) ) {
		printf("pvmeupkmatHeadRest(): pvm_upkint() failed "
		       "while unpacking ndim\n");
		return info;
	}

	/*printf("ndim: %i unpacked.\n", ndim);*/

	/* 
	 * unpack dims
	 */

	dims = (int*) mxCalloc(ndim,sizeof(int));
	if ( (info = pvm_upkint(dims,ndim,1)) ) {
		printf("pvmeupkmatHeadRest(): pvm_upkint() failed "
		       "while unpacking dims\n");
		return info;
	}
/*
printf("Dimensions: ");
for (i=0; i<ndim; i++)
        printf("%i ",(dims)[i]);
printf("unpacked\n ");
*/

	if ( (mxSTRUCT_CLASS == (mxClassID) ClassId) || (mxOBJECT_CLASS == (mxClassID) ClassId)) { 

		/* 
		 * unpack nfields
		 */

		if ( (info = pvm_upkint(&nfields,1,1)) ) {
			printf("pvmeupkmatHeadRest(): pvm_upkint() failed "
			       "while unpacking nfields.\n");
			return info;
		}

		/*printf("nfields: %i unpacked.\n", nfields);*/

		/* 
		 * unpack field_names
		 */
		field_names = mxCalloc(nfields, sizeof(char*));
		for(i=0; i<nfields; i++) {
			(field_names)[i] = mxCalloc(mxMAXNAM, sizeof(char));
				if ( (info = pvm_upkstr((field_names)[i])) ) {
					printf("pvmeupkmatHeadRest(): pvm_upkstr() failed "
					       "while unpacking field_names.\n");
					return info;
				}

				/*printf("field_names %d: %s\n", i, (field_names)[i]);*/

		}
	}

	if ( mxSPARSE_CLASS == (mxClassID) ClassId ) { 

		/* 
		 * unpack nzmax and create sparse matrix
		 */

		if ( (info = pvm_upkint(&nzmax,1,1)) ) {
			printf("pvmeupkmatHeadRest(): pvm_upkint() failed "
			       "while unpacking nzmax.\n");
			return info;
		}     

		/*printf("nzmax: %i\n",nzmax);*/


		*ppm = mxCreateSparse((dims)[0],(dims)[1],nzmax,ComplexFlag);
		if ( !*ppm ) {
			printf("pvmeupkmatHeadRest(): mxCreateSparse() failed.\n");
			return PvmeErr;
		}
	}
	else if ( !(( mxCELL_CLASS == (mxClassID) ClassId ) || 
		    ( mxOBJECT_CLASS == (mxClassID) ClassId ) ||
		    ( mxSTRUCT_CLASS == (mxClassID) ClassId )) ) {

		/* 
		 * create full matrix (double or char)
		 */

		*ppm = mxCreateNumericArray( ndim, dims, (mxClassID) ClassId, ComplexFlag);
		if ( !*ppm ) {
			printf("pvmeupkmatHeadRest(): mxCreateNumericArray() failed.\n");
			return PvmeErr;
		}
	}
	else if ( mxCELL_CLASS == (mxClassID) ClassId ){

		/* 
		 * create cell array
		 */

		*ppm = mxCreateCellArray(ndim, dims);
		if ( !*ppm ) {
			printf("pvmeupkmatHeadRest(): mxCreateCellArray() failed.\n");
			return PvmeErr;
		}
	}
	else if (( mxSTRUCT_CLASS == (mxClassID) ClassId ) || ( mxOBJECT_CLASS == (mxClassID) ClassId )){

		/* 
		 * create struct array
		 */

		*ppm = mxCreateStructArray(ndim, dims, nfields, (const char**)field_names);
		if ( !*ppm ) {
			printf("pvmeupkmatHeadRest(): mxCreateStructArray() failed.\n");
			return PvmeErr;
		}
		if ( mxOBJECT_CLASS == (mxClassID) ClassId ){
		  if ( mxSetClassName(*ppm, ClassName) ) {
		    printf("pvmeupkmatHeadRest(): mxSetClassName() failed.\n");
		    return PvmeErr;
		  }
		}
	}
	else {
		printf("pvmeupkmatHeadRest(): unimplemented Class\n");
		return (PvmeErr);
	}

	/*
	 * set Name 
	 */

	mxSetName(*ppm,Name);
	
	/*	if (userobj) {
	  return 1; 
	} 
	else {*/
	  return PvmOk;
	  /*	}*/
}

static int 
pvmeupkarrayData(mxArray **ppm, int n)
{
	int	nbr_of_elements;
	const int	*dims;
	int	ndim, nfield;
	int	i, j, info;
	mxArray	*pnm;

	/* get the number of elements */
	nbr_of_elements = mxGetNumberOfElements(*ppm);
	dims = mxGetDimensions(*ppm);
	ndim = mxGetNumberOfDimensions(*ppm);
	if (mxIsStruct(*ppm)) {
		nfield = mxGetNumberOfFields(*ppm);
	}
	/* set the content of each element (array) or each field (struct) */
	for (i=0; i<nbr_of_elements; i++) {
		if (mxIsCell(*ppm)) { /* cell array */
			if ( (info = pvmeupkrecall(&pnm)) ) {
				printf("pvmeupkarrayData(): pvmeupkrecall() "
				       "failed.\n");
				return info;
			}

			/*printf("Class: %s\n",mxGetClassName(pnm));*/

			mxSetCell(*ppm, i, pnm);
		}
		else {	/* structure array */
			for (j=0; j<nfield; j++) {
				if ( (info = pvmeupkrecall(&pnm)) ) {
					printf("pvmeupkarrayData(): pvmeupkrecall()"
					       " failed.\n");
					return info;
				}

				/*printf("Class: %s\n",mxGetClassName(pnm));*/

				mxSetFieldByNumber(*ppm, i, j, pnm);
			}
		}
	}

	return PvmOk;

}


static int 
pvmeupkmatPrPi(mxArray **ppm, int n)
{
	int 	info;
	char	*upkchar;
	mxChar	*trash;
	int	i;

	if (mxIsChar(*ppm)) {
		/* mxChar == 16 bit, we have to unpack n*2 bytes */
		upkchar = mxCalloc(n, sizeof(char));
		trash   = mxCalloc(n, sizeof(mxChar));
        	if ( (info = pvm_upkbyte(upkchar,n,1)) ) {
                	printf("pvmeupkmatPrPi(): pvm_upkbyte() failed "
                       	       "while unpacking pr[].\n");
                	return info;
        	}
		for (i=0;i<n;++i) 
			trash[i]=(mxChar)upkchar[i];
			mxFree(mxGetPr(*ppm));
			mxSetData(*ppm, trash);
		}
	else {
        	if ( (info = pvm_upkdouble(mxGetPr(*ppm),n,1)) ) {
                	printf("pvmeupkmatPrPi(): pvm_upkdouble() failed "
                       	       "while unpacking pr[].\n");
                	return info;
        	}
	}


	if ( mxIsComplex(*ppm) ) {
                if ( (info = pvm_upkdouble(mxGetPi(*ppm),n,1)) ) {
                        printf("pvmeupkmatPrPi(): pvm_upkdouble() failed "
                               "while unpacking pi[].\n");
                        return info;
                }
/*
for (i=0;i<n;++i)
  printf("pi[%i]: %f\n",i,mxGetPi(*ppm)[i]);
*/
        }
   
	return PvmOk;
}


static int 
pvmeupkmatIrJc(mxArray **ppm, int N, int nzmax)
{
	int 	info;

int i;


	if ( (info = pvm_upkint(mxGetIr(*ppm),nzmax,1)) ) {
		printf("pvmeupkmatIrJc(): pvm_upkint() failed "
		       "while unpacking ir[].\n");
		return info;
	}
/*
for (i=0;i<nzmax;++i)
  printf("ir[%i]: %i\n",i,mxGetIr(*ppm)[i]);
*/

	if ( (info = pvm_upkint(mxGetJc(*ppm),N+1,1)) ) {
		printf("pvmeupkmatIrJc(): pvm_upkint() failed "
		       "while unpacking jc[].\n");
		return info;
	}
/*
for (i=0;i<N+1;++i)
  printf("jc[%i]: %i\n",i,mxGetJc(*ppm)[i]);
*/

	return PvmOk;
}


static int 
pvmeupkmatData(mxArray **ppm)
{
	int	N, nzmax, n;
	int	info;


	if ( mxIsSparse(*ppm) ) { 

		N     = mxGetN(*ppm);
		nzmax = mxGetNzmax(*ppm);

		if ( (info = pvmeupkmatIrJc(ppm,N,nzmax)) ) {
			printf("pvmeupkmatData(): pvmeupkmatIrJc() failed.\n");
			return info;
		}

		n = nzmax;
	}
	else {

		n = mxGetNumberOfElements(*ppm);
	}

	if ((mxIsCell(*ppm)) || (mxIsStruct(*ppm))){
		if ( (info = pvmeupkarrayData(ppm,n)) ) {
			printf("pvmeupkmatData(): pvmeupkarrayData() failed.\n");
			return info;
		}
	}
	else {
		if ( (info = pvmeupkmatPrPi(ppm,n)) ) {
			printf("pvmeupkmatData(): pvmeupkmatPrPi() failed.\n");
			return info;
		}
	}

	return PvmOk;
}

int static
pvmeupkrecall(mxArray **ppm)
{
	char	Name[mxMAXNAM];
	int info;

	/*
	 * unpack matrix head
	 */

	if ( (info = pvmeupkmatHeadName(Name)) ) {
		printf("pvmeupkrecall(): pvmeupkmatHeadName() failed.\n");
		return info;
	}

	if ( (info = pvmeupkmatHeadRest(ppm,Name)) ) {
		printf("pvmeupkrecall(): pvmeupkmatHeadRest() failed.\n");
		mxDestroyArray(*ppm);
		*ppm = mxCreateDoubleMatrix(0,0,mxREAL);
		return info;
	}

	/*
	 * unpack matrix data 
	 */

	if ( (info = pvmeupkmatData(ppm)) ) {
		printf("pvme_upkmat(): pvmeupkmatData() failed.\n");
		mxDestroyArray(*ppm);
		*ppm = mxCreateDoubleMatrix(0,0,mxREAL);
		return info;
	}

	return PvmOk;

}


/********************************
 *				*
 * Interface Unpack Functions 	*
 *				*
 ********************************/

int 
pvme_upkarray(mxArray **ppm)
/* 
 *	unpacks an array from the active receive buffer and 
 *	returns it in ppm.
 *	
 *	If pvme_upkarray() failes it returns info less than zero and 
 *	an empty matrix in ppm.
 */
{
	int	info;

	/*
	 * internal function call
	 */

	if ( (info = pvmeupkrecall(ppm)) ) {
		printf("pvme_upkarray(): pvmeupkrecall() failed.\n");
		return info;
	}

	return PvmOk;
}


int 
pvme_upkarray_name(char *Name)
/* 
 *	unpacks the name of an array from the active receive buffer and 
 *	returns it in Name. Memory for Name has to be allocated by the
 *	caller.
 *	
 *	If pvme_upkarray_Name() failes it returns info less than zero.
 */
{
	int	info;

	/*
	 * unpack array name
	 */

	if ( (info = pvmeupkmatHeadName(Name)) ) {
		printf("pvme_upkarrayName(): pvmeupkmatHeadName() failed.\n");
		return info;
	}

	/*printf("pvme_upkarrayName()  OKOKOKOK!d.\n");*/

	return PvmOk;
}


int 
pvme_upkarray_rest(mxArray **ppm, char *Name)
/* 
 *	unpacks a the rest of an array from the active receive buffer 
 *	(the array name has to be already unpacked by pvme_upkarrayName())
 *	and returns it in ppm.
 *	
 *	If pvme_upkarrayRest() failes it returns info less than zero and 
 *	an empty matrix in ppm.
 */
{
	int	info;
	int     userobj;
	/*
	 * unpack rest of array head
	 */
	userobj = PvmOk;

	if ( (info = pvmeupkmatHeadRest(ppm,Name)) ) { 
		printf("pvme_upkarray_rest(): pvmeupkmatHeadRest() failed.\n");
		mxDestroyArray(*ppm);
		*ppm = mxCreateDoubleMatrix(0,0,mxREAL);
		return info;
	}

	/*
	 * unpack array data 
	 */

	if ( (info = pvmeupkmatData(ppm)) ) {
		printf("pvme_upkarray_rest(): pvmeupkmatData() failed.\n");
		mxDestroyArray(*ppm);
		*ppm = mxCreateDoubleMatrix(0,0,mxREAL);
		return info;
	}

	return userobj;
	
}


/********************************
 *				*
 * Internal Pack Functions 	*
 *				*
 ********************************/

static int
pvmepkmatHeadName(mxArray *pm)
{
	int	Name_Length;
	int	info;

	/*
	 * pack Name_Length and Name
	 */

	Name_Length = strlen( mxGetName(pm) ) + 1;
	if ( (info = pvm_pkint(&Name_Length,1,1)) ) {
		printf("pvmepkmatHeadName(): pvm_pkint() failed "
		       "while packing Name_Length.\n");
		return info;
	}

	/*printf("Name_Length: %i packed.\n",Name_Length);*/


	if ( (info = pvm_pkbyte((char*)mxGetName(pm),Name_Length,1)) ) {
		printf("pvmepkmatHeadName(): pvm_pkbyte() failed "
		       "while packing Name.\n");
		return info;
	}

	/*printf("Name: %s packed.\n",mxGetName(pm));*/


	return PvmOk;
}

static int
pvmepkmatHeadRest(mxArray *pm)
{
	int  	ClassId;
	int  	ComplexFlag;
	int  	ndim;
	const int  	*dims; 
	int  	nzmax;
	int	info;
	int	nfields;
	const char	*field_name;
	int	i;

	/* 
	 * check Classname
	 */

	/*printf("Class: %s\n",mxGetClassName(pm));*/

	/* 
	 * pack ClassId
	 */

	ClassId = (int) mxGetClassID(pm);
	if ( (info = pvm_pkint(&ClassId,1,1)) ) {
		printf("pvmepkmatHeadRest(): pvm_pkint() failed "
		       "while packing ClassId.\n");
		return info;
	}

	/*printf("ClassId: %i packed.\n",ClassId);*/

	/*
	 * if user defined class -> pack class name
	 */

        if ( mxOBJECT_CLASS == (mxClassID) ClassId ) {
	  i = strlen( mxGetClassName(pm) ) + 1;
	  if ( (info = pvm_pkint(&i,1,1)) ) {
	    printf("pvmepkmatHeadName(): pvm_pkint() failed "
		   "while packing Class Name_Length.\n");
	    return info;
	  }
	  
	  /*printf("Class Name_Length: %i packed.\n",i);*/
	  
          if ( (info = pvm_pkbyte((char*)mxGetClassName(pm), i, 1)) ) {
	    printf("pvmepkmatHeadRest(): pvm_pkbyte() failed "
		   "while packing Class name.\n");
	    return info;
	  }

	  /*printf("Class name: %s packed.\n",mxGetClassName(pm));*/

	}

	/* 
	 * pack ComplexFlag (for non-structs)
	 */

	if ( !(mxIsStruct(pm) || mxIsCell(pm)) ) {
		ComplexFlag = mxIsComplex(pm);
		if ( (info = pvm_pkint(&ComplexFlag,1,1)) ) {
			printf("pvmepkmatHeadRest(): pvm_pkint() failed while "
			       "packing ComplexFlag.\n");
			return info;
		}
 
		/*printf("ComplexFlag: %i packed.\n",ComplexFlag);*/

	}

	/* 
	 * pack ndim
	 */

	ndim = mxGetNumberOfDimensions(pm);
	if ( (info = pvm_pkint(&ndim,1,1)) ) {
		printf("pvmepkmatHeadRest(): pvm_pkint() failed "
		       "while packing ndim.\n");
		return info;
	}

	/*printf("ndim: %i packed.\n",ndim);*/


	/* 
	 * pack dims
	 */

	dims = mxGetDimensions(pm);
	if ( (info = pvm_pkint( (int*) dims,ndim,1)) ) {
		printf("pvmepkmatHeadRest(): pvm_pkint() failed "
		       "while packing dims.\n");
		return info;
	}
/*
printf("Dimensions: ");
for(info=0; info<ndim; info++)
	printf("%d ", *dims++);
printf("packed\n ");
*/

	if ( mxIsSparse(pm) ) {

		/* 
	 	 * pack nzmax;
	 	 */

		nzmax = mxGetNzmax(pm);
		if ( (info = pvm_pkint(&nzmax,1,1)) ) {
			printf("pvmepkmatHeadRest(): pvm_pkint() failed "
		       	       "while packing nzmax.\n");
			return info;
		}

		/*printf("nzmax: %i packed.\n",nzmax);*/

	}

	if ( mxIsStruct(pm) ){

		/* 
	 	 * pack nfields;
	 	 */

		nfields = mxGetNumberOfFields(pm);
		if ( (info = pvm_pkint(&nfields,1,1)) ) {
			printf("pvmepkmatHeadRest(): pvm_pkint() failed "
		       	       "while packing nfields.\n");
			return info;
		}

		/*printf("nfields: %i packed.\n",nfields);*/

		/* 
	 	 * pack field_names;
	 	 */
		field_name = mxCalloc(mxMAXNAM, sizeof(char));
		for (i=0; i<nfields; i++) {
			field_name = mxGetFieldNameByNumber(pm,i);
			if ( (info = pvm_pkstr((char*)field_name)) ) {
				printf("pvmepkmatHeadRest(): pvm_pkstr() failed "
			       	       "while packing field_names.\n");
				return info;
			}

			/*printf("field_name%i: %s packed.\n", i+1, field_name);*/

		}

	}
	return PvmOk;
}


int static
pvmepkmatPrPi(mxArray* pm, int n)
{
	int	info;
	char	*pkchar, *buf;
	int	i;


	if (mxIsChar(pm)) {
		/* mxChar == 16 bit, we have to pack n*2 bytes */
		buf    = mxGetData(pm);
		pkchar = mxCalloc(n, sizeof(char));
		for (i=0; i<n; ++i){
			if ((int)buf[2*i] != 0) {
				pkchar[i] = buf[2*i];
			}
			else {
				pkchar[i] = buf[2*i+1];
			}
		} 

		if ( (info = pvm_pkbyte(pkchar,n,1)) ) {
			printf("pvmepkmatPrPi(): pvm_pkint() failed "
			       "while packing pr[].\n");
			return info;
		}
	}
	else {
		if ( (info = pvm_pkdouble(mxGetPr(pm),n,1)) ) {
			printf("pvmepkmatPrPi(): pvm_pkdouble() failed "
			       "while packing pr[].\n");
			return info;
		}
	}
/*
for (i=0;i<n;++i)
  printf("pr[%i]: %f\n",i,mxGetPr(pm)[i]);
*/

	if ( mxIsComplex(pm) ) {
		if ( (info = pvm_pkdouble(mxGetPi(pm),n,1)) ) {
			printf("pvmepkmatPrPi(): pvm_pkdouble() failed "
			       "while packing pi[].\n");
			return info;
		}
/*
for (i=0;i<n;++i)
  printf("pi[%i]: %f\n",i,mxGetPi(pm)[i]);
*/
	}

	return PvmOk;
}


int static
pvmepkmatIrJc(mxArray* pm, int N, int nzmax)
{
	int	info;
/*
int i;
*/
	if ( (info = pvm_pkint(mxGetIr(pm),nzmax,1)) ) {
		printf("pvmepkmatIrJc(): pvm_pkint() failed while "
		       "packing ir[].\n");
		return info;
	}
/*
for (i=0;i<nzmax;++i)
  printf("ir[%i]: %i\n",i,mxGetIr(pm)[i]);
*/

	if ( (info = pvm_pkint(mxGetJc(pm),N+1,1)) ) {
		printf("pvmepkmatIrJc(): pvm_pkint() failed while "
		       "packing jc[].\n");
		return info;
	}
/*
for (i=0;i<N+1;++i) 
  printf("jc[%i]: %i\n",i,mxGetJc(pm)[i]);
*/

	return PvmOk;
}


int static
pvmepkmatData(mxArray* pm)
{
	int  	N, nzmax, n;
	int	info;

	if (mxIsStruct(pm) || mxIsCell(pm)) {
		/*
		 * pack array data
		 */

		if ( (info = pvmepkarrayData(pm)) ) {
			printf("pvme_pkmat(): pvmepkarrayData() failed.\n");
			return info;
		}

	return PvmOk;
	}

	if ( mxIsSparse(pm) ) { 

		N     = mxGetN(pm);
		nzmax = mxGetNzmax(pm);

		if ( (info = pvmepkmatIrJc(pm,N,nzmax)) ) {
			printf("pvmepkmatData(): pvmepkmatIrJc() failed\n");
			return info;
		}

		n = nzmax;
	}
	else {

		n = mxGetNumberOfElements(pm);
	}
		if ( (info = pvmepkmatPrPi(pm,n)) ) {
			printf("pvmepkmatData(): pvmepkmatPrPi() failed\n");
			return info;
		}

	return PvmOk;
}

int static 
pvmepkarrayData(mxArray* pm)
{
	int	nbr_of_elements;
	const int	*dims;
	int	ndim, nfield;
	int	i, j, info;
	mxArray	*pnm;

	/* get the number of elements */
	nbr_of_elements = mxGetNumberOfElements(pm);
	dims = mxGetDimensions(pm);
	ndim = mxGetNumberOfDimensions(pm);
	if (mxIsStruct(pm)) {
		nfield = mxGetNumberOfFields(pm);
	}

	/* get the content of each element (array) and each field (struct) */
	for (i=0; i<nbr_of_elements; i++) {
		if (mxIsCell(pm)) { /* cell array */
			pnm = mxGetCell(pm, i);

			/*printf("Class: %s\n",mxGetClassName(pnm));*/

			if ( (info = pvmepkrecall(pnm)) ) {
				printf("pvmepkarrayData(): pvmepkrecall() "
				       "failed.\n");
				return info;
			}
		}
		else {	/* structure array */
			for (j=0; j<nfield; j++) {
				pnm = mxGetFieldByNumber(pm, i, j);

				/*printf("Class: %s\n",mxGetClassName(pnm));*/

				if ( (info = pvmepkrecall(pnm)) ) {
					printf("pvmepkarrayData(): "
					       "pvmepkrecall() failed.\n");
					return info;
				}
			}
		}
	}

	return PvmOk;
}

int static
pvmepkrecall(mxArray* pm)
{
	int info;

	/*
	 * pack matrix head
	 */

	if ( (info = pvmepkmatHeadName(pm)) ) {
		printf("pvme_pkmat(): pvmepkmatHeadName() failed.\n");
		return info;
	}

	if ( (info = pvmepkmatHeadRest(pm)) ) {
		printf("pvme_pkmat(): pvmepkmatHeadRest() failed.\n");
		return info;
	}

		/*
		 * pack matrix data
		 */

		if ( (info = pvmepkmatData(pm)) ) {
			printf("pvme_pkmat(): pvmepkmatData() failed.\n");
			return info;
		}

	return PvmOk;
}
/********************************
 *				*
 * Interface Pack Functions 	*
 *				*
 ********************************/

int 
pvme_pkarray(mxArray* pm)
/* 
 *	packs the array pointed by pm into the active send buffer.
 *	
 *	pvme_pkmat must *NOT* be used in conjunction with PvmDataInPlace
 *	encoding.
 *
 *	If pvme_pkmat() failes it returns info less than zero.
 *
 */
{
	int	info;
	int	ClassId;

	/*
	 * check class
	 */
	ClassId = (int) mxGetClassID(pm);
	if (((ClassId >= 7) && (ClassId <= 15))){
		printf("pvme_pkarray: class %s not implemented yet.",mxGetClassName(pm));
		return (PvmeErr);
	}
	if (ClassId == -1){
		printf("pvme_pkarray: %s",mxGetClassName(pm));
		return (PvmeErr);
	}


	/*
	 * internal function call
	 */

	if ( (info = pvmepkrecall(pm)) ) {
		printf("pvme_pkarray(): pvmepkrecall() failed.\n");
		return info;
	}

	return PvmOk;
}






#else /* M4 */






/****************************************************************
 *								*
 * Packing / Unpacking M4 Matrices				*
 *								*
 ****************************************************************/
/* 
 * properties of matlab's matrix object in the order of (un)packing:
 *
 * int  	Name_Length;    length of matrix name including \0 
 * char 	Name[mxMAXNAM];	matrix name; packed as byte[Name_Length]
 *
 * int  	Precision;	only double is supported and it is checked in
 *				this function; therefore Precision is not trans-
 *				fered and pvme_upkmat() assumes double without 
 *				any check
 *
 * int  	Storage;	0-Full / 1-Sparse by mxIsSparse
 * int  	ComplexFlag;	0-REAL / 1-COMPLEX by mxIsComplex
 * int  	DisplayMode;	0-Numeric / 1-String by mxIsString
 * int  	M;		number of rows
 * int  	N;		number of columns
 *
 * int  	nzmax;		only for Sparse: max possible nonzeros
 * int*		ir;		only for Sparse: row indices for pr
 *				and pi; array of length nzmax
 * int*		jc;		only for Sparse: column index information;
 *				array of length N+1
 * double*	pr;		for Full: M*N Fortran column-order matrix
 *				array (double); the real part
 *				for Sparse: double array of length nzmax
 * double*	pi;		for Full: M*N Fortran column-order matrix
 *				array (double); the imaginary part
 *				for Sparse: double array of length nzmax
 */


/********************************
 *				*
 * Internal Unpack Functions 	*
 *				*
 ********************************/

static int 
pvmeupkmatHeadName(char *Name)
{
	int	Name_Length;
	int	info;

	/*
	 * unpack Name_Length and Name
	 */

	if ( (info = pvm_upkint(&Name_Length,1,1)) ) {
		printf("pvmeupkmatHeadName(): pvm_upkint() failed "
		       "while unpacking Name_Length.\n");
		return info;
	}
/*
printf("Name_Length: %i\n",Name_Length);
*/

	if ( (info = pvm_upkbyte(Name,Name_Length,1)) ) {
		printf("pvmeupkmatHeadName(): pvm_upkbyte() failed "
		       "while unpacking Name.\n");
		return info;
	}
/*
printf("Name: %s\n",Name);
*/

	return PvmOk;
}


static int 
pvmeupkmatHeadRest(Matrix **ppm, char *Name)
{
	int	Storage=0, ComplexFlag=1, DisplayMode=2, M=3, N=4;
	int	scdmn[5];
	int	nzmax;
	int	info;

	/* 
	 * unpack Storage, ComplexFlag, DisplayMode, M and N
	 */

	if ( (info = pvm_upkint(scdmn,5,1)) ) {
		printf("pvmeupkmatHeadRest(): pvm_upkint() failed "
		       "while unpacking Storage, ComplexFlag, DisplayMode, "
		       "M and N.\n");
		return info;
	}
/*
printf("Storage: %i\n"	  ,scdmn[Storage]);
printf("ComplexFlag: %i\n",scdmn[ComplexFlag]);
printf("DisplayMode: %i\n",scdmn[DisplayMode]);
printf("M: %i\n"	  ,scdmn[M]);
printf("N: %i\n"	  ,scdmn[N]);
*/


	if ( scdmn[Storage] ) { 

		/* 
		 * unpack nzmax and create sparse matrix
		 */

		if ( (info = pvm_upkint(&nzmax,1,1)) ) {
			printf("pvmeupkmatHeadRest(): pvm_upkint() failed "
			       "while unpacking nzmax.\n");
			return info;
		}     
/*
printf("nzmax: %i\n",nzmax);
*/

		*ppm = mxCreateSparse(scdmn[M],scdmn[N],nzmax,scdmn[ComplexFlag]);
		if ( !*ppm ) {
			printf("pvmeupkmatHeadRest(): mxCreateSparse() failed.\n");
			return PvmeErr;
		}
	}
	else {

		/* 
		 * create full matrix
		 */

		*ppm = mxCreateFull(scdmn[M],scdmn[N],scdmn[ComplexFlag]);
		if ( !*ppm ) {
			printf("pvmeupkmatHeadRest(): mxCreateFull() failed.\n");
			return PvmeErr;
		}
	}

	/*
	 * set Name and DisplayMode
	 */

	mxSetName(*ppm,Name);

	if ( scdmn[DisplayMode] ) {
		mxSetString(*ppm);
	}


	return PvmOk;
}


static int 
pvmeupkmatPrPi(Matrix **ppm, int n)
{
	int 	info;
/*
int i;
*/
        if ( (info = pvm_upkdouble(mxGetPr(*ppm),n,1)) ) {
                printf("pvmeupkmatPrPi(): pvm_upkdouble() failed "
                       "while unpacking pr[].\n");
                return info;
        }
/*
for (i=0;i<n;++i)
  printf("pr[%i]: %f\n",i,mxGetPr(*ppm)[i]);
*/

	if ( mxIsComplex(*ppm) ) {
                if ( (info = pvm_upkdouble(mxGetPi(*ppm),n,1)) ) {
                        printf("pvmeupkmatPrPi(): pvm_upkdouble() failed "
                               "while unpacking pi[].\n");
                        return info;
                }
/*
for (i=0;i<n;++i)
  printf("pi[%i]: %f\n",i,mxGetPi(*ppm)[i]);
*/
        }
   
	return PvmOk;
}


static int 
pvmeupkmatIrJc(Matrix **ppm, int N, int nzmax)
{
	int 	info;
/*
int i;
*/

	if ( (info = pvm_upkint(mxGetIr(*ppm),nzmax,1)) ) {
		printf("pvmeupkmatIrJc(): pvm_upkint() failed "
		       "while unpacking ir[].\n");
		return info;
	}
/*
for (i=0;i<nzmax;++i)
  printf("ir[%i]: %i\n",i,mxGetIr(*ppm)[i]);
*/

	if ( (info = pvm_upkint(mxGetJc(*ppm),N+1,1)) ) {
		printf("pvmeupkmatIrJc(): pvm_upkint() failed "
		       "while unpacking jc[].\n");
		return info;
	}
/*
for (i=0;i<N+1;++i)
  printf("jc[%i]: %i\n",i,mxGetJc(*ppm)[i]);
*/

	return PvmOk;
}


static int 
pvmeupkmatData(Matrix **ppm)
{
	int	N, nzmax, n;
	int	info;

	if ( mxIsSparse(*ppm) ) { 

		N     = mxGetN(*ppm);
		nzmax = mxGetNzmax(*ppm);

		if ( (info = pvmeupkmatIrJc(ppm,N,nzmax)) ) {
			printf("pvmeupkmatData(): pvmeupkmatIrJc() failed.\n");
			return info;
		}

		n = nzmax;
	}
	else {

		n = mxGetM(*ppm) * mxGetN(*ppm);
	}

	if ( (info = pvmeupkmatPrPi(ppm,n)) ) {
		printf("pvmeupkmatData(): pvmeupkmatPrPi() failed.\n");
		return info;
	}

	return PvmOk;
}


/********************************
 *				*
 * Interface Unpack Functions 	*
 *				*
 ********************************/

int 
pvme_upkmat(Matrix **ppm)
/* 
 *	unpacks a matrix from the active receive buffer and 
 *	returns it in ppm.
 *	
 *	If pvme_upkmat() failes it returns info less than zero and 
 *	an empty matrix in ppm.
 */
{
	char	Name[mxMAXNAM];
	int	info;

	/*
	 * unpack matrix head
	 */

	if ( (info = pvmeupkmatHeadName(Name)) ) {
		printf("pvme_upkmat(): pvmeupkmatHeadName() failed.\n");
		return info;
	}

	if ( (info = pvmeupkmatHeadRest(ppm,Name)) ) {  
		printf("pvme_upkmat(): pvmeupkmatHeadRest() failed.\n");
		mxFreeMatrix(*ppm);
		*ppm = mxCreateFull(0,0,REAL);
		return info;
	}

	/*
	 * unpack matrix data 
	 */

	if ( (info = pvmeupkmatData(ppm)) ) {
		printf("pvme_upkmat(): pvmeupkmatData() failed.\n");
		mxFreeMatrix(*ppm);
		*ppm = mxCreateFull(0,0,REAL);
		return info;
	}

	return PvmOk;
}


int 
pvme_upkmat_name(char *Name)
/* 
 *	unpacks the name of a matrix from the active receive buffer and 
 *	returns it in Name. Memory for Name has to be allocated by the
 *	caller.
 *	
 *	If pvme_upkmat_Name() failes it returns info less than zero.
 */
{
	int	info;

	/*
	 * unpack matrix name
	 */

	if ( (info = pvmeupkmatHeadName(Name)) ) {
		printf("pvme_upkmatName(): pvmeupkmatHeadName() failed.\n");
		return info;
	}

	return PvmOk;
}


int 
pvme_upkmat_rest(Matrix **ppm, char *Name)
/* 
 *	unpacks a the rest of a matrix from the active receive buffer 
 *	(the matrix name has to be already unpacked by pvme_upkmatName())
 *	and returns it in ppm.
 *	
 *	If pvme_upkmatRest() failes it returns info less than zero and 
 *	an empty matrix in ppm.
 */
{
	int	info;

	/*
	 * unpack rest of matrix head
	 */

	if ( (info = pvmeupkmatHeadRest(ppm,Name)) ) { 
		printf("pvme_upkmat(): pvmeupkmatHeadRest() failed.\n");
		mxFreeMatrix(*ppm);
		*ppm = mxCreateFull(0,0,REAL);
		return info;
	}

	/*
	 * unpack matrix data 
	 */

	if ( (info = pvmeupkmatData(ppm)) ) {
		printf("pvme_upkmat(): pvmeupkmatData() failed.\n");
		mxFreeMatrix(*ppm);
		*ppm = mxCreateFull(0,0,REAL);
		return info;
	}

	return PvmOk;
}


/********************************
 *				*
 * Internal Pack Functions 	*
 *				*
 ********************************/

static int
pvmepkmatHeadName(Matrix *pm)
{
	int	Name_Length;
	int	info;

	/*
	 * pack Name_Length and Name
	 */

	Name_Length = strlen( mxGetName(pm) ) + 1;
	if ( (info = pvm_pkint(&Name_Length,1,1)) ) {
		printf("pvmepkmatHeadName(): pvm_pkint() failed "
		       "while packing Name_Length.\n");
		return info;
	}
/*
printf("Name_Length: %i packed.\n",Name_Length);
*/

	if ( (info = pvm_pkbyte((char*)mxGetName(pm),Name_Length,1)) ) {
		printf("pvmepkmatHeadName(): pvm_pkbyte() failed "
		       "while packing Name.\n");
		return info;
	}
/*
printf("Name: %s packed.\n",mxGetName(pm));
*/

	return PvmOk;
}


static int
pvmepkmatHeadName_bypass(char *Name)
{
	int	Name_Length;
	int	info;

	/*
	 * pack Name_Length and Name
	 */

	Name_Length = strlen(Name) + 1;
	if ( (info = pvm_pkint(&Name_Length,1,1)) ) {
		printf("pvmepkmatHeadName_bypass(): pvm_pkint() failed "
		       "while packing Name_Length.\n");
		return info;
	}
/*
printf("Name_Length: %i packed.\n",Name_Length);
*/

	if ( (info = pvm_pkbyte((char*)Name,Name_Length,1)) ) {
		printf("pvmepkmatHeadName_bypass(): pvm_pkbyte() failed "
		       "while packing Name.\n");
		return info;
	}
/*
printf("Name: %s packed.\n",Name);
*/

	return PvmOk;
}


static int
pvmepkmatHeadRest(Matrix *pm)
{
	int  	Storage;
	int  	ComplexFlag;
	int  	DisplayMode;
	int  	M,N;
	int  	nzmax;
	int	info;

	/* 
	 * check Precision
	 */

	if ( ! mxIsDouble(pm) ) {
		printf("pvmepkmatHeadRest(): Precision other than DOUBLE. "
		       "Not supported.\n");
		return PvmeErr;
	}
/*
printf("Precision checked: is double.\n");
*/

	/* 
	 * pack Storage
	 */

	Storage = mxIsSparse(pm);
	if ( (info = pvm_pkint(&Storage,1,1)) ) {
		printf("pvmepkmatHeadRest(): pvm_pkint() failed "
		       "while packing Storage.\n");
		return info;
	}
/*
printf("Storage: %i packed.\n",Storage);
*/

	/* 
	 * pack ComplexFlag
	 */

	ComplexFlag = mxIsComplex(pm);
	if ( (info = pvm_pkint(&ComplexFlag,1,1)) ) {
		printf("pvmepkmatHeadRest(): pvm_pkint() failed while "
		       "packing ComplexFlag.\n");
		return info;
	}
/*
printf("ComplexFlag: %i packed.\n",ComplexFlag);
*/

	/* 
	 * pack DisplayMode
	 */

	DisplayMode = mxIsString(pm);
	if ( (info = pvm_pkint(&DisplayMode,1,1)) ) {
		printf("pvmepkmatHeadRest(): pvm_pkint() failed "
		       "while packing DisplayMode.\n");
		return info;
	}
/*
printf("DisplayMode: %i packed.\n",DisplayMode);
*/

	/* 
	 * pack M and N
	 */

	M = mxGetM(pm);
	if ( (info = pvm_pkint(&M,1,1)) ) {
		printf("pvmepkmatHeadRest(): pvm_pkint() failed "
		       "while packing M.\n");
		return info;
	}
/*
printf("M: %i packed.\n",M);
*/

	N = mxGetN(pm);
	if ( (info = pvm_pkint(&N,1,1)) ) {
		printf("pvmepkmatHeadRest(): pvm_pkint() failed "
		       "while packing N.\n");
		return info;
	}
/*
printf("N: %i packed.\n",N);
*/


	if ( mxIsSparse(pm) ) {

		/* 
	 	 * pack nzmax;
	 	 */

		nzmax = mxGetNzmax(pm);
		if ( (info = pvm_pkint(&nzmax,1,1)) ) {
			printf("pvmepkmatHeadRest(): pvm_pkint() failed "
		       	       "while packing nzmax.\n");
			return info;
		}
/*
printf("nzmax: %i packed.\n",nzmax);
*/
	}

	return PvmOk;
}


int static
pvmepkmatPrPi(Matrix* pm, int n) 
{
	int	info;
/*
int i;
*/

	if ( (info = pvm_pkdouble(mxGetPr(pm),n,1)) ) {
		printf("pvmepkmatPrPi(): pvm_pkdouble() failed "
		       "while packing pr[].\n");
		return info;
	}
/*
for (i=0;i<n;++i)
  printf("pr[%i]: %f\n",i,mxGetPr(pm)[i]);
*/

	if ( mxIsComplex(pm) ) {
		if ( (info = pvm_pkdouble(mxGetPi(pm),n,1)) ) {
			printf("pvmepkmatPrPi(): pvm_pkdouble() failed "
			       "while packing pi[].\n");
			return info;
		}
/*
for (i=0;i<n;++i)
  printf("pi[%i]: %f\n",i,mxGetPi(pm)[i]);
*/
	}

	return PvmOk;
}


int static
pvmepkmatIrJc(Matrix* pm, int N, int nzmax) 
{
	int	info;
/*
int i;
*/
	if ( (info = pvm_pkint(mxGetIr(pm),nzmax,1)) ) {
		printf("pvmepkmatIrJc(): pvm_pkint() failed while "
		       "packing ir[].\n");
		return info;
	}
/*
for (i=0;i<nzmax;++i)
  printf("ir[%i]: %i\n",i,mxGetIr(pm)[i]);
*/

	if ( (info = pvm_pkint(mxGetJc(pm),N+1,1)) ) {
		printf("pvmepkmatIrJc(): pvm_pkint() failed while "
		       "packing jc[].\n");
		return info;
	}
/*
for (i=0;i<N+1;++i) 
  printf("jc[%i]: %i\n",i,mxGetJc(pm)[i]);
*/

	return PvmOk;
}


int static
pvmepkmatData(Matrix* pm) 
{
	int  	N, nzmax, n;
	int	info;

	if ( mxIsSparse(pm) ) { 

		N     = mxGetN(pm);
		nzmax = mxGetNzmax(pm);

		if ( (info = pvmepkmatIrJc(pm,N,nzmax)) ) {
			printf("pvmepkmatData(): pvmepkmatIrJc() failed\n");
			return info;
		}

		n = nzmax;
	}
	else {

		n = mxGetM(pm) * mxGetN(pm);
	}

	if ( (info = pvmepkmatPrPi(pm,n)) ) {
		printf("pvmepkmatData(): pvmepkmatPrPi() failed\n");
		return info;
	}

	return PvmOk;
}


/********************************
 *				*
 * Interface Pack Functions 	*
 *				*
 ********************************/

int 
pvme_pkmat(Matrix* pm) 
/* 
 *	packs the matrix pointed by pm into the active send buffer.
 *	
 *	pvme_pkmat must *NOT* be used in conjunction with PvmDataInPlace
 *	encoding.
 *
 *	If pvme_pkmat() failes it returns info less than zero.
 *
 *	ATTENTION: Due to a bug in Matlab's mxSetName() routine 
 *	(M4.2c for LNX86 crashes when we want to write an empty 
 *	string with mxSetName() ), pvme_pkmat() can't be used
 *	in dynamical linkage with Matlab.
 *	For that purpose pvme_pkmat_bypass() is provided.
 */
{
	int	info;

	/*
	 * pack matrix head
	 */

	if ( (info = pvmepkmatHeadName(pm)) ) {
		printf("pvme_pkmat(): pvmepkmatHeadName() failed.\n");
		return info;
	}

	if ( (info = pvmepkmatHeadRest(pm)) ) {
		printf("pvme_pkmat(): pvmepkmatHeadRest() failed.\n");
		return info;
	}

	/*
	 * pack matrix data
	 */

	if ( (info = pvmepkmatData(pm)) ) {
		printf("pvme_pkmat(): pvmepkmatData() failed.\n");
		return info;
	}

	return PvmOk;
}


int 
pvme_pkmat_bypass(Matrix* pm, char* Name) 
/* 
 *	packs the matrix pointed by pm into the active send buffer.
 *	Instead of pm's name, Name is packed.
 *
 *	For further explanation see pvm_pkmat().
 */
{
	int	info;

	/*
	 * pack matrix head
	 */

	if ( (info = pvmepkmatHeadName_bypass(Name)) ) {
		printf("pvme_pkmat_bypass(): pvmepkmatHeadName_bypass() failed.\n");
		return info;
	}

	if ( (info = pvmepkmatHeadRest(pm)) ) {
		printf("pvme_pkmat_bypass(): pvmepkmatHeadRest() failed.\n");
		return info;
	}

	/*
	 * pack matrix data
	 */

	if ( (info = pvmepkmatData(pm)) ) {
		printf("pvme_pkmat_bypass(): pvmepkmatData() failed.\n");
		return info;
	}

	return PvmOk;
}



#endif
