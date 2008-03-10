/* m2pvm header file */

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArrayIn *prhs[]);
static void m2pvmAtExitWarning();
static void pvme_link();
static void pvme_unlink(int nlhs, mxArray *plhs[]);
