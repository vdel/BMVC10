SET SVMMEX=C:\SVM_MEX601
set PATH=%PATH%;%SVMMEX%\WIN\BIN

@echo off
echo ---------------------------------------------------------------------
echo REQUIREMENTS:
echo   (1) Ensure that "mex.bat" is in your path
echo   (2) Copy or Unzip SVM Light 6.01 source files
echo      into the "src" subdirectory
echo ---------------------------------------------------------------------
pause

echo Patching the svm source
cd src
rem patch -p1  < ../patch_svm601
patch -p1 --binary < ../patch_svm601

pause
echo Compiling (using mex.bat)
cd ../bin
echo Compiling mexsvmlearn
cmd /c mex -g -DMATLAB_MEX -DMEX_MEMORY -I../src ../src/mexsvmlearn.c ../src/global.c ../src/svm_learn.c ../src/svm_common.c ../src/svm_hideo.c ../src/mexcommon.c ../src/mem_clean.c


echo Compiling mexsvmclassify
cmd /c mex -O  -DMATLAB_MEX -DMEX_MEMORY -I../src  ../src/mexsvmclassify.c ../src/global.c ../src/svm_learn.c ../src/svm_common.c ../src/svm_hideo.c ../src/mexcommon.c ../src/mem_clean.c

echo Compiling mexsinglekernel
cmd /c mex -O  -DMATLAB_MEX -DMEX_MEMORY -I../src ../src/mexsinglekernel.c ../src/global.c ../src/svm_learn.c ../src/svm_common.c ../src/svm_hideo.c ../src/mexcommon.c ../src/mem_clean.c


echo Compiling mexkernel
cmd /c mex -O  -DMATLAB_MEX -DMEX_MEMORY -I../src ../src/mexkernel.c ../src/global.c ../src/svm_learn.c ../src/svm_common.c ../src/svm_hideo.c ../src/mexcommon.c ../src/mem_clean.c

cd ..
