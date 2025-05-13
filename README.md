# Portfolio Optimization in OCaml

This project implements a portfolio optimization algorithm using Modern Portfolio Theory (MPT) to find the optimal asset allocation across stocks from the Dow Jones Industrial Average.

## Project Overview

The application:
- Analyzes 30 stocks from the Dow Jones Industrial Average using data from the second half of 2024
- Selects 25 out of 30 stocks (~142,000 combinations)
- Generates 1,000 random portfolio weights for each combination
- Uses parallel processing to optimize execution time
- Identifies the optimal portfolio based on the Sharpe ratio
- Compares performance between sequential and parallel implementations

## Installation

### Prerequisites

- OCaml (version 5.3.0 or newer)
- OPAM (OCaml package manager)

### Installing Dependencies

```bash
# Initialize opam if not done already
opam init

# Create a switch for this project
opam switch create 5.3.0+options

# Update environment
eval $(opam env)

# Install required libraries
opam install dune
opam install cohttp-lwt-unix
opam install yojson
opam install csv
opam install ptime
opam install domainslib  # For parallelism
```

### Building the Project

```bash
cd src/portifolio_opt
dune build
```

## Running the Application

```bash
# Execute the main program
dune exec bin/main.exe
```

The application will:
1. Run the parallel simulation 5 times
2. Run the sequential simulation 5 times
3. Save the results to `data/simulation_results.csv`

## Project Structure

```
src/portifolio_opt/
├── bin/                # Executable files
│   ├── dune            # Dune configuration for executable
│   └── main.ml         # Main program entry point
├── lib/                # Library code
│   ├── data_loader.ml  # Functions to load stock data from API
│   ├── simulate.ml     # Portfolio simulation functions (sequential & parallel)
│   ├── simulate.mli    # Interface for simulation module
│   ├── util.ml         # Pure utility functions
│   └── dune            # Dune configuration for library
├── data/               # Stock data and simulation results
├── dune-project        # Dune project configuration
└── portifolio_opt.opam # OPAM package description
```

## Implementation Details

### Data Loading

The application:
- Fetches Dow Jones stock data from a REST API (configurable between development and production environments)
- Processes the JSON response into a structured format for analysis

### Parallelization Strategy

The application parallelizes portfolio simulation using OCaml's `domainslib`:

1. Uses `Domain.recommended_domain_count()` to determine the optimal number of domains (threads)
2. Creates a thread pool with the `Task` module
3. Distributes combinations across available cores using `Task.parallel_for`
4. Uses atomic operations to safely aggregate results from parallel computations
5. Finally compares the performance against a sequential implementation

### Portfolio Optimization

For each combination of 25 stocks:
1. Generates 1,000 random weight vectors (normalized so weights sum to 1.0)
2. Creates a daily return matrix from historical data
3. Calculates the portfolio's expected return using pure OCaml matrix operations
4. Calculates the portfolio's standard deviation (risk)
5. Computes the Sharpe ratio (return divided by risk)
6. Identifies the portfolio with the highest Sharpe ratio among all 1,000 simulations

### Linear Algebra Operations

The project uses pure OCaml implementations for matrix operations:
- `generate_daily_return_matrix`: Creates a matrix of daily returns for selected stocks
- `matrix_vector_mul`: Multiplies the returns matrix by the weights vector using a pure functional approach
- All mathematical operations are implemented without external numerical libraries, showcasing OCaml's capabilities for numerical computing

## Expected Results

The output includes:
- Best Sharpe ratio found in each simulation run
- Optimal portfolio weights
- The selected stocks in the optimal portfolio
- Execution time metrics for both parallel and sequential implementations

Results are saved to a CSV file for further analysis and visualization.

## References

- Modern Portfolio Theory (Markowitz, 1952)
- Sharpe, W. F. (1964). Capital asset prices: A theory of market equilibrium under conditions of risk
- OCaml Multicore: https://github.com/ocaml-multicore/