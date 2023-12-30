# Ported from the Python version with minimum modifications.
from sys import argv

alias Literal = Int # Note: negative integers are negated variables
alias Clause = DynamicVector[Literal] # disjunction of literals

struct ClauseRef(CollectionElement):
    var ptr: Pointer[Int]

    fn __init__( inout self, new_ptr: Pointer[Int] ):
        self.ptr = new_ptr

    fn __copyinit__( inout self, existing: Self ):
        self.ptr = existing.ptr

    fn __moveinit__( inout self, owned existing: Self ):
        self.ptr = existing.ptr
        existing.ptr = Pointer[Int].get_null()

struct LitRef:
    var ptr: Pointer[Int]

    fn __init__( inout self, cl: ClauseRef ):
        self.ptr = cl.ptr

    fn load( self ) -> Int:
        return self.ptr.load()

    fn advance( inout self ):
        self.ptr += 1

struct ClauseAlloc:
    var ptr: Pointer[Int]
    var size: Int
    var offset_unallocated: Int

    fn __init__( inout self, size: Int ):
        self.ptr = Pointer[Int].alloc( size )
        self.size = size
        self.offset_unallocated = 0

    fn __del__( owned self ):
        self.ptr.free()

    fn new_clause( inout self, data: DynamicVector[Int] ) raises -> ClauseRef:
        if self.offset_unallocated + len(data) > self.size:
            raise "[ClauseAlloc] Out of memory"
        let new_ptr = self.ptr + self.offset_unallocated
        self.offset_unallocated += (len(data) + 1)

        # fill the new memory
        for i in range( len(data) ):
            new_ptr[i] = data[i]
        new_ptr[len(data)] = 0
        return ClauseRef(new_ptr)

alias CNF = DynamicVector[ClauseRef] # conjunction of clauses
alias Var = Int # Variable (Note: must be positive integers)
alias Assignment = DynamicVector[Int] # 0: unassigned, 1: true, -1: false

struct Solver:
    var n_vars: Int
    var clause_alloc: ClauseAlloc
    var clauses: CNF
    var assignment: Assignment

    fn __init__(inout self, n_vars: Int, owned clauses: DynamicVector[Clause]) raises:
        self.n_vars = n_vars
        self.clause_alloc = ClauseAlloc( 1000 )
        self.assignment = Assignment()
        self.assignment.resize( n_vars + 1, 0 )
        self.clauses = CNF( len(clauses) )

        for idx in range(len(clauses)):
            let clause = clauses[idx]
            let cref = self.clause_alloc.new_clause( clause )
            self.clauses.append( cref )

    fn is_consistent(self) -> Bool:
        fn is_consistent_clause( self: Self, clause: ClauseRef ) -> Bool:
            var lit_ref = LitRef(clause)
            while True:
                let lit = lit_ref.load()
                if lit == 0:
                    break
                lit_ref.advance()
                let lit_var: Var
                let lit_neg: Bool # negated?
                if lit > 0:
                    lit_var = lit
                    lit_neg = False
                else:
                    lit_var = -lit
                    lit_neg = True
                let lit_satisfied: Bool
                if self.assignment[lit_var] == 0:
                    lit_satisfied = True
                else:
                    lit_satisfied = (self.assignment[lit_var] > 0) ^ lit_neg
                if lit_satisfied == True:
                    return True

            # Note: empty clause (no literals) => trivially false
            return False

        for idx_cls in range(len(self.clauses)):
            let clause = self.clauses[idx_cls]
            if not is_consistent_clause(self, clause):
                return False

        # Note: empty formula (no clauses) => trivially satisfied
        return True

    fn solve(inout self, i: Int = 1) -> Bool:
        if i > self.n_vars:
            # all variables are assigned
            return True

        # print( "debug: var", i, "=> T" )
        self.assignment[i] = 1
        if self.is_consistent():
            if self.solve( i + 1 ):
                return True
        # print( "debug: var", i, "=> F" )
        self.assignment[i] = -1
        if self.is_consistent():
            if self.solve( i + 1 ):
                return True

        # print( "debug: reset var", i )
        self.assignment[i] = 0 # reset assignment
        return False

# returns (# of vars, # of clauses)
fn parse_formula( f: FileHandle, inout clauses: DynamicVector[Clause] ) raises -> (Int, Int):
    let lines = f.read().split('\n')
    let header = lines[0].split(' ')
    let n_vars = atol( header[2] )
    let n_clauses = atol( header[3] )

    # parse formula
    for idx in range(1, len(lines)):
        let line = lines[idx]
        if len(line) == 0:
            # skip empty lines
            continue

        # parse clause
        let str_lits = line.strip().split(' ')
        var clause = Clause()
        for i in range(len(str_lits)):
            let str_lit = str_lits[i]
            let lit = atol(str_lit)
            if lit == 0: # end of clause
                break
            clause.append( lit )

        clauses.append( clause )

    return (n_vars, n_clauses)

fn main() raises:
    if len(argv()) != 2:
        raise "Missing filepath argument"

    let filepath = argv()[1]

    with open(filepath, "r") as f:
        var formula = DynamicVector[Clause]()
        let n_vars : Int
        let n_clauses : Int
        n_vars, n_clauses = parse_formula( f, formula )

        # solve
        print( "# of vars (from input):", n_vars )
        print( "# of clauses (from input):", n_clauses )
        var solver = Solver( n_vars, formula )
        let result = solver.solve()
        if result:
            print( "SAT" )
        else:
            print( "UNSAT" )
