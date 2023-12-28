#include <vector>
#include <optional>
#include <iostream>
#include <fstream>
#include <assert.h>

using namespace std;

#define debugOut(X)  cout << "debug: " << X << endl

using Var = int; // a positive value
using Lit = int; // non-zero value
using Clause = vector<Lit>;
using CNF = vector<Clause>;
using Assignment = vector<optional<bool>>;

class Solver
{
    int         num_vars;
    const CNF&  clauses;
    Assignment  assignment;

public:
    Solver( int num_vars, const CNF& clauses )
    : num_vars( num_vars ), clauses( clauses )
    {
        assignment.resize( num_vars + 1 );
    }

protected:
    bool is_consistent( const Clause& cl ) const
    {
        for( auto& l : cl ) {
            unsigned lit_var = std::abs(l);
            bool lit_satisfied;
            if( ! assignment[lit_var] ) {
                lit_satisfied = true;
            }
            else {
                bool polarity = l > 0;
                lit_satisfied = *assignment[lit_var] == polarity;
            }
            if( lit_satisfied ) {
                return true;
            }
        }
        // NB: Empty clause is trivially false.
        return false;
    }

    bool is_consistent() const
    {
        for( auto& cl : clauses ) {
            auto r = is_consistent( cl );
            if( ! r ) {
                return false;
            }
        }
        // NB: Empty formula is trivially true.
        return true;
    }

public:
    bool solve( int i=1 )
    {
        if( i > num_vars ) {
            // All variables are assigned.
            return true;
        }
        // debugOut( "var " << i << " => T" );
        assignment[i] = true;
        if( is_consistent() )
            if( solve(i + 1) )
                return true;
        // debugOut( "var " << i << " => F" );
        assignment[i] = false;
        if( is_consistent() )
            if( solve(i + 1) )
                return true;

        // debugOut( "reset var " << i );
        assignment[i] = nullopt; // reset assignment
        return false;
    }
};

void scan_string( istream& in, const string& str )
{
    for( auto c : str ) {
        int c2 = in.get();
        if( c != c2 ) {
            cerr << "expected '" << c << "', got '" << c2 << "'" << endl;
            throw runtime_error( "parse error" );
        }
    }
}

void parse_formula( istream& in, /*out*/CNF& f, int& n_vars, int& n_clauses )
{
    scan_string( in, "p cnf" );
    in >> n_vars >> n_clauses;

    while( in ) {
        Clause cl;
        while( in ) {
            int l;
            in >> l;
            if( l == 0 )
                break;
            cl.push_back( l );
        }
        if( cl.empty() )
            break;
        f.push_back( cl );
    }
}

int main( int argc, char** argv )
{
    if( argc != 2 ) {
        cerr << "usage: " << argv[0] << " <input-file>" << endl;
        return 1;
    }

    ifstream input( argv[1] );

    CNF f;
    int n_vars;
    int n_clauses;
    parse_formula( input, f, n_vars, n_clauses );

    cout << "# of vars (from input): " << n_vars << endl;
    cout << "# of clauses (from input): " << n_clauses << endl;

    auto solver = Solver( n_vars, f );
    auto result = solver.solve();
    if( result )
        cout << "SAT" << endl;
    else
        cout << "UNSAT" << endl;
    return 0;
}
