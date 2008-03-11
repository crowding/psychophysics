#include "mex.h"
#include <pvm3.h>

/* [numt,tid]=pvm_spawn(task,argv,flag,where,ntask) */
void m2pvm_spawn(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    char *task,**argv,*where;
    int flag,ntask,*tids,numt,i,buflen,nargv;
    mxArray *tmp;
    double *pr;

    buflen=mxGetNumberOfElements(prhs[0])+1;
    task=(char *)mxCalloc(buflen,sizeof(char));
    mxGetString(prhs[0],task,buflen);
#ifdef DEBUG
    mexPrintf("buflen:%d task:%s\n",buflen,task);
#endif

    nargv=mxGetNumberOfElements(prhs[1])+1;
    argv=(char **)mxCalloc(nargv,sizeof(char *));
    for (i=0;i<nargv-1;i++){
	tmp=mxGetCell(prhs[1],i);
	buflen=mxGetNumberOfElements(tmp)+1;
	argv[i]=(char *)mxCalloc(buflen,sizeof(char));
	mxGetString(tmp,argv[i],buflen);
    }
    argv[nargv-1]=NULL;
#ifdef DEBUG
    for (i=0;i<nargv;i++)
	mexPrintf("argv[%d]:%s\n",i,argv[i]);
#endif

    flag=mxGetScalar(prhs[2]);
#ifdef DEBUG
    mexPrintf("flag:%d\n",flag);
#endif

    buflen=mxGetNumberOfElements(prhs[3])+1;
    where=(char *)mxCalloc(buflen,sizeof(char));
    mxGetString(prhs[3],where,buflen);
#ifdef DEBUG
    mexPrintf("buflen:%d where:%s\n",buflen,where);
#endif

    ntask=mxGetScalar(prhs[4]);
#ifdef DEBUG
    mexPrintf("ntask:%d\n",ntask);
#endif

    tids=(int *)mxCalloc(ntask,sizeof(int));

    numt=pvm_spawn(task,argv,flag,where,ntask,tids);

    plhs[0]=mxCreateDoubleScalar(numt);
    
    plhs[1]=mxCreateDoubleMatrix(ntask,1,mxREAL);
    pr=mxGetPr(plhs[1]);
    for (i=0;i<ntask;i++){
	*pr=(double)tids[i];
	pr++;
    }
}

/* info=pvm_kill(tid) */
void m2pvm_kill(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int info,tid;

    tid=mxGetScalar(prhs[0]);
#ifdef DEBUG
    mexPrintf("tid:%d\n",tid);
#endif

    info=pvm_kill(tid);
    
    plhs[0]=mxCreateDoubleScalar(info);
}

/* info=pvm_exit */
void m2pvm_exit(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int info;

    info=pvm_exit();
    
    plhs[0]=mxCreateDoubleScalar(info);
}

/* tid=pvm_mytid */
void m2pvm_mytid(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int tid;
    
    tid=pvm_mytid();
    
    plhs[0]=mxCreateDoubleScalar(tid);
}

/* tid=pvm_parent */
void m2pvm_parent(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int tid;

    tid=pvm_parent();
    
    plhs[0]=mxCreateDoubleScalar(tid);
}

/* info=pvm_initsend(encoding) */
void m2pvm_initsend(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int encoding,bufid;

    encoding=(int)mxGetScalar(prhs[0]);
#ifdef DEBUG
    mexPrintf("encoding:%d\n",encoding);
#endif

    bufid=pvm_initsend(encoding);
    
    plhs[0]=mxCreateDoubleScalar(bufid);
}

/* info=pvm_pkbyte(array,stride) */
void m2pvm_pkbyte(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    char *xp;
    int nitem,stride,i,info;
    double *pr;

    nitem=mxGetNumberOfElements(prhs[0]);
    xp=(char *)mxCalloc(nitem,sizeof(char));
    pr=mxGetPr(prhs[0]);
    for (i=0;i<nitem;i++){
        xp[i]=(char)(*pr);
        pr++;
#ifdef DEBUG
        mexPrintf("xp[%d]:%d\n",i,xp[i]);
#endif
    }
    stride=mxGetScalar(prhs[1]);
#ifdef DEBUG
    mexPrintf("stride:%d\n",stride);
#endif

    info=pvm_pkbyte(xp,nitem,stride);
    
    plhs[0]=mxCreateDoubleScalar(info);
}

/* [info,array]=pvm_upkbyte(nitem,stride) */
void m2pvm_upkbyte(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int nitem,i,info,stride;
    double *pr;
    char *xp;

    nitem=mxGetScalar(prhs[0]);
    stride=mxGetScalar(prhs[1]);
#ifdef DEBUG
    mexPrintf("nitem:%d stride:%d\n",nitem,stride);
#endif
    xp=(char *)mxCalloc(nitem,sizeof(char));

    info=pvm_upkbyte(xp,nitem,stride);

    plhs[0]=mxCreateDoubleScalar(info);

    plhs[1]=mxCreateDoubleMatrix(nitem,1,mxREAL);
    pr=mxGetPr(plhs[1]);
    for (i=0;i<nitem;i++){
        *pr=(double)xp[i];
        pr++;
    }
}

/* info=pvm_pkint(array,stride) */
void m2pvm_pkint(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int *ip,nitem,stride,i,info;
    double *pr;

    nitem=mxGetNumberOfElements(prhs[0]);
    ip=(int *)mxCalloc(nitem,sizeof(int));
    pr=mxGetPr(prhs[0]);
    for (i=0;i<nitem;i++){
        ip[i]=(int)pr[i];
#ifdef DEBUG
        mexPrintf("ip[%d]:%d\n",i,ip[i]);
#endif
    }
    stride=mxGetScalar(prhs[1]);
#ifdef DEBUG
    mexPrintf("stride:%d\n",stride);
#endif

    info=pvm_pkint(ip,nitem,stride);

    plhs[0]=mxCreateDoubleScalar(info);
}

/* [info,array]=pvm_upkint(nitem,stride) */
void m2pvm_upkint(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int nitem,i,info,stride,*ip;
    double *pr;

    nitem=mxGetScalar(prhs[0]);
    stride=mxGetScalar(prhs[1]);
#ifdef DEBUG
    mexPrintf("nitem:%d stride:%d\n",nitem,stride);
#endif
    ip=(int *)mxCalloc(nitem,sizeof(int));

    info=pvm_upkint(ip,nitem,stride);

    plhs[0]=mxCreateDoubleScalar(info);

    plhs[1]=mxCreateDoubleMatrix(nitem,1,mxREAL);
    pr=mxGetPr(plhs[1]);
    for (i=0;i<nitem;i++)
        pr[i]=(double)ip[i];
}

/* info=pvm_pkdouble(array,stride) */
void m2pvm_pkdouble(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int nitem,stride,i,info;
    double *pr;

    nitem=mxGetNumberOfElements(prhs[0]);
    stride=mxGetScalar(prhs[1]);
#ifdef DEBUG
    mexPrintf("nitem:%d stride:%d\n",nitem,stride);
#endif
    pr=mxGetPr(prhs[0]);

    info=pvm_pkdouble(pr,nitem,stride);

    plhs[0]=mxCreateDoubleScalar(info);
}

/* [info,array]=pvm_upkdouble(nitem,stride) */
void m2pvm_upkdouble(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int nitem,info,stride;
    double *pr;

    nitem=mxGetScalar(prhs[0]);
    stride=mxGetScalar(prhs[1]);
#ifdef DEBUG
    mexPrintf("nitem:%d stride:%d\n",nitem,stride);
#endif

    plhs[1]=mxCreateDoubleMatrix(nitem,1,mxREAL);
    pr=mxGetPr(plhs[1]);

    info=pvm_upkdouble(pr,nitem,stride);

    plhs[0]=mxCreateDoubleScalar(info);
}

/* info=pvm_send(tid,msgtag) */
void m2pvm_send(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int info,tid,msgtag;

    tid=mxGetScalar(prhs[0]);
    msgtag=mxGetScalar(prhs[1]);
#ifdef DEBUG
    mexPrintf("tid:%d msgtag:%d\n",tid,msgtag);
#endif

    info=pvm_send(tid,msgtag);
    
    plhs[0]=mxCreateDoubleScalar(info);
}

/* bufid=pvm_recv(tid,msgtag) */
void m2pvm_recv(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int bufid,tid,msgtag;

    tid=mxGetScalar(prhs[0]);
    msgtag=mxGetScalar(prhs[1]);
#ifdef DEBUG
    mexPrintf("tid:%d msgtag:%d\n",tid,msgtag);
#endif

    bufid=pvm_recv(tid,msgtag);
    
    plhs[0]=mxCreateDoubleScalar(bufid);
}

void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[]){
    int opcode;

    opcode=mxGetScalar(prhs[0]);
    nrhs--;
    prhs++;

    switch(opcode){
	case 300: m2pvm_spawn(nlhs,plhs,nrhs,prhs);break;
	case 304: m2pvm_kill(nlhs,plhs,nrhs,prhs);break;
	case 305: m2pvm_exit(nlhs,plhs,nrhs,prhs);break;
	case 400: m2pvm_mytid(nlhs,plhs,nrhs,prhs);break;
	case 401: m2pvm_parent(nlhs,plhs,nrhs,prhs);break;
	case 600: m2pvm_initsend(nlhs,plhs,nrhs,prhs);break;
	case 700: m2pvm_pkbyte(nlhs,plhs,nrhs,prhs);break;
	case 701: m2pvm_upkbyte(nlhs,plhs,nrhs,prhs);break;
	case 702: m2pvm_pkint(nlhs,plhs,nrhs,prhs);break;
	case 703: m2pvm_upkint(nlhs,plhs,nrhs,prhs);break;
	case 704: m2pvm_pkdouble(nlhs,plhs,nrhs,prhs);break;
	case 705: m2pvm_upkdouble(nlhs,plhs,nrhs,prhs);break; 
	case 800: m2pvm_send(nlhs,plhs,nrhs,prhs);break;
	case 801: m2pvm_recv(nlhs,plhs,nrhs,prhs);break;
	default: mexErrMsgTxt("Unknown operation code.\n");break;
    }
}
