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

