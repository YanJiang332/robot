#!/bin/bash

# This script runs all Robot Framework tests from the 'cases' directory
# and saves the output to a timestamped directory under 'results'.

# Define the output directory with a timestamp
OUTPUT_DIR="results/run_$(date +%Y%m%d_%H%M%S)"

# The directory containing all test cases
TEST_DIR="cases"

echo "--- Running all tests in: ${TEST_DIR} ---"
echo "--- Reports will be saved to: ${OUTPUT_DIR} ---"

# Add the libraries directory to PYTHONPATH so Robot Framework can find custom libraries
export PYTHONPATH=$PYTHONPATH:/root/robot_ws/libraries

# Run the robot tests, specifying the output directory
robot -d "${OUTPUT_DIR}" "${TEST_DIR}"

echo "--- Test run complete. ---"
