#!/bin/sh

DIST=`pwd`
SVMSRC=$DIST/src	# either manually set or use the loop below
PATCH=`which patch`		# location of patch command


if [ ! -x "$PATCH" ]; then
	echo "ERROR: could not find 'patch' command in your PATH environment."
fi

# if the SVMSRC directory isn't valid, ask where it is
while [ ! -f "$SVMSRC/svm_common.c" ];
do
  echo "-----------------------------------------"
  echo "ERROR - $DIST/src/svm_common.c was not found"
  echo ""
  echo "SVM-Light source files were not found in the $DIST/src directory"
  echo "Either copy or extract the files into $DIST/src"
  echo ""
  echo "Press <enter> when ready to continue "
  echo "-or- ctrl-c to exit the script (no changes have been made yet)"
  echo "-----------------------------------------"
  read SVMSRC

done

#echo Patching $SVMSRC
cd $DIST/src

#patch -p1 < $DIST/patch_svm601

echo Compiling
cd ../bin
mex -O  -DMATLAB_MEX -I../src ../src/mexsvmlearn.c ../src/global.c ../src/svm_learn.c ../src/svm_common.c ../src/svm_hideo.c ../src/mexcommon.c ../src/mem_clean.c

mex -O  -DMATLAB_MEX -I../src ../src/mexsvmclassify.c ../src/global.c ../src/svm_learn.c ../src/svm_common.c ../src/svm_hideo.c ../src/mexcommon.c ../src/mem_clean.c

mex -O  -DMATLAB_MEX -I../src ../src/mexsinglekernel.c ../src/global.c ../src/svm_learn.c ../src/svm_common.c ../src/svm_hideo.c ../src/mexcommon.c ../src/mem_clean.c
 
mex -O  -DMATLAB_MEX -I../src ../src/mexkernel.c ../src/global.c ../src/svm_learn.c ../src/svm_common.c ../src/svm_hideo.c ../src/mexcommon.c ../src/mem_clean.c
    
