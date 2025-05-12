open Portifolio_opt.Data_loader
open Portifolio_opt.Simulate

let () = 
  print_endline "Hello, World!";
  
  try
    (* Run portfolio optimization *)
    let (best_sharpe, best_weights, best_comb, all_results) = simulate_parallel_portfolio_optimization dow_jones_stocks in
    
    (* Print results *)
    print_endline (string_of_float best_sharpe);
    
    (match best_weights with
    | Some weights -> print_endline (string_of_float (Array.fold_left (+.) 0.0 weights))
    | None -> print_endline "No weights found");
    
    (* Carefully handle best_comb *)
    (match best_comb with
    | Some comb -> 
        print_endline "Got best combination";
        (try 
           print_endline (string_of_int (List.length comb))
         with e -> 
           Printf.printf "Error with comb: %s\n" (Printexc.to_string e))
    | None -> 
        print_endline "No combination found");
    
    (* Safely print all_results length *)
    (try
       print_endline (string_of_int (List.length all_results));
       
       (* Debug info *)
       Printf.printf "Results count: %d\n" (List.length all_results);
       Printf.printf "Current directory: %s\n" (Sys.getcwd());

       (* CSV export with error handling *)
       (try
         let csv_data = List.map (fun (sharpe, weights, comb) ->
           string_of_float sharpe :: Array.to_list (Array.map string_of_float weights) @ comb
         ) all_results in
         
         (* Use a relative path to the data directory *)
         let data_dir = "./data" in

         let csv_path = Filename.concat data_dir "all_results.csv" in
         Printf.printf "Saving CSV to: %s\n" csv_path;
         Csv.save csv_path csv_data;
         Printf.printf "CSV file saved successfully!\n"
       with e ->
         Printf.printf "Error saving CSV: %s\n" (Printexc.to_string e))
     with e ->
       Printf.printf "Error with all_results: %s\n" (Printexc.to_string e))
  with e ->
    Printf.printf "Program crashed: %s\n" (Printexc.to_string e)