open Portifolio_opt.Data_loader
open Lwt
open Cohttp_lwt_unix

(* API URL configuration *)
let prod_env = false
let api_url = if prod_env then "http://44.200.31.239:8000" else "http://0.0.0.0:8000"

(* Fetch 2025 Q1 data from API *)
let get_dow_jones_2025 =
  Client.get (Uri.of_string (api_url ^ "/api/dow-jones-data/2025")) >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string

(* Load the 2025 Q1 data *)
let dow_jones_2025_data = Lwt_main.run get_dow_jones_2025
let dow_jones_2025_json = Yojson.Basic.from_string dow_jones_2025_data
let dow_jones_2025_stocks = get_stock_data dow_jones_2025_json

(* Hard-coded best portfolio from 2024 data *)
let best_portfolio () =
  (* Original Sharpe ratio from 2024 *)
  let original_sharpe = 3.015921 in
  
  (* Hard-coded weights *)
  let weights = [|
    0.10092720913; 0.0198823952227; 0.0600665150264; 0.0720585848953; 
    0.0832337497945; 0.010257395934; 0.0825310101469; 0.0559603534957; 
    0.100287284606; 0.00768849079685; 0.00378892057101; 0.00338064567328; 
    0.00491641833963; 0.0542997240936; 0.0337042799209; 0.0146081646728; 
    0.0119965420605; 0.0119387736448; 0.0963451274984; 0.00819520279264; 
    0.00393985085284; 0.0727125207143; 0.00422558438815; 0.0039804760374; 
    0.0790747796916
  |] in
  
  (* Hard-coded stock tickers *)
  let tickers = [
    "AAPL"; "BA"; "CAT"; "CRM"; "CSCO"; "CVX"; "DIS"; "HD"; "HON"; "IBM";
    "INTC"; "JNJ"; "JPM"; "MCD"; "MMM"; "MRK"; "MSFT"; "NKE"; "PG"; "TRV";
    "UNH"; "V"; "VZ"; "WBA"; "WMT"
  ] in
  
  Printf.printf "Using hard-coded portfolio with Sharpe ratio: %f\n" original_sharpe;
  (original_sharpe, weights, tickers)

(* Print the portfolio composition *)
let print_portfolio weights tickers =
  Printf.printf "\nPortfolio composition:\n";
  List.iteri (fun i ticker -> 
    Printf.printf "%s: %.2f%%\n" ticker (weights.(i) *. 100.0)
  ) tickers

(* Check if a ticker exists in the dataset *)
let ticker_exists ticker stocks =
  List.exists (fun stock -> stock.ticker = ticker) stocks

(* Modified version of the generate_daily_return_matrix function that's more robust *)
let safe_generate_daily_return_matrix stock_data stock_tickers =
  (* First, verify all tickers exist *)
  let all_exist = List.for_all (fun ticker -> ticker_exists ticker stock_data) stock_tickers in
  
  if not all_exist then (
    Printf.printf "WARNING: Not all portfolio tickers exist in the 2025 Q1 dataset!\n";
    Printf.printf "This will affect the accuracy of the evaluation.\n";
  );
  
  (* Filter to only include tickers that exist in the dataset *)
  let valid_tickers = List.filter (fun ticker -> ticker_exists ticker stock_data) stock_tickers in
  
  if List.length valid_tickers < List.length stock_tickers then (
    Printf.printf "Proceeding with %d out of %d tickers.\n" 
      (List.length valid_tickers) (List.length stock_tickers);
  );
  
  (* If no valid tickers, return empty matrix *)
  if List.length valid_tickers = 0 then
    [| |]
  else (
    (* Get the first stock to determine number of days *)
    let first_stock = List.find (fun s -> s.ticker = List.hd valid_tickers) stock_data in
    let total_days = List.length first_stock.dates in
    
    if total_days = 0 then
      [| |]
    else (
      (* Create matrix as an array of arrays *)
      let num_stocks = List.length valid_tickers in
      let result = Array.make_matrix total_days num_stocks 0.0 in
      
      (* Fill the matrix with daily returns *)
      for day = 0 to total_days - 1 do
        for stock_idx = 0 to num_stocks - 1 do
          let ticker = List.nth valid_tickers stock_idx in
          
          (* Find stock data for this ticker *)
          let stock = List.find (fun s -> s.ticker = ticker) stock_data in
          
          (* Calculate return safely (day 0 return is always 0) *)
          let return = 
            if day = 0 then 0.0
            else
              try
                let today_price = List.nth stock.close day in
                let yesterday_price = List.nth stock.close (day-1) in
                (today_price -. yesterday_price) /. yesterday_price
              with _ -> 
                0.0  (* Handle missing data points safely *)
          in
          
          (* Store the return in the matrix *)
          result.(day).(stock_idx) <- return
        done
      done;
      
      result
    )
  )

(* Safe implementation of matrix-vector multiplication *)
let safe_matrix_vector_mul matrix vector =
  let m = Array.length matrix in
  if m = 0 then [| |]  (* Empty matrix case *)
  else (
    let n = Array.length vector in
    let result = Array.make m 0.0 in
    
    for i = 0 to m - 1 do
      let row = matrix.(i) in
      let row_len = Array.length row in
      let sum = ref 0.0 in
      for j = 0 to min row_len n - 1 do
        sum := !sum +. row.(j) *. vector.(j)
      done;
      result.(i) <- !sum
    done;
    
    result
  )

(* Safe calculation of mean *)
let safe_mean arr =
  let len = Array.length arr in
  if len = 0 then 0.0
  else
    let sum = Array.fold_left (+.) 0.0 arr in
    sum /. float_of_int len

(* Safe calculation of standard deviation *)
let safe_std arr =
  let len = Array.length arr in
  if len <= 1 then 0.0
  else
    let m = safe_mean arr in
    let sum_sq_diff = Array.fold_left (fun acc x -> 
      acc +. ((x -. m) ** 2.0)
    ) 0.0 arr in
    sqrt (sum_sq_diff /. float_of_int len)

(* Safe implementation of Sharpe ratio calculation *)
let safe_calculate_sharpe_ratio stock_data weight_vector year_days tickers =
  (* Generate daily return matrix safely *)
  let daily_returns_matrix = safe_generate_daily_return_matrix stock_data tickers in
  
  if Array.length daily_returns_matrix = 0 then (
    Printf.printf "Cannot calculate Sharpe ratio: insufficient data\n";
    nan
  ) else (
    (* Calculate returns *)
    let total_daily_return = safe_matrix_vector_mul daily_returns_matrix weight_vector in
    
    if Array.length total_daily_return = 0 then (
      Printf.printf "Cannot calculate Sharpe ratio: matrix multiplication failed\n";
      nan
    ) else (
      let mean_daily_return = safe_mean total_daily_return in
      let mean_return_annualized = mean_daily_return *. float_of_int year_days in
      
      (* Calculate risk *)
      let daily_volatility = safe_std total_daily_return in
      
      if daily_volatility = 0.0 then (
        Printf.printf "Warning: zero volatility detected\n";
        if mean_return_annualized > 0.0 then infinity else nan
      ) else (
        let annualized_volatility = daily_volatility *. sqrt (float_of_int year_days) in
        mean_return_annualized /. annualized_volatility
      )
    )
  )

(* Calculate the Sharpe ratio for 2025 Q1 data *)
let evaluate_performance (original_sharpe, weights, tickers) =
  try
    Printf.printf "Evaluating portfolio performance in Q1 2025...\n";
    Printf.printf "Original portfolio (2024) Sharpe ratio: %f\n" original_sharpe;
    
    (* Print portfolio composition *)
    print_portfolio weights tickers;
    
    (* Print data available for each ticker *)
    Printf.printf "\nChecking data availability for each ticker in 2025 Q1:\n";
    List.iter (fun ticker ->
      let has_data = ticker_exists ticker dow_jones_2025_stocks in
      Printf.printf "  %s: %s\n" ticker (if has_data then "Available" else "Missing")
    ) tickers;
    
    (* Calculate the Sharpe ratio for 2025 Q1 data with robust error handling *)
    let sharpe_2025 = safe_calculate_sharpe_ratio dow_jones_2025_stocks weights 252 tickers in
    
    if classify_float sharpe_2025 = FP_nan then (
      Printf.printf "\nCould not calculate valid Sharpe ratio for 2025 Q1 data.\n";
      nan
    ) else (
      Printf.printf "\nResults:\n";
      Printf.printf "2025 Q1 Sharpe ratio: %f\n" sharpe_2025;
      Printf.printf "Performance change: %.2f%%\n" 
        ((sharpe_2025 -. original_sharpe) /. original_sharpe *. 100.0);
      
      if sharpe_2025 > original_sharpe then
        Printf.printf "\nThe portfolio performed BETTER in 2025 Q1 than in 2024!\n"
      else
        Printf.printf "\nThe portfolio performed WORSE in 2025 Q1 than in 2024.\n";
        
      sharpe_2025
    )
  with exn ->
    Printf.printf "\nError evaluating portfolio: %s\n" (Printexc.to_string exn);
    Printf.printf "This could be due to missing data or format differences in 2025 Q1 data.\n";
    nan

(* Main function *)
let () =
  Printf.printf "Starting 2025 Q1 portfolio evaluation...\n";
  Printf.printf "=======================================\n\n";
  
  (* Load the hard-coded best portfolio from 2024 *)
  let portfolio = best_portfolio () in
  
  (* Evaluate the portfolio performance on 2025 Q1 data *)
  let _ = evaluate_performance portfolio in
  
  Printf.printf "\nEvaluation complete!\n"
