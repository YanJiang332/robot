# Robot Framework Project

This project is structured to follow common Robot Framework best practices.

## Directory Structure

- `tests/`: Contains all Robot Framework test suites (`.robot` files).
- `resources/`: Contains reusable keywords and variable resource files (`.robot` files).
- `libraries/`: Contains custom Python libraries (`.py` files).
- `variables/`: Contains variable files (`.py` or `.yaml` files).
- `results/`: Stores test execution output files (logs, reports, XML).
- `docs/`: For project documentation.
- `config/`: For configuration files.
- `venv/`: Python virtual environment.

## Getting Started

1.  **Create and activate a virtual environment:**
    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

2.  **Install Robot Framework and other dependencies:**
    ```bash
    pip install robotframework
    # pip install -r requirements.txt (if you have one)
    ```

## Running Tests

To run all tests, navigate to the project root and execute:

```bash
robot --outputdir results tests/
```

To run a specific test suite:

```bash
robot --outputdir results tests/your_test_suite.robot
```
