# A simple SAT solver written in Python
from dataclasses import dataclass
from sys import argv
from io import TextIOWrapper

@dataclass
class Solver:
    n_vars: int
    clauses: list
    assignment: list

    def __init__(self, n_vars: int, clauses: list):
        self.n_vars = n_vars
        self.clauses = clauses
        self.assignment = [0 for _ in range(0, n_vars + 1)]

    def is_consistent(self) -> bool:
        def is_consistent_clause(clause: list) -> bool:
            for idx_lit in range(len(clause)):
                lit = clause[idx_lit]
                if lit > 0:
                    lit_var = lit
                    lit_neg = False
                else:
                    lit_var = -lit
                    lit_neg = True
                lit_satisfied: bool
                if self.assignment[lit_var] == 0:
                    lit_satisfied = True
                else:
                    lit_satisfied = (self.assignment[lit_var] > 0) ^ lit_neg
                if lit_satisfied == True:
                    return True

            # Note: empty clause (no literals) => trivially false
            return False

        for idx_cls in range(len(self.clauses)):
            clause = self.clauses[idx_cls]
            if not is_consistent_clause(clause):
                return False

        # Note: empty formula (no clauses) => trivially satisfied
        return True

    def solve(self, i: int = 1) -> bool:
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

# returns (formula, # of vars, # of clauses)
def parse_formula( f: TextIOWrapper ) -> ([], int, int):
    lines = f.read().split('\n')

    # first line: header
    header = lines[0].split(' ')
    n_vars = int( header[2] )
    n_clauses = int( header[3] )

    # parse formula
    formula = []
    for idx in range(1, len(lines)):
        line = lines[idx]
        if len(line) == 0:
            # skip empty lines
            continue

        # parse clause
        str_lits = line.strip().split(' ')
        clause = []
        for i in range(len(str_lits)):
            str_lit = str_lits[i]
            lit = int(str_lit)
            if lit == 0: # end of clause
                break
            clause.append( lit )

        formula.append( clause )

    return (formula, n_vars, n_clauses)


def main():
    if len(argv) != 2:
        raise "Missing filepath argument"

    filepath = argv[1]

    with open(filepath, "r") as f:
        clauses, n_vars, n_clauses = parse_formula( f )

        # solve
        print( "# of vars (from input):", n_vars )
        print( "# of clauses (from input):", n_clauses )
        solver = Solver( n_vars, clauses )
        result = solver.solve()
        if result:
            print( "SAT" )
        else:
            print( "UNSAT" )

if __name__ == "__main__":
    main()
