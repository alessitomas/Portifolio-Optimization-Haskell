open Portifolio_opt.Data_loader
open Portifolio_opt.Util

(* request stock data from api and transform to yojson using functions defined at data_loader.ml *)

let () = 
  print_endline "Hello, World!";
  (* get just the first record *)
  let first_record = List.hd dow_jones_stocks in
  print_stock_data first_record;;

  (* get all combinations of 25 stocks *)
  (* let combinations = portifolio_combinations in
  print_endline (string_of_int (List.length combinations)); *)

  (* generate weight vector *)
  let weight_vector = generate_weight_vector () in
  (* print weight vector *)
  Array.iter (fun x -> print_endline (string_of_float x)) weight_vector;
  (* print sum of weight vector *)
  print_endline (string_of_float (Array.fold_left (+.) 0.0 weight_vector));
