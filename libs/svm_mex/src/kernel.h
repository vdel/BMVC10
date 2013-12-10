/************************************************************************/
/*                                                                      */
/*   kernel.h                                                           */
/*                                                                      */
/*   User defined kernel function. Feel free to plug in your own.       */
/*                                                                      */
/*   Copyright: Thorsten Joachims                                       */
/*   Date: 16.12.97                                                     */
/*                                                                      */
/************************************************************************/

/* KERNEL_PARM is defined in svm_common.h The field 'custom' is reserved for */
/* parameters of the user defined kernel. You can also access and use */
/* the parameters of the other kernels. Just replace the line 
             return((double)(1.0)); 
   with your own kernel. */

  /* Example: The following computes the polynomial kernel. sprod_ss
              computes the inner product between two sparse vectors. 

      return((CFLOAT)pow(kernel_parm->coef_lin*sprod_ss(a->words,b->words)
             +kernel_parm->coef_const,(double)kernel_parm->poly_degree)); 
  */

/* If you are implementing a kernel that is not based on a
   feature/value representation, you might want to make use of the
   field "userdefined" in SVECTOR. By default, this field will contain
   whatever string you put behind a # sign in the example file. So, if
   a line in your training file looks like

   -1 1:3 5:6 #abcdefg

   then the SVECTOR field "words" will contain the vector 1:3 5:6, and
   "userdefined" will contain the string "abcdefg". */
   
#ifndef KERNELH
#define KERNELH

#include <assert.h>

double **K;    /* K[i][j]: 'i' is row index and 'j' is column index */
int dimensionN;
int dimensionM;

double gram_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b);
double chi2_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b);
double intersection_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b);

/*****************************************************************************/
/*                                                                           */
/*                               Custom Kernel                               */
/*                                                                           */
/*****************************************************************************/
double custom_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b) 
     /* plug in you favorite kernel */                          
{
	switch(kernel_parm->custom[0])
	{
		case '0': 
		case '\0':
			return gram_kernel(kernel_parm, a, b);	
		case '1': return chi2_kernel(kernel_parm, a, b);
		case '2': return intersection_kernel(kernel_parm, a, b);
		default:
		#ifdef MATLAB_MEX
			mexErrMsgTxt("Unknown personnal kernel function!");
		#else
			printf("Error: Unknown personnal kernel function!\n"); 
			exit(1);
		#endif
	}
}

/*****************************************************************************/
/*                                                                           */
/*                              Chi2 Kernel                                  */
/*                                                                           */
/*****************************************************************************/

/* Chi2 Distance
*/
double chi2_distance(SVECTOR *a, SVECTOR *b)
{
  register double sum=0;
  register WORD *ai,*bj;
  register double num;
	register double denom;
  ai=a->words;
  bj=b->words;
  while (ai->wnum && bj->wnum) {
    if(ai->wnum > bj->wnum) {
	sum += bj->weight;
	bj++;
    }
    else if (ai->wnum < bj->wnum) {
	sum += ai->weight;
	ai++;
    }
    else {
	num   = ai->weight - bj->weight;
	denom = ai->weight + bj->weight;
	if(denom)
		sum += num*num/denom;
	ai++;
	bj++;
    }
  }
	while(ai->wnum)
	{
		sum += ai->weight;
		ai++;	
	}
	while(bj->wnum)
	{
		sum += bj->weight;
		bj++;	
	}	
  return sum*2.;
}

/*****************************************************************************/
double chi2_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b)                         
{
	return exp(-kernel_parm->rbf_gamma*chi2_distance(a,b));
}

/*****************************************************************************/
/*                                                                           */
/*                           Intersection Kernel                             */
/*                                                                           */
/*****************************************************************************/
double intersection_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b)
{
	register double sum=0;
    register WORD *ai,*bj;
    ai=a->words;
    bj=b->words;
    while (ai->wnum && bj->wnum) {
      if(ai->wnum > bj->wnum) 
		bj++;
      else if (ai->wnum < bj->wnum) 
		ai++;
      else {
        if(ai->weight < bj->weight)
        	sum += ai->weight;
       	else
        	sum += bj->weight;
		ai++;
		bj++;
      }
    }
    return sum;
}

/*****************************************************************************/
/*                                                                           */
/*                General Kernel with precomputed gram matrix                */
/*                                                                           */
/*****************************************************************************/

/* Reading input arguments */
void load_kernel_from_file(char *file)
{
	int i;
	FILE *fid = fopen(file,"rb");
	assert(fid);
	fread(&dimensionN, sizeof(int), 1, fid);
	fread(&dimensionM, sizeof(int), 1, fid);	
	K = (double**)malloc(sizeof(double*)*dimensionN);
	for(i=0; i<dimensionN; i++)
	{
		K[i] = (double*)malloc(sizeof(double)*dimensionM);
		fread(K[i], sizeof(double), dimensionM, fid);
	}
	fclose(fid);		
}

/*****************************************************************************/
/* Frees the memory */
void free_kernel()
{
	if(K)
	{
		int i;
		for(i=0; i<dimensionN; i++)
			free(K[i]);
		free(K);
	}
}

/*****************************************************************************/
double gram_kernel(KERNEL_PARM *kernel_parm, SVECTOR *a, SVECTOR *b)                         
{
	if(kernel_parm->custom[0] == '0')
	{
	  load_kernel_from_file(kernel_parm->custom + 1);
	  kernel_parm->custom[0] = '\0';
	}
	  
	if(!a->words->wnum) {
		if(!b->words->wnum) return K[0][0];
		else           			return K[0][(int)(b->words->weight)];
	}	else 	{
		if(!b->words->wnum)	return K[(int)(a->words->weight)][0];
		
		else								return K[(int)(a->words->weight)][(int)(b->words->weight)];
	}
}

/*****************************************************************************/

#endif
