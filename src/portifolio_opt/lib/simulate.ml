open Data_loader
open Util
open Domainslib
(* sequencial portifolio optimization *)

(* 1. generate all combinations of 25 stocks 
     1.1 for each combination, generate 1000 weight vector
     1.2 for each weight vector, calculate the sharpe ratio
     1.3 store the best sharpe ratio, its best weight vector and its combination.
*)
let simulate_portifolio_optimization (stock_data: stock_data list) =
  let combinations = portifolio_combinations in
  let best_sharpe = ref neg_infinity in
  let best_weights = ref None in 
  let best_comb = ref None in
  let all_results = ref [] in

  List.iteri (fun _ comb ->
    for _ = 1 to 200 do
      let weights = generate_weight_vector () in
      let sharpe_ratio = calculate_sharpe_ratio stock_data weights 252 comb in
      
      if sharpe_ratio > !best_sharpe then (
        best_sharpe := sharpe_ratio;
        best_weights := Some weights;
        best_comb := Some comb;
        all_results := (sharpe_ratio, weights, comb) :: !all_results;
      );
    done
  ) combinations;

  (!best_sharpe, !best_weights, !best_comb, !all_results)

(* Sequential optimization that returns the same format as parallel *)
let simulate_sequential_portfolio_optimization (stock_data: stock_data list) =
  let (sharpe, weights, comb, _) = simulate_portifolio_optimization stock_data in
  (sharpe, weights, comb)

(* Parallel portfolio optimization simulation *)
let simulate_parallel_portfolio_optimization (stock_data: stock_data list) =
  let combinations = portifolio_combinations in
  let best_sharpe = Atomic.make neg_infinity in
  let best_weights = Atomic.make None in 
  let best_comb = Atomic.make None in
  
  let num_domains = Domain.recommended_domain_count () in
  let pool = Task.setup_pool ~num_domains () in
  
  (* Process each combination in parallel *)
  Task.run pool (fun () ->
    Task.parallel_for pool
      ~start:0
      ~finish:(List.length combinations - 1)
      ~body:(fun comb_index ->
        let comb = List.nth combinations comb_index in
        let local_best_sharpe = ref neg_infinity in
        let local_best_weights = ref None in
        
        (* For each combination, we run 1000 weight simulations *)
        for _ = 1 to 200 do
          let weights = generate_weight_vector () in
          let sharpe_ratio = calculate_sharpe_ratio stock_data weights 252 comb in
          
          (* Update local best *)
          if sharpe_ratio > !local_best_sharpe then (
            local_best_sharpe := sharpe_ratio;
            local_best_weights := Some weights;
          );
        done;
        
        (* Update global best under atomic protection *)
        if !local_best_sharpe > Atomic.get best_sharpe then (
          Atomic.set best_sharpe !local_best_sharpe;
          Atomic.set best_weights !local_best_weights;
          Atomic.set best_comb (Some comb);
        );
       
      )
  );
  
  (* Clean up the thread pool *)
  Task.teardown_pool pool;
  
  (Atomic.get best_sharpe, Atomic.get best_weights, Atomic.get best_comb)
