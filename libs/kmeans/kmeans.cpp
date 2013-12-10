#include <iostream>
#include <fstream>
#include <sstream>
#include <cmath>
#include <time.h>
#include <stdlib.h>
#ifdef MEXFILE
#include <mex.h>
#endif

using namespace std;

class kmeans
{
	private:
		float* data;
		int dimension;
		int ndata;

		int ncluster;
		int maxiter;
		int niter;

		float* centers;
		float* assign;

		float* new_centers;
		int* cluster_count;
		int gcd(int,int);
	public:
		// data , dim , ndata , ncluster , maxiter
		kmeans(float*,int,int,int,int);
		void set_out_data(float*,float*);
		int getNiter();

		void initialize();

		float do_kmeans();

		void clear_new_centers();
		void find_new_centers();
		bool hasConverged(float *distance);

		bool hasEmptyFeatureVector();
		bool hasEmptyClusterCenter();
};

int kmeans::gcd(int num1,int num2)
{
	if(num2 == 0)
		return num1;
	else
	{
		int q = num1/num2;
		return gcd(num2,num1 - q*num2);
	}
}

kmeans::kmeans(float* ptr,int value1,int value2,int value3,int value4)
{
	data = ptr;
	dimension = value1;
	ndata = value2;
	ncluster = value3;
	maxiter = value4;
	new_centers = new float[dimension * ncluster];
	cluster_count = new int[ncluster];

}

void kmeans::set_out_data(float* ptr1,float* ptr2)
{
	centers = ptr1;
	assign = ptr2;
	for(int i=0;i<ndata;i++)
		assign[i] = -1;
}

void kmeans::initialize()
{
  if(hasEmptyFeatureVector())
		printf("Empty feature vector detected!\n");
	srand(time(NULL));
	int index1 = static_cast<int>(ndata*static_cast<float>(rand())/RAND_MAX);
	int index2;
	do{
		index2 = static_cast<int>(ndata*static_cast<float>(rand())/RAND_MAX);
	}while(gcd(index1,index2) != 1);
	for(int i=0;i<ncluster;i++)
	{
		for(int j=0;j<dimension;j++)
		{
			centers[i*dimension + j] = data[index1*dimension + j];
		}
		index1 = index2 + index1;
		if(index1 >= ndata)
			index1 -= ndata;
	}
	if(hasEmptyClusterCenter())
		printf("Empty initial cluster center detected!\n");
}

bool kmeans::hasEmptyFeatureVector()
{
	bool return_value = false;
	for(int i=0;i<ndata;i++)
	{
		float sum = 0.0;
		for(int j=0;j<dimension;j++)
		{
			sum += data[i * dimension + j];
		}
		if(sum == 0)
		{
			return_value = true;
			break;
		}
	}
	return return_value;
}

bool kmeans::hasEmptyClusterCenter()
{
	bool return_value = false;
	for(int i=0;i<ncluster;i++)
	{
		float sum = 0.0;
		for(int j=0;j<dimension;j++)
		{
			sum += centers[i * dimension + j];
		}
		if(sum == 0)
		{
			return_value = true;
			break;
		}
	}
	return return_value;
}

float kmeans::do_kmeans()
{
	initialize();
	float obj;
	niter = 0;
  do{
    printf("Iteration #%d\n", niter + 1);
    fflush(stdout);
		clear_new_centers();
		find_new_centers();
		niter++;
	}while(!hasConverged(&obj) && niter < maxiter);
	return obj;
}

void kmeans::clear_new_centers()
{
	for(int i=0;i<dimension*ncluster;i++)
		new_centers[i] = 0.0;
	for(int i=0;i<ncluster;i++)
		cluster_count[i] = 0;
}

void kmeans::find_new_centers()
{
	for(int i=0;i<ndata;i++)
	{
		float min_distance;
		int min_index;
		int temp_min_index;
		if(assign[i] == -1)
		{
			min_distance = 10e10;
			min_index = -1;
			temp_min_index = -1;
		}
		else
		{
			min_index = static_cast<int>(assign[i]);
			if(min_index < 0 || min_index >= ncluster)
				cout << "Error : " << min_index << endl;
			temp_min_index = min_index;
			min_distance = 0.0;
			for(int k=0;k<dimension;k++)
			{
				float value = data[i*dimension + k]-centers[min_index*dimension + k];
				min_distance += value*value;
			}
		}
		for(int j=0;j<ncluster;j++)
		{
			if( j != temp_min_index )
			{
				float c_distance = 0.0;
				for(int k=0;k<dimension;k++)
				{
					float value = data[i*dimension + k] - centers[j*dimension + k];
					c_distance += value*value;
					if(c_distance >= min_distance)
						break;
				}
				if(c_distance < min_distance)
				{
					min_distance = c_distance;
					min_index = j;
				}
			}
		}
		assign[i] = static_cast<float>(min_index);
		cluster_count[min_index] ++;
		for(int j=0;j<dimension;j++)
			new_centers[min_index*dimension + j] += data[i*dimension + j];

	}
	for(int i=0;i<ncluster;i++)
	{
		if(cluster_count[i] != 0)
			for(int j=0;j<dimension;j++)
				new_centers[i*dimension + j] /= static_cast<float>(cluster_count[i]);
    else
    {
			cout << "Empty Cluster Detected !" << endl;
			int assignement = rand()%ncluster;
			cluster_count[i] = 1;
			assign[i] = static_cast<float>(assignement);
			for(int j=0;j<dimension;j++)
				new_centers[i*dimension + j] = data[i*dimension + j];
	  }
	}
}

bool kmeans::hasConverged(float *distance)
{
	*distance = 0.0;
	float epsilon = 1e-3;
	bool abort = false;
	for(int i=0;i<ncluster;i++)
	{
		float cdistance = 0.0;
		for(int j=0;j<dimension;j++)
		{
//			cout << centers[ i* dimension + j ] << "\t" << new_centers[i*dimension +j] << endl;
			float value = centers[i*dimension + j] - new_centers[i*dimension + j];
			cdistance += value*value;
		}
//		cout << cdistance << endl;
		*distance += sqrt(cdistance);
		if(*distance > epsilon)
		{
			abort = true;
			break;
		}
  }
  printf("Distance: %f\n", *distance);
  fflush(stdout);
	if(!abort)
		return true;
	else
	{
		for(int i=0;i<ncluster*dimension;i++)
		{
			centers[i] = new_centers[i];
			new_centers[i] = 0;
		}
		return false;
	}

}

int kmeans::getNiter()
{
	return niter;
}

void norm2(float *hist, int n)
{
	float s = 1e-10;
	for(int i = 0; i < n; i++)
		s += hist[i]*hist[i];
	s = sqrt(s);
	for(int i = 0; i < n; i++)
		hist[i] /= s;
}
void norm1_with_cutoff(float *hist, int n, float cut_off_threshold)
{
	float s = 1e-10;
	for(int i = 0; i < n; i++)
		s += hist[i];
	for(int i = 0; i < n; i++)
		hist[i] /= s;

	//Cut-off
	for(int i = 0; i < n; i++)
		if(hist[i] > cut_off_threshold)
			hist[i] = cut_off_threshold;

	//re-normalization
	s = 1e-10;
	for(int i = 0; i < n; i++)
		s += hist[i];
	for(int i = 0; i < n; i++)
		hist[i] /= s;
}

#ifdef MEXFILE
void mexFunction(int nlhs,mxArray* plhs[],int nrhs,const mxArray* prhs[])
{
	 // [centers, assign, niter] = kmeans_mex(data, nclusters, maxiter)
   if(nrhs!=3)
     mexErrMsgTxt("Three input arguments required.");
   else if(nlhs!=3)
     mexErrMsgTxt("Three output arguments required.");
   else if(mxGetClassID(prhs[0]) != mxSINGLE_CLASS || mxGetNumberOfDimensions(prhs[0]) != 2)
     mexErrMsgTxt("First input should be a 2-dimensional array of type SINGLE.");  
     
	// Reading input arguments
	float* data = (float*)mxGetPr(prhs[0]);

	int dimension = static_cast<int>(mxGetM(prhs[0]));
	int ndata = static_cast<int>(mxGetN(prhs[0]));

	int ncluster = static_cast<int>(mxGetScalar(prhs[1]));
	int maxiter = static_cast<int>(mxGetScalar(prhs[2]));
	
	printf("%d-dimensional data, %d points.\n", dimension, ndata);

	// Seting output arguments

	plhs[0] = mxCreateNumericMatrix(dimension,ncluster,mxSINGLE_CLASS,mxREAL);
  float *centers = (float*)mxGetPr(plhs[0]);
	plhs[1] = mxCreateNumericMatrix(1,ndata,mxSINGLE_CLASS,mxREAL);
	float* assign = (float*)mxGetPr(plhs[1]);
	plhs[2] = mxCreateDoubleMatrix(1,1,mxREAL);
	double* obj = mxGetPr(plhs[2]);

	
	kmeans KMEANS(data,dimension,ndata,ncluster,maxiter);
	KMEANS.set_out_data(centers,assign);
	*obj = KMEANS.do_kmeans();
}
#else
int main(int argc, char **argv)
{
	if(argc != 5)
	{
		cerr << "Usage: [kmeans] feature-file ncluster maxiter output-file" << endl;
		return 1;
	}

	int dimension = 0;
	int ndata = 0;
	
  //Load data
	FILE *File = fopen(argv[1], "rb");
	
	fread(&dimension, sizeof(int), 1, File);
	fread(&ndata, sizeof(int), 1, File);
	
	float *data = new float[ndata*dimension];
	fread(data, sizeof(float), dimension*ndata, File);
  fclose(File);	
	
	int ncluster = atoi(argv[2]); 
	int maxiter = atoi(argv[3]);
	ofstream fout(argv[4]);

	// Seting output arguments
	float *centers = new float[ncluster * dimension];
	float *assign = new float[ndata];
	
	kmeans KMEANS(data,dimension,ndata,ncluster,maxiter);
	KMEANS.set_out_data(centers,assign);

	KMEANS.do_kmeans();
	
	File = fopen(argv[4], "wb+");
	fwrite(centers, sizeof(float), dimension*ncluster, File);
  fclose(File);	

	return 0;
}
#endif
