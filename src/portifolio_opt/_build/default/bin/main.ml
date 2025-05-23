open Portifolio_opt.Data_loader
open Portifolio_opt.Simulate
open Unix

let run_and_save_simulation name simulation_fn =
  (* Record start time *)
  let start_time = gettimeofday () in
  
  (* Run portfolio optimization *)
  let (best_sharpe, best_weights, best_comb) = simulation_fn dow_jones_stocks in
  
  (* Record end time and calculate elapsed time *)
  let end_time = gettimeofday () in
  let elapsed_time = end_time -. start_time in
  Printf.printf "%s simulation took %.2f seconds\n" name elapsed_time;
  
  (* Print results *)
  Printf.printf "Best Sharpe Ratio: %f\n" best_sharpe;
  
  (match best_weights with
  | Some weights -> Printf.printf "Sum of weights: %f\n" (Array.fold_left (+.) 0.0 weights)
  | None -> print_endline "No weights found");
  
  (* Print best combination info *)
  (match best_comb with
  | Some comb -> 
      print_endline "Got best combination";
      Printf.printf "Number of stocks: %d\n" (List.length comb)
  | None -> 
      print_endline "No combination found");
  
  (* CSV export for the best result *)
  (match best_weights, best_comb with
  | Some weights, Some comb ->
      (* Create the new data row with simulation type as first column *)
      let new_row = name :: 
                   string_of_float best_sharpe :: 
                   Array.to_list (Array.map string_of_float weights) @ 
                   comb @ 
                   [string_of_float elapsed_time] in
      
      let data_dir = "./data" in
      let csv_path = Filename.concat data_dir "simulation_results.csv" in
      
      (* Load existing CSV or create empty one if it doesn't exist *)
      let existing_rows = 
        try Csv.load csv_path 
        with _ -> [] in
      
      (* Append the new row to existing data *)
      let updated_csv = existing_rows @ [new_row] in
      
      (* Save the updated CSV *)
      Printf.printf "Appending result to: %s\n" csv_path;
      Csv.save csv_path updated_csv;
      Printf.printf "CSV file updated with new result (execution time: %.2f seconds)\n" elapsed_time
  | _, _ ->
      print_endline "Could not save result to CSV as some optimal values are missing.");
  
  print_endline "-----------------------------------"

let () = 
  print_endline "Starting portfolio optimization simulations";
  print_endline "=========================================";
  
  (* Run parallel simulations 5 times *)
  print_endline "\nRunning 5 parallel simulations:";
  for i = 1 to 5 do
    Printf.printf "\nParallel simulation %d/5\n" i;
    run_and_save_simulation "Parallel" simulate_parallel_portfolio_optimization;
  done;
  
  (* Run sequential simulations 5 times *)
  print_endline "\nRunning 5 sequential simulations:";
  for i = 1 to 5 do
    Printf.printf "\nSequential simulation %d/5\n" i;
    run_and_save_simulation "Sequential" simulate_sequential_portfolio_optimization;
  done;
  
  print_endline "\nAll simulations completed!"