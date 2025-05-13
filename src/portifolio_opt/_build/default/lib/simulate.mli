open Data_loader

(* Portfolio optimization functions *)
val simulate_portifolio_optimization : 
  stock_data list -> 
  float * float array option * string list option * (float * float array * string list) list

val simulate_sequential_portfolio_optimization :
  stock_data list ->
  float * float array option * string list option

val simulate_parallel_portfolio_optimization :
  stock_data list ->
  float * float array option * string list option 