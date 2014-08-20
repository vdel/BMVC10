"""
Example script to create a codebook
===================================
Created by Koen van de Sande, University of Amsterdam

Example usage:

  python exampleCreateCodebook.py trainimages.txt outputFilename
  
with trainimages.txt a textfile with on every line a filename of an image
from the train set (e.g. the set of images to construct a codebook from).
outputFilename is the file in which the codebook will be written in BINDESC1
file format (see DescriptorIO.py for functions to parse this file).

For other options (codebookSize, number of iterations), see below.
To change the feature to construct a codebook for, change the 
extractionConfig variable.

Why is the script so slow?
==========================

K-means clustering is quite slow for the data sizes used in this script.
Clustering with 250,000 descriptors on 384D (ColorSIFT) descriptors will
take at least 12 hours per iteration of k-means.
To make it faster you can do the following:
- Reduce the number of iterations (e.g. --iterations 1). Iterations mean
  that k-means is run multiple times and the codebook with the lowest
  distortion is selected.
- Reduce the number of points to cluster on. By default, 250,000 descriptors
  will be extracted (no matter how many training images; the number of 
  descriptors per image is computed automatically so the total of 250,000
  is reached). This is the number of descriptors needed to construct a codebook
  of size 4,096. For a codebook with fewer elements, you can cluster on
  fewer descriptors. The script will cluster on only 100k descriptors if the
  codebook size is <= 1024.

Dependencies
============
You need to have NumPy and SciPy installed
"""

import os, sys, time, tempfile, random, struct
import numpy            # you need to have NumPy installed
import DescriptorIO     # included with ColorDescriptor software
from scipy.cluster.vq import kmeans  # you need to have SciPy installed 

if sys.platform == "win32":
    binarySoftware = "colorDescriptor.exe"
else:
    binarySoftware = "./colorDescriptor"
extractionConfig = "--detector densesampling --ds_spacing 6 --ds_scales 1.2 --descriptor opponentsift"
#extractionConfig = "--detector densesampling --ds_spacing 6 --ds_scales 1.2+2.0 --descriptor opponentsift"
#extractionConfig = "--detector harrislaplace --descriptor opponentsift"

def process(options, args):
    trainSetFilename = args[0]
    inputImages = [line.strip() for line in open(trainSetFilename).readlines()]
    outputFilename = args[1]
    keepLimited = options.descriptorsPerImage
    if keepLimited < 0:
       # estimate a good number
       if options.codebookSize > 1024:
           keepLimited = 250000 // len(inputImages)
       else:
           keepLimited = 100000 // len(inputImages)
    
    # create one file to store output of software
    (f, tempFilename) = tempfile.mkstemp()
    os.close(f)
    print "Created temporary file:", tempFilename
    print "Keeping maximum of %d descriptors per image for clustering" % keepLimited
   
    startTime = time.time()
    clusterInput = []
    for inputImage in inputImages:
        # extract features for this image
        cmdLine = "%s %s --keepLimited %d --outputFormat binary --output %s %s" % (binarySoftware, inputImage, keepLimited, tempFilename, extractionConfig)
        returnCode = os.system(cmdLine)
        if returnCode != 0:
            raise Exception("Error when executing '%s': command returned error" % cmdLine)
            
        (points, descriptors) = DescriptorIO.readDescriptors(tempFilename)
        if descriptors.size > 0:
            clusterInput.append(descriptors)
        
    os.remove(tempFilename)

    data = numpy.concatenate(clusterInput)
    print "Have cluster input (#descriptors, #dimensionality):", data.shape, "after", time.time() - startTime, "seconds"
    print "Starting k-means with %d iterations to find %d clusters" % (options.iterations, options.codebookSize)
    clusters, perf = kmeans(data, options.codebookSize, iter=options.iterations)
    print "Best distance:", perf, "; shape:", clusters.shape, ";", time.time() - startTime, "seconds"    
    DescriptorIO.writeBinaryDescriptors(outputFilename, numpy.array([[float(i)] for i in range(clusters.shape[0])]), clusters, "CODEBOOK")

def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
        
    from optparse import OptionParser
    parser = OptionParser(usage="""usage: %prog [options] trainimages.txt outputFilename""")
    parser.add_option("--iterations", default=5, type="int", help="Number of iterations for k-means (default=5)")
    parser.add_option("--codebookSize", default=512, type="int",         help="Codebook size requested (default=512)")
    parser.add_option("--descriptorsPerImage", default=-1, type="int",   help="Number of descriptors per image to cluster on (default=auto)")

    (options, args) = parser.parse_args(argv)
    if len(args) < 2:
        parser.print_help()
        return 1
    return process(options, args)
    
if __name__ == "__main__":
    sys.exit(main())
