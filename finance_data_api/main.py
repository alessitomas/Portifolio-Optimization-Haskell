from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
import yfinance as yf
import pandas as pd
from datetime import datetime
import logging
from typing import Dict, List, Any
import uvicorn
import os

# Configure logging
logging.basicConfig(level=logging.INFO, 
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Dow Jones Stock Data API",
    description="API that retrieves closing prices for Dow Jones components (Aug-Dec 2024)",
    version="1.0.0"
)

# Constants
DATA_DIR = "data"
CSV_FILENAME = f"{DATA_DIR}/dow_jones_data.csv"
START_DATE = "2024-08-01"
END_DATE = "2024-12-31"

def ensure_data_dir():
    """Ensure data directory exists"""
    if not os.path.exists(DATA_DIR):
        os.makedirs(DATA_DIR)

def get_dow_jones_components() -> List[str]:
    """Get current Dow Jones Industrial Average components."""
    # As of 2024, these are the 30 stocks in the Dow Jones Industrial Average
    dow_tickers = [
        "AAPL", "AMGN", "AXP", "BA", "CAT", "CRM", "CSCO", "CVX", "DIS", "DOW",
        "GS", "HD", "HON", "IBM", "INTC", "JNJ", "JPM", "KO", "MCD", "MMM",
        "MRK", "MSFT", "NKE", "PG", "TRV", "UNH", "V", "VZ", "WBA", "WMT"
    ]
    return dow_tickers

def fetch_and_save_data() -> bool:
    """Fetch stock data and save to CSV file"""
    ensure_data_dir()
    
    tickers = get_dow_jones_components()
    logger.info(f"Fetching data for {len(tickers)} Dow Jones components")
    
    # Store all dataframes to combine later
    all_dfs = []
    
    for ticker in tickers:
        try:
            logger.info(f"Fetching data for {ticker}")
            stock = yf.Ticker(ticker)
            data = stock.history(start=START_DATE, end=END_DATE)
            
            if not data.empty:
                # Keep only the Close column
                data = data[['Close']]
                # Add ticker as a column
                data['ticker'] = ticker
                # Reset index to make date a column
                data = data.reset_index()
                # Convert Date column to string to avoid timezone issues
                data['Date'] = data['Date'].dt.strftime('%Y-%m-%d')
                all_dfs.append(data)
                logger.info(f"Successfully retrieved data for {ticker}")
            else:
                logger.warning(f"No data available for {ticker}")
        except Exception as e:
            logger.error(f"Error retrieving data for {ticker}: {e}")
    
    if all_dfs:
        # Combine all data into a single DataFrame
        combined_df = pd.concat(all_dfs)
        # Save to CSV - only Date, Close, and ticker columns
        combined_df.to_csv(CSV_FILENAME, index=False)
        logger.info(f"Saved data to {CSV_FILENAME}")
        return True
    else:
        logger.error("No data was fetched to save")
        return False

def read_csv_data() -> Dict[str, Any]:
    """Read stock data from CSV and format for API response"""
    if not os.path.exists(CSV_FILENAME):
        logger.error(f"CSV file not found: {CSV_FILENAME}")
        return {}
    
    try:
        # Read the CSV file
        df = pd.read_csv(CSV_FILENAME)
        
        # Group by ticker
        grouped = df.groupby('ticker')
        
        # Format data for each ticker - only dates and close values
        all_data = {}
        for ticker, group in grouped:
            # Sort by date
            group = group.sort_values('Date')
            
            stock_dict = {
                'dates': group['Date'].tolist(),
                'close': group['Close'].tolist()
            }
            all_data[ticker] = stock_dict
            
        return all_data
    
    except Exception as e:
        logger.error(f"Error reading CSV data: {e}")
        return {}

@app.get("/api/dow-jones-data", response_class=JSONResponse)
async def dow_jones_data():
    """
    Get closing prices for all Dow Jones components from August 1, 2024 to December 31, 2024.
    
    Returns:
        JSON object containing dates and closing prices for each ticker
    """
    try:
        # Check if CSV exists, if not, fetch and save data
        if not os.path.exists(CSV_FILENAME):
            logger.info("CSV file not found. Fetching new data...")
            success = fetch_and_save_data()
            if not success:
                raise HTTPException(status_code=500, detail="Failed to fetch stock data")
        
        # Read data from CSV
        stock_data = read_csv_data()
        
        if not stock_data:
            logger.error("Failed to read stock data from CSV")
            raise HTTPException(status_code=500, detail="Failed to read stock data from CSV")
        
        # Prepare response
        response = {
            'data': stock_data,
            'metadata': {
                'start_date': START_DATE,
                'end_date': END_DATE,
                'components_count': len(stock_data),
                'components': list(stock_data.keys()),
                'timestamp': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }
        }
        
        return response
    
    except Exception as e:
        logger.error(f"Error processing request: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/")
async def root():
    """Root endpoint that redirects to API documentation."""
    return {"message": "Welcome to Dow Jones Stock API. Visit /docs for API documentation."}

# Fetch data on startup
@app.on_event("startup")
async def startup_event():
    """Fetch and save data when the application starts"""
    logger.info("Application startup: Checking for existing data")
    if not os.path.exists(CSV_FILENAME):
        logger.info("No existing data found. Fetching new data...")
        fetch_and_save_data()
    else:
        logger.info(f"Existing data found at {CSV_FILENAME}")

if __name__ == '__main__':
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)