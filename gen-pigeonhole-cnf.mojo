# pigeon hole formula generator
# Pigeon hole problem: Placing n+1 pigeons in n holes without placing 2 pigeons in the same hole.

# Example 1: There are 2 pigeons but 1 hole. (2 vars)
# Var `1` means pigeon #1 is in the hole.
# Var `2` means pigeon #2 is in the hole.
# formula:
# 1
# 2
# -1 -2

# Example 2: There are 3 pigeons but 2 holes. (6 vars)
# Var `1` means pigeon #1 is in the hole #1.
# Var `2` means pigeon #1 is in the hole #2.
# Var `3` means pigeon #2 is in the hole #1.
# Var `4` means pigeon #2 is in the hole #2.
# Var `5` means pigeon #3 is in the hole #1.
# Var `6` means pigeon #3 is in the hole #2.
# formula:
# 1 2
# 3 4
# 5 6
# -1 -3
# -1 -5
# -3 -5
# -2 -4
# -2 -6
# -4 -6

# The predicate `p(i, j)` means pigeon #i is in the hole #j.
# Each pigeon must be in one of the holes. (`n+1` clauses)
# - p(1, 1) p(1, 2) ... p(1, n)
# - p(2, 1) p(2, 2) ... p(2, n)
# - ...
# - p(n+1, 1) p(n+1, 2) ... p(n+1, n)
# Any 2 pigeons cannot be in the same hole. (`n * (n+1) / 2` clauses per hole)
# - ¬p(1, h) ¬p(2, h)
# - ¬p(1, h) ¬p(3, h)
# - ...
# - ¬p(n-1, h) ¬p(n, h)
# - ¬p(n-1, h) ¬p(n+1, h)
# - ¬p(n, h) ¬p(n+1, h)
# # of clauses: (n+1) + ((n * (n+1) // 2) * n)
# # of Boolean vars: n * (n+1)
# - p(x, y) == var # `(x-1) * n + (y-1) + 1` (1 <= x <= n+1, 1 <= y <= n)

fn generate( n_holes: Int ):
    # header
    let n_vars = n_holes * (n_holes+1)
    let n_clauses = (n_holes+1) + ((n_holes+1) * n_holes // 2) * n_holes
    print( "p", "cnf", n_vars, n_clauses )

    # p: pigeon #
    # h: hole #
    fn compute_var( p: Int, h: Int ) -> Int:
        return 1 + ((p-1) * n_holes) + (h-1)

    # Each pigeon must be in one of the holes. (`n+1` clauses)
    for p in range(1, n_holes+2):
        for h in range(1, n_holes+1):
            print_no_newline( compute_var(p, h), "" )
        print( "0" ) # end of clause

    for h in range(1, n_holes+1):
        # Any 2 pigeons cannot be in the same hole. (`(n+1) * n` clauses per hole)
        for p in range(1, n_holes+2):
            for q in range(1, n_holes+2):
                if p >= q:
                    continue
                print( -compute_var(p, h), -compute_var(q, h), "0" )

from sys import argv

def main():
    let size = atol(argv()[1])
    generate( size )
