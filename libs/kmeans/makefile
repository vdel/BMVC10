
all: cpp mex

cpp:
	g++ -O3 -o kmeans kmeans.cpp
	
mex:
	mex -o kmeansmex -DMEXFILE=1 -O kmeans.cpp
	
clean:
	rm -rf kmeans_mex.mexa64 kmeans_cpp *.cpp~ makefile~ *.m~
