open Lwt
open Cohttp_lwt_unix

let prod_env = false
let api_url = if prod_env then "http://44.200.31.239:8000" else "http://0.0.0.0:8000"

let get_dow_jones =
  Client.get (Uri.of_string (api_url ^ "/api/dow-jones-data")) >>= fun (_, body) ->
  body |> Cohttp_lwt.Body.to_string ;;

let dow_jones_data = Lwt_main.run get_dow_jones ;;

(* json string to yojson *)
let dow_jones_data_yojson = Yojson.Basic.from_string dow_jones_data ;;

type stock_data = {
  ticker: string;
  close: float list;
  dates: string list;
}

let get_stock_data json =
  let open Yojson.Basic.Util in
  let data = json |> member "data" in
  let tickers = data |> keys in
  List.map (fun ticker ->
    let stock = data |> member ticker in
    {
      ticker = ticker;
      close = stock |> member "close" |> to_list |> List.map to_float;
      dates = stock |> member "dates" |> to_list |> List.map to_string;
    }
  ) tickers

let dow_jones_stocks = get_stock_data dow_jones_data_yojson

(* fucntion to print each record *)
let print_stock_data stock =
  print_endline ("Ticker: " ^ stock.ticker);
  print_endline ("Dates: " ^ String.concat ", " stock.dates);
  print_endline ("Close: " ^ String.concat ", " (List.map string_of_float stock.close));

