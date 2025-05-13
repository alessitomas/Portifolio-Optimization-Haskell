(* Pure function to generate all combinations of 25 stocks *)
let portifolio_combinations : string list list =
  let stock_tickers = 
    ["AAPL"; "AMGN"; "AXP"; "BA"; "CAT"; "CRM"; "CSCO"; "CVX"; "DIS"; "DOW";
    "GS"; "HD"; "HON"; "IBM"; "INTC"; "JNJ"; "JPM"; "KO"; "MCD"; "MMM";
    "MRK"; "MSFT"; "NKE"; "PG"; "TRV"; "UNH"; "V"; "VZ"; "WBA"; "WMT"] in

  let rec combinations n lst =
    if n = 0 then [[]]
    else match lst with
      | [] -> []
      | h :: t ->
          let with_h = List.map (fun l -> h :: l) (combinations (n-1) t) in
          let without_h = combinations n t in
          with_h @ without_h in

  combinations 25 stock_tickers

let generate_weight_vector () =
  let weights = Array.init 25 (fun _ -> Random.float 0.2) in
  let sum = Array.fold_left (+.) 0.0 weights in
  Array.map (fun x -> x /. sum) weights


open Data_loader
open Lacaml.D  (* Use double precision - D module *)

(* return a 2D array of daily returns *)
let generate_daily_return_matrix (stock_data: stock_data list) (stock_tickers: string list) =
  (* Create matrix as an array of arrays *)
  let total_days = 105 in
  let num_stocks = List.length stock_tickers in
  let result = Array.make_matrix total_days num_stocks 0.0 in
  
  (* Fill the matrix with daily returns *)
  for day = 0 to total_days - 1 do
    for stock_idx = 0 to num_stocks - 1 do
      let ticker = List.nth stock_tickers stock_idx in
      
      (* Find stock data for this ticker *)
      let stock = List.find (fun s -> s.ticker = ticker) stock_data in
      
      (* Calculate return (day 0 return is always 0) *)
      let return = 
        if day = 0 then 0.0
        else
          let today_price = List.nth stock.close day in
          let yesterday_price = List.nth stock.close (day-1) in
          (today_price -. yesterday_price) /. yesterday_price
      in
      
      (* Store the return in the matrix *)
      result.(day).(stock_idx) <- return
    done
  done;
  
  result


(* Matrix-vector multiplication using LACAML for better performance *)
let matrix_vector_mul matrix vector =
  let m = Array.length matrix in
  let n = Array.length vector in
  
  (* Create LACAML matrix from OCaml array *)
  let a = Mat.create m n in
  for i = 1 to m do
    for j = 1 to n do
      (* LACAML uses 1-based indexing *)
      a.{i,j} <- matrix.(i-1).(j-1)
    done
  done;
  
  (* Create LACAML vector from OCaml array *)
  let x = Vec.of_array vector in
  
  (* Perform matrix-vector multiplication using optimized BLAS *)
  let result = gemv a x in
  
  (* Convert back to OCaml array *)
  Vec.to_array result

(* Calculate mean of an array *)
let mean arr =
  let sum = Array.fold_left (+.) 0.0 arr in
  sum /. float_of_int (Array.length arr)

(* Calculate standard deviation of an array *)
let std arr =
  let m = mean arr in
  let sum_sq_diff = Array.fold_left (fun acc x -> 
    acc +. ((x -. m) ** 2.0)
  ) 0.0 arr in
  sqrt (sum_sq_diff /. float_of_int (Array.length arr))

(* Calculate annual return *)
let calculate_annual_return weight_vector daily_returns_matrix year_days =
  let total_daily_return = matrix_vector_mul daily_returns_matrix weight_vector in
  let mean_daily_return = mean total_daily_return in
  let mean_return_annualized = mean_daily_return *. float_of_int year_days in
  (total_daily_return, mean_return_annualized)

(* Calculate annualized standard deviation *)
let calculate_standard_deviation total_daily_return year_days =
  let daily_volatility = std total_daily_return in
  let annualized_volatility = daily_volatility *. sqrt (float_of_int year_days) in
  annualized_volatility

(* Calculate Sharpe ratio *)
let calculate_sharpe_ratio stock_data weight_vector year_days comb =
  let daily_returns_matrix = generate_daily_return_matrix stock_data comb in
  let (total_daily_return, annual_return) = calculate_annual_return weight_vector daily_returns_matrix year_days in
  let annual_vol = calculate_standard_deviation total_daily_return year_days in
  annual_return /. annual_vol