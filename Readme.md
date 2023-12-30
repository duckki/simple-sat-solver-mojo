# A Simple SAT Solver Implemented in Python/Mojo/C++

I've implemented a simple SAT solver in Python, [Mojo](https://docs.modular.com/mojo/) and C++, then compared their runtime performance in the style of [The Great Computer Language Shootout](https://en.wikipedia.org/wiki/The_Computer_Language_Benchmarks_Game).

## What's SAT?

SAT represents [the Boolean satisfiability problem](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem), which is one of the canonical computational problems known to be NP-complete.

## The DIMACS Input Format

[DIMACS](http://www.satcompetition.org/2009/format-benchmarks2009.html) is the standard input file format used at the SAT competition and most SAT solvers support this format.

Example (from [pigeonhole2.cnf](pigeonhole2.cnf))
```
p cnf 6 9
1 2 0
3 4 0
5 6 0
-1 -3 0
-1 -5 0
-3 -5 0
-2 -4 0
-2 -6 0
-4 -6 0
```

## Comparison

Although a [SAT solver](https://en.wikipedia.org/wiki/SAT_solver) can be very complicated, this exercise is to compare the compiler optimizations and the solver code is intentionally kept very simple. I started with a Python version and then ported it into Mojo and C++.

| Version | Source File |
| - | ---- |
| Python version | [sat-solver-python.py](sat-solver-python.py) |
| Mojo version | [sat-solver-port.mojo](sat-solver-port.mojo) |
| C++ version | [sat-solver-cpp.cpp](sat-solver-cpp.cpp) |

The Python version is 118 LoC. The Mojo version is 128 LoC with some more type declarations. The C++ version came in at 142 LoC.

In terms of algorithm and data structure, they are comparable. The Python version mainly uses `list`, the Mojo version uses `DynamicVector` and the C++ version uses `vector`. SAT solvers are memory access intensive using those data structures. So, their internal implementation will have a great impact on the result.

### Benchmark

A sample of DIMACS inputs are generated using the `gen-pigeonhole-cnf.mojo` script. The script generates SAT formulas in DIMACS format based on the pigeonhole principle with a given number of holes as its argument. All generated formulas are unsatisfiable, forcing simple SAT solvers to explore the entire search space.

Usage:
```
mojo run gen-pigeonhole-cnf.mojo <holes>
```

### Experiment

Run `make` to build Mojo version and C++ version binaries and benchmarks (pigeonhole2.cnf through pigeonhole8.cnf).

Run `python3 run-benchmark.py` to execute the whole experiment. The script runs 4 different solver configurations over the generated benchmark input files.

| Configuration | Command Line |
| ------------- | ------------ |
| Python version | python3 sat-solver-python.py |
| Mojo version (JIT) | mojo run sat-solver-port.mojo |
| Mojo version (precompiled) | ./sat-solver-port |
| C++ version (precompiled) | ./sat-solver-cpp |

Mojo version was compiled with the default optimization enabled (without any options). The C++ version was compiled with `clang` and `-O1` optimization option. (But, any higher optimization option didn't seem to make much difference.)

### Result

Here're the runtime measurements in seconds:

| | python3 sat-solver-python.py | mojo run sat-solver-port.mojo | ./sat-solver-port | ./sat-solver-cpp |
| ---- | ---- | ---- | ---- | ---- |
| pigeonhole2.cnf | 0.0249 | 0.0895 | 0.0037 | 0.0032 |
| pigeonhole3.cnf | 0.0250 | 0.0900 | 0.0042 | 0.0033 |
| pigeonhole4.cnf | 0.0361 | 0.0916 | 0.0050 | 0.0036 |
| pigeonhole5.cnf | 0.2142 | 0.1123 | 0.0243 | 0.0057 |
| pigeonhole6.cnf | 3.2518 | 0.4473 | 0.3361 | 0.0342 |
| pigeonhole7.cnf | 58.0513 | 6.3182 | 5.8706 | 0.5018 |
| pigeonhole8.cnf | 1114.3073 | 117.5253 | 112.2467 | 9.3582 |

(*Measurements were recorded on a MacBook Pro with M1 Pro and 16GB RAM running macOS Sonoma 14.2.1*)

Here're the speed-ups over the original Python runtime.

| | mojo run sat-solver-port.mojo | ./sat-solver-port | ./sat-solver-cpp |
| ---- | ---- | ---- | ---- |
| pigeonhole2.cnf  | 0.28      | 6.67      | 7.73      |
| pigeonhole3.cnf  | 0.28      | 5.97      | 7.45      |
| pigeonhole4.cnf  | 0.39      | 7.18      | 10.13     |
| pigeonhole5.cnf  | 1.91      | 8.80      | 37.67     |
| pigeonhole6.cnf  | 7.27      | 9.68      | 95.13     |
| pigeonhole7.cnf  | 9.19      | 9.89      | 115.68    |
| pigeonhole8.cnf  | 9.48      | 9.93      | 119.07    |

The Mojo version has over 9x speedup over the larger inputs. The difference between JIT and precompile was not significant and that's understandable since the size of code is very small.

Interestingly, Python is indeed lighter at loading, recording 0.025 seconds compared to Mojo's 0.0895 seconds for `pigeonhole2.cnf` and `pigeonhole3.cnf`, which are so small that the most of the runtime must be just loading/compiling. In any case, their loading/compile time is quite small. And Mojo's faster runtime quickly overtake Python version over the larger inputs.

The C++ version turned out to be much faster than the Mojo version (over 95x~119x speedup over the baseline Python version). That suggests Mojo still has a long way to go in terms of code generation.

## Performance Bottleneck in the Mojo version

The ported Mojo version couldn't use for-each loop directly over the content of `DynamicVector`. Instead, I had to use an index to access the vector indirectly. It seems to be the main bottleneck.

```python
        def is_consistent_clause(borrowed that: Self, clause: Clause) -> Bool:
            for idx_lit in range(len(clause)):
                lit = clause[idx_lit]
                ...
```

I implemented another version using the (unsafe) `Pointer` type (in [sat-solver-unsafe.mojo](sat-solver-unsafe.mojo)) and the Mojo's performance matched C++'s.

## Porting Python to Mojo

Mojo is aiming to be a superset of Python. Even at an early version (0.6.1), it was straightforward to port the Python version to Mojo. But, there were several issues as indicated in the code comments. Here is the summary of my expereince.

### Unimplemented features and workarouds

I think these are minor compatibility issues that can be easily fixed as Mojo matures.

* No list comprehension: Use the `DynamicVector` type and loops to initialize.
* `class` definition: Use `struct` definition.
* Type casing like `int(x)` or `str(y)`: Use Mojo types and library functions.
* No `TextIOWrapper` type: Use `FileHandle`.
* `DynamicVector` instance couldn't be returned in a tuple.
* `sys.argv` is a function, not a list: Change `argv[1]` to `argv()[1]`.
* Closures can't capture by reference, yet: Pass references explictly to the closure.

### Unexpected compile failures

Also, I experienced a few unexpected issues that might be just bugs in the current version of Mojo (0.6.1).

The variable scope of local variables in `def` functions are not hoisted to the top of the function.

* Symptom: Local variables that are assigned under a `then`-clause wasn't accessible after the if-statement.
* Workaround: Those variables need to be explicitly declared outside of the if-statement.
* I filed https://github.com/modularml/mojo/issues/1574 for this, but it seems to be intentional deviation from Python.

### `borrowed`/`inout` annotations can't be avoided

Even if all of those compiler and compatibility issues are resolved, I don't think some of those `borrowed`/`inout` annotations on arguments could be elided altogether. That means not all Python code can be ported without a change. I expect many Python code will need some additional annotations in their Mojo port, even if some of that could be automated.

As an alternative, Mojo could feature an "auto" ownership for `def` functions, instead of `owned` default, allowing the compiler to decide `owned`/`borrowed`/`inout` based on the usage of the arguments within the function definition.

The issue will be more pronounced with closures, because Python closures are expected to capture local variables by reference. The `owned` default ownership is more likely to break closures, even after Mojo implementing capture declarations in closures.