import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import os



# Read the CSV file
# Since the CSV doesn't have headers, we'll read it as is and extract the implementation type and execution time
data = pd.read_csv("portifolio_opt/data/simulation_results.csv", header=None)

# Extract implementation type (first column) and execution time (last column)
implementations = data[0]
execution_times = data[data.columns[-1]]

# Group by implementation type and calculate statistics
parallel_times = execution_times[implementations == 'Parallel'].astype(float)
sequential_times = execution_times[implementations == 'Sequential'].astype(float)

# Calculate mean and standard deviation
parallel_mean = parallel_times.mean()
sequential_mean = sequential_times.mean()
parallel_std = parallel_times.std()
sequential_std = sequential_times.std()

# Create a bar chart
plt.figure(figsize=(10, 6))
bars = plt.bar(['Parallel', 'Sequential'], 
        [parallel_mean, sequential_mean],
        yerr=[parallel_std, sequential_std],
        capsize=10,
        color=['#3498db', '#e74c3c'])

# Add execution time labels on top of bars
for bar in bars:
    height = bar.get_height()
    plt.text(bar.get_x() + bar.get_width()/2., height + 100,
             f'{height:.2f}s\n({height/60:.1f}min)',
             ha='center', va='bottom', fontsize=12)

# Add a speedup annotation
speedup = sequential_mean / parallel_mean
plt.annotate(f'Speedup: {speedup:.2f}x',
             xy=(0.5, parallel_mean + 1500),
             xytext=(0.5, parallel_mean + 2500),
             arrowprops=dict(arrowstyle='->'),
             ha='center', fontsize=14, color='green')

# Customize the chart
plt.title('Execution Time: Parallel vs Sequential Implementation', fontsize=16)
plt.ylabel('Time (seconds)', fontsize=14)
plt.grid(axis='y', linestyle='--', alpha=0.7)
plt.tight_layout()

# Save the figure
plt.savefig('portfolio_optimization_performance.png', dpi=300, bbox_inches='tight')
print(f"Visualization saved as portfolio_optimization_performance.png")

# Show the plot
plt.show() 