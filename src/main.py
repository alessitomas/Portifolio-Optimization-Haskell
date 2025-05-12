import requests

def get_dowjones_data(url):
    response = requests.get(url)
    response_json = response.json()
    stock_data = response_json["data"]
    return stock_data

import numpy as np
def generate_daily_return_matrix(stock_data, stock_tickets, total_days=105):
    # days x stocks
    daily_return_matix = []

    for index in range(0, total_days):
        closed_by_day = []
        for stock in stock_tickets:
            stock_closed_value = 0 if index == 0 else (stock_data[stock]["close"][index] - stock_data[stock]["close"][index-1]) / stock_data[stock]["close"][index-1]
            closed_by_day.append(stock_closed_value)
        daily_return_matix.append(closed_by_day)
    
    return np.array(daily_return_matix)


def calculate_anual_return(weight_vector, daily_returns_matix, year_days):
    total_daily_return = daily_returns_matix @ weight_vector
    mean_daily_return = total_daily_return.mean()
    mean_return_annualized = mean_daily_return * year_days
    return total_daily_return, mean_return_annualized
    

def calculate_standard_deviation(total_daily_return, year_days):
    daily_volatility = total_daily_return.std()
    annualized_volatility = daily_volatility * np.sqrt(year_days)
    return annualized_volatility

def calculate_sharpe_ratio(stock_data, weight_vector, year_days, comb):
    daily_returns_matrix = generate_daily_return_matrix(stock_data, comb)
    total_daily_return, anual_return = calculate_anual_return(weight_vector, daily_returns_matrix, year_days)
    annual_vol = calculate_standard_deviation(total_daily_return, year_days)
    return anual_return / annual_vol

import numpy as np
import copy
def generate_all_combs(dow_tickers):
    all_combs = [] 
    visited_index = set()
    
    def backtrack_all_combs(curr_comb, index):
        if len(curr_comb) == 25:
            all_combs.append(copy.deepcopy(curr_comb))
            return
        
        for i in range(index + 1, len(dow_tickers)):
            if i not in visited_index:
                curr_comb.append(dow_tickers[i])
                visited_index.add(i)
                backtrack_all_combs(curr_comb, i)

                curr_comb.pop(-1)
                visited_index.remove(i)
    
    backtrack_all_combs([], -1)
    return all_combs



def generate_weight_vector():
    weights = np.random.uniform(0.0, 0.2, 25)
    normalized_weights = weights / weights.sum()
    return np.array(normalized_weights)

def generate_simulations(stock_data, stock_tickets, year_days=252):
    total_combinations = generate_all_combs(stock_tickets)
    print("Calculated all combinations")
    best_sharpe = float("-inf")
    best_weights = None
    best_comb = None
    for comb_index, comb in enumerate(total_combinations):
        for i in range(1000):
            stock_weights = generate_weight_vector()
            sharpe_ratio = calculate_sharpe_ratio(stock_data, stock_weights, year_days, comb)
            if sharpe_ratio > best_sharpe:
                best_sharpe = sharpe_ratio
                best_comb = comb
                best_weights = stock_weights
            print(f"Calculate Sharpe Ratio: {sharpe_ratio} , for comb {comb_index}")

         

def main():
    url = "http://0.0.0.0:8000/api/dow-jones-data"
    
    stock_data = get_dowjones_data(url)
    print("Data loaded!")
    
    DOW_TICKERS = [
    "AAPL", "AMGN", "AXP", "BA", "CAT", "CRM", "CSCO", "CVX", "DIS", "DOW",
    "GS", "HD", "HON", "IBM", "INTC", "JNJ", "JPM", "KO", "MCD", "MMM",
    "MRK", "MSFT", "NKE", "PG", "TRV", "UNH", "V", "VZ", "WBA", "WMT"
    ]
    print("Starting Simulation")
    generate_simulations(stock_data, DOW_TICKERS)


main()