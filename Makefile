BENCHMARKS = pigeonhole2.cnf pigeonhole3.cnf pigeonhole4.cnf pigeonhole5.cnf pigeonhole6.cnf pigeonhole7.cnf pigeonhole8.cnf

all: sat-solver-port sat-solver-cpp $(BENCHMARKS)

sat-solver-port: Makefile sat-solver-port.mojo
	mojo build sat-solver-port.mojo

sat-solver-cpp: Makefile sat-solver-cpp.cpp
	c++ -std=gnu++17 -O1 -o $@ sat-solver-cpp.cpp

# Rule pattern to generate pigeonhole*.cnf files
pigeonhole%.cnf: Makefile gen-pigeonhole-cnf.mojo
	mojo run gen-pigeonhole-cnf.mojo $* > $@
