open Portifolio_opt.Data_loader
open Portifolio_opt.Simulate

(* request stock data from api and transform to yojson using functions defined at data_loader.ml *)
let () = 
  print_endline "Hello, World!";
  
  (* simulate portifolio optimization *)
  let (best_sharpe, best_weights, best_comb, all_results) = simulate_portifolio_optimization dow_jones_stocks in
  print_endline (string_of_float best_sharpe);
  match best_weights with
  | Some weights -> print_endline (string_of_float (Array.fold_left (+.) 0.0 weights))
  | None -> print_endline "No weights found";
  match best_comb with
  | Some comb -> print_endline (string_of_int (List.length comb))
  | None -> print_endline "No combination found";
  print_endline (string_of_int (List.length all_results));


