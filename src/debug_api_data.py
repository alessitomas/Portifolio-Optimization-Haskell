import requests
import json
from pprint import pprint
import sys

API_BASE_URL = "http://0.0.0.0:8000"

def fetch_data(endpoint):
    """Fetch data from API endpoint"""
    url = f"{API_BASE_URL}{endpoint}"
    print(f"Fetching data from: {url}")
    
    try:
        response = requests.get(url)
        response.raise_for_status()
        return response.json()
    except Exception as e:
        print(f"Error fetching data: {e}")
        return None

def analyze_data(data_2024, data_2025):
    """Compare and analyze both datasets"""
    if not data_2024 or not data_2025:
        print("Cannot analyze: One or both datasets are missing")
        return
    
    # Check metadata
    print("\n=== Metadata Comparison ===")
    print(f"2024 Data: {data_2024['metadata']['start_date']} to {data_2024['metadata']['end_date']}")
    print(f"2025 Data: {data_2025['metadata']['start_date']} to {data_2025['metadata']['end_date']}")
    
    # Check component counts
    print(f"\n2024 Components: {data_2024['metadata']['components_count']}")
    print(f"2025 Components: {data_2025['metadata']['components_count']}")
    
    # Check for missing tickers
    tickers_2024 = set(data_2024['metadata']['components'])
    tickers_2025 = set(data_2025['metadata']['components'])
    
    print("\n=== Missing Tickers ===")
    if tickers_2024 != tickers_2025:
        print("The datasets have different tickers!")
        missing_in_2025 = tickers_2024 - tickers_2025
        missing_in_2024 = tickers_2025 - tickers_2024
        
        if missing_in_2025:
            print(f"Tickers in 2024 but not in 2025: {', '.join(missing_in_2025)}")
        if missing_in_2024:
            print(f"Tickers in 2025 but not in 2024: {', '.join(missing_in_2024)}")
    else:
        print("Both datasets have the same tickers.")
    
    # Check data points per ticker
    print("\n=== Data Points Per Ticker ===")
    print("Ticker | 2024 Data Points | 2025 Data Points")
    print("------|-----------------|---------------")
    
    # Portfolio tickers to check
    portfolio_tickers = [
        "AAPL", "BA", "CAT", "CRM", "CSCO", "CVX", "DIS", "HD", "HON", "IBM",
        "INTC", "JNJ", "JPM", "MCD", "MMM", "MRK", "MSFT", "NKE", "PG", "TRV",
        "UNH", "V", "VZ", "WBA", "WMT"
    ]
    
    for ticker in portfolio_tickers:
        dates_2024 = len(data_2024['data'].get(ticker, {}).get('dates', []))
        dates_2025 = len(data_2025['data'].get(ticker, {}).get('dates', []))
        print(f"{ticker} | {dates_2024} | {dates_2025}")
        
        # Alert if ticker is missing or has insufficient data
        if dates_2024 == 0 or dates_2025 == 0:
            print(f"⚠️ WARNING: {ticker} is missing data in {'2024' if dates_2024 == 0 else '2025'}")
    
    # Check number of days (for validation)
    print("\n=== Data Length Analysis ===")
    if data_2024['data'] and len(data_2024['data']) > 0:
        first_ticker_2024 = next(iter(data_2024['data']))
        print(f"2024 data covers {len(data_2024['data'][first_ticker_2024]['dates'])} days")
    
    if data_2025['data'] and len(data_2025['data']) > 0:
        first_ticker_2025 = next(iter(data_2025['data']))
        print(f"2025 data covers {len(data_2025['data'][first_ticker_2025]['dates'])} days")

def main():
    # Fetch data from both endpoints
    data_2024 = fetch_data("/api/dow-jones-data")
    data_2025 = fetch_data("/api/dow-jones-data/2025")
    
    # Analyze and compare
    analyze_data(data_2024, data_2025)
    
    # Option to save full JSON response for detailed inspection
    if len(sys.argv) > 1 and sys.argv[1] == "--save":
        with open("api_response_2024.json", "w") as f:
            json.dump(data_2024, f, indent=2)
        with open("api_response_2025.json", "w") as f:
            json.dump(data_2025, f, indent=2)
        print("\nSaved full API responses to api_response_2024.json and api_response_2025.json")

if __name__ == "__main__":
    main() 