open Data_loader
open Util
(* sequencial portifolio optimization *)

(* 1. generate all combinations of 25 stocks 
     1.1 for each combination, generate 1000 weight vector
     1.2 for each weight vector, calculate the sharpe ratio
     1.3 store the best sharpe ratio, its best weight vector and its combination.
     1.4 store all sharpe ratios, weight vectors and combinations in a list.
*)
let simulate_portifolio_optimization (stock_data: stock_data list) =
  let combinations = portifolio_combinations in
  let best_sharpe = ref neg_infinity in
  let best_weights = ref None in 
  let best_comb = ref None in
  let all_results = ref [] in

  List.iteri (fun comb_index comb ->
    for _ = 1 to 1000 do
      let weights = generate_weight_vector () in
      let sharpe_ratio = calculate_sharpe_ratio stock_data weights 252 comb in
      
      if sharpe_ratio > !best_sharpe then (
        best_sharpe := sharpe_ratio;
        best_weights := Some weights;
        best_comb := Some comb
      );

      all_results := (sharpe_ratio, weights, comb) :: !all_results;
      Printf.printf "Calculated Sharpe Ratio: %f, for comb %d\n" sharpe_ratio comb_index;
    done
  ) combinations;

  (!best_sharpe, !best_weights, !best_comb, !all_results)
