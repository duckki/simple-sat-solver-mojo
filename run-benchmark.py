import subprocess
import time
from sys import argv
from prettytable import PrettyTable

# config
num_runs = 3

def run_command(command):
    start_time = time.time()
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
    end_time = time.time()
    elapsed_time = end_time - start_time
    return elapsed_time

def measure_average_time(command):
    print() # newline
    print( "========================================================" )
    print( "Running:", command )
    total_elapsed_time = 0
    for _ in range(num_runs):
        elapsed_time = run_command(command)
        total_elapsed_time += elapsed_time
        # print(f"Run {_ + 1}: {elapsed_time:.4f} seconds")

    average_elapsed_time = total_elapsed_time / num_runs
    print(f"\nAverage Execution Time: {average_elapsed_time:.4f} seconds")
    return average_elapsed_time

def print_result(result):
    # Assuming 'result' is a 2-level dictionary
    table = PrettyTable()

    # Extract column names (assuming they are the keys of the inner dictionary)
    columns = [name for name in list(result.values())[0].keys()]

    # Set up the table columns
    table.field_names = [""] + columns
    for col in columns:
        table.float_format[col] = "0.3f"

    # Populate the table with data
    for outer_key, inner_dict in result.items():
        row = [outer_key] + [inner_dict[column] for column in columns]
        table.add_row(row)

    # Print the table
    print(table)

def generate_csv(result):
    filename = "result.csv"
    with open(filename, 'w') as file:
        columns = [name for name in list(result.values())[0].keys()]

        print( ",".join([""] + columns), file=file )
        for outer_key, inner_dict in result.items():
            line = ",".join([outer_key] + [str(inner_dict[column]) for column in columns])
            print( line, file=file )


commands = [
    "python3 sat-solver-python.py",
    "mojo run sat-solver-port.mojo",
    "./sat-solver-port",
    "./sat-solver-cpp",
]

args = [
    "pigeonhole2.cnf",
    "pigeonhole3.cnf",
    "pigeonhole4.cnf",
    "pigeonhole5.cnf",
    "pigeonhole6.cnf",
    "pigeonhole7.cnf",
    "pigeonhole8.cnf",
]

def main():
    result = dict()
    for arg in args:
        result[arg] = dict()
        for cmd in commands:
            avg_time = measure_average_time( cmd + " " + arg )
            result[arg][cmd] = avg_time

    print_result( result )

    generate_csv( result )

if __name__ == "__main__":
    main()
