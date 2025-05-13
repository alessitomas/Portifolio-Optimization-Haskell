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
- Python 3.8+ (for data API and visualization)

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

# Install Python dependencies for data API and visualization
cd finance_data_api
python -m pip install -r requirements.txt
cd ../src
python -m pip install -r requirements.txt
```

## Setting Up the Finance Data API

The project uses a custom FastAPI server to provide stock data for the portfolio optimization algorithm. The server fetches Dow Jones Industrial Average stock data using the Yahoo Finance API and serves it through a REST endpoint.

### Starting the Finance Data API Server

```bash
# Navigate to the finance_data_api directory
cd finance_data_api

# Start the server
python main.py
```

The server will start on http://0.0.0.0:8000 and will:
- Automatically fetch and cache Dow Jones stock data on startup
- Provide an API endpoint at `/api/dow-jones-data` that returns stock closing prices
- Include API documentation at `/docs`

By default, the server uses data from August 1, 2024 to December 31, 2024 for portfolio optimization.

### Building the Project

```bash
cd src/portifolio_opt
dune build
```

## Running the Application

Before running the main application, ensure the Finance Data API server is running.

```bash
# Execute the main program
dune exec bin/main.exe
```

The application will:
1. Fetch stock data from the Finance Data API
2. Run the parallel simulation 5 times
3. Run the sequential simulation 5 times
4. Save the results to `data/simulation_results.csv`

## Visualizing Performance Results

After running the simulations, you can visualize the performance comparison:

```bash
# Run the visualization script
python src/visualize_performance.py
```

This will generate a chart comparing the execution times of parallel and sequential implementations.

## Project Structure

```
portfolio-optimization-ocaml/
├── finance_data_api/              # API for stock data
│   ├── data/                      # Cached stock data
│   ├── main.py                    # FastAPI server implementation
│   └── requirements.txt           # Python dependencies for the API
├── src/
│   ├── portifolio_opt/            # OCaml portfolio optimization
│   │   ├── bin/                   # Executable files
│   │   │   ├── dune               # Dune configuration for executable
│   │   │   └── main.ml            # Main program entry point
│   │   ├── lib/                   # Library code
│   │   │   ├── data_loader.ml     # Functions to load stock data from API
│   │   │   ├── simulate.ml        # Portfolio simulation functions
│   │   │   ├── simulate.mli       # Interface for simulation module
│   │   │   ├── util.ml            # Pure utility functions
│   │   │   └── dune               # Dune configuration for library
│   │   ├── data/                  # Stock data and simulation results
│   │   ├── dune-project           # Dune project configuration
│   │   └── portifolio_opt.opam    # OPAM package description
│   ├── images/                    # Visualization outputs
│   ├── main.py                    # Python utility script
│   ├── visualize_performance.py   # Performance visualization script
│   └── requirements.txt           # Python dependencies for visualization
```

## Implementation Details

### Data Loading

The application:
- Fetches Dow Jones stock data from the Finance Data API server
- The API caches data to avoid repeated network requests to Yahoo Finance
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

## Performance Analysis

The portfolio optimization simulation achieved impressive results, finding an optimal portfolio with the following characteristics:

### Best Portfolio Performance
- **Sharpe Ratio**: 3.016 (Higher ratio indicates better risk-adjusted returns)
- **Execution Time**: ~2,454 seconds for parallel implementation

### Optimal Portfolio Composition in 2024 (2025-08-01 to 2025-12-31)
The best-performing portfolio consists of 25 stocks with the following allocation:

| Stock | Weight (%) | Stock | Weight (%) | Stock | Weight (%) |
|-------|------------|-------|------------|-------|------------|
| AAPL  | 10.09     | IBM   | 0.77      | MSFT  | 1.20      |
| BA    | 1.99      | INTC  | 0.38      | NKE   | 1.19      |
| CAT   | 6.01      | JNJ   | 0.34      | PG    | 9.63      |
| CRM   | 7.21      | JPM   | 0.49      | TRV   | 0.82      |
| CSCO  | 8.32      | MCD   | 5.43      | UNH   | 0.39      |
| CVX   | 1.03      | MMM   | 3.37      | V     | 7.27      |
| DIS   | 8.25      | MRK   | 1.46      | VZ    | 0.42      |
| HD    | 5.60      | HON   | 10.03     | WBA   | 0.40      |
| WMT   | 7.91      |       |           |       |           |

This diversified portfolio balances investments across technology (AAPL, MSFT), finance (V, JPM), consumer goods (PG, WMT), and other sectors, with individual weights optimized for maximum risk-adjusted returns.

## Using the best performing portfolio in 2024 to invest in the first trimestre of 2025


## Performance comparison between sequential and parallel implementations

![Performance Comparison](/src/images/parallel_vs_squencial.png)

The performance comparison demonstrates a significant speedup achieved by the parallel implementation:

- **Parallel Implementation**: ~40 minutes execution time
- **Sequential Implementation**: ~201 minutes execution time
- **Speedup Factor**: ~5x faster with parallel processing

This dramatic improvement in execution time showcases the effectiveness of OCaml's multicore capabilities for computationally intensive portfolio optimization tasks.
