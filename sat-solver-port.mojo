# Ported from the Python version with minimum modifications.
from sys import argv

alias Var = Int # Variable (Note: must be positive integers)
alias Literal = Int # Note: negative integers are negated variables
alias Clause = DynamicVector[Literal] # disjunction of literals
alias Assignment = DynamicVector[Var] # 0: unassigned, 1: true, -1: false

struct Solver: # Porting issue: `class` is not supported yet.
    var n_vars: Int
    var clauses: DynamicVector[Clause]
    var assignment: Assignment

    def __init__(inout self, n_vars: Int, clauses: DynamicVector[Clause]):
        self.n_vars = n_vars
        self.clauses = clauses
        self.assignment = Assignment( n_vars + 1 ) # Porting issue: No list comprehension yet
        self.assignment.resize(n_vars + 1, 0)

    # Porting issue: `borrowed` was needed to avoid a compile error.
    def is_consistent(borrowed self) -> Bool:
        def is_consistent_clause(borrowed that: Self, clause: Clause) -> Bool:
            for idx_lit in range(len(clause)):
                lit = clause[idx_lit]
                let lit_var: Var # Porting issue: Declaration needed due to variable scoping
                let lit_neg: Bool # negated?
                if lit > 0:
                    lit_var = lit
                    lit_neg = False
                else:
                    lit_var = -lit
                    lit_neg = True
                let lit_satisfied: Bool
                if that.assignment[lit_var] == 0:
                    lit_satisfied = True
                else:
                    # Porting issue: The captured `self` didn't compile here.
                    #                So, `that` is explicitly passed.
                    lit_satisfied = (that.assignment[lit_var] > 0) ^ lit_neg
                if lit_satisfied == True:
                    return True

            # Note: empty clause (no literals) => trivially false
            return False

        for idx_cls in range(len(self.clauses)):
            clause = self.clauses[idx_cls]
            if not is_consistent_clause(self, clause):
                return False

        # Note: empty formula (no clauses) => trivially satisfied
        return True

    def solve(inout self, i: Int = 1) -> Bool:
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
# Porting issue: No `TextIOWrapper` yet. So, `FileHandle` is used instead.
# Porting issue: The `formula` couldn't be returned due to some limitation in compiler.
#                 So, it is passed as an `inout` parameter.
def parse_formula( borrowed f: FileHandle, inout formula: DynamicVector[Clause] ) -> (Int, Int):
    lines = f.read().split('\n')

    # first line: header
    header = lines[0].split(' ')
    n_vars = atol( header[2] ) # Porting issue: `Int(header[2])` wouldn't work
    n_clauses = atol( header[3] )

    # parse formula
    for idx in range(1, len(lines)):
        line = lines[idx]
        if len(line) == 0:
            # skip empty lines
            continue

        # parse clause
        str_lits = line.strip().split(' ')
        clause = Clause()
        for i in range(len(str_lits)):
            str_lit = str_lits[i]
            lit = atol(str_lit)
            if lit == 0: # end of clause
                break
            clause.append( lit )

        formula.append( clause )

    return (n_vars, n_clauses)

def main():
    # Porting issue: `argv` is not an array in Mojo.
    if len(argv()) != 2:
        raise "Missing filepath argument"

    filepath = argv()[1]

    with open(filepath, "r") as f:
        clauses = DynamicVector[Clause]()
        # Porting issue: destructuring assignments won't declare local variables.
        let n_vars: Int
        let n_clauses: Int
        n_vars, n_clauses = parse_formula( f, clauses )

        # solve
        print( "# of vars (from input):", n_vars )
        print( "# of clauses (from input):", n_clauses )
        solver = Solver( n_vars, clauses )
        result = solver.solve()
        if result:
            print( "SAT" )
        else:
            print( "UNSAT" )
