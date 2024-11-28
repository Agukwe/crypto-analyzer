# Crypto Analyzer Smart Contract

The **Crypto Analyzer** smart contract is a Clarity-based application for analyzing cryptocurrency prices. It allows tracking price data, calculating percentage changes, and determining the profitability of coins based on configurable thresholds. 

## Features
- **Price Tracking**: Record and update current and previous prices for specific cryptocurrencies.
- **Profitability Analysis**: Automatically calculate percentage changes and determine whether a coin is profitable based on a user-defined threshold.
- **Customizable Thresholds**: Configure profitability thresholds for individual coins.
- **Data Queries**: Read-only functions to retrieve stored coin data and thresholds.

---

## Contract Details

### Constants
- **`contract-owner`**: The owner of the contract, initialized as the deployer.
- **Error Codes**:
  - `err-owner-only` (`u100`): Only the contract owner can perform certain actions.
  - `err-invalid-price` (`u101`): Invalid price input (must be greater than 0).
  - `err-no-previous-price` (`u102`): No previous price is available for calculation.
- **Calculation Multiplier**: `PERCENTAGE_MULTIPLIER` (`u100`) for percentage change calculations.

### Data Maps
- **`CoinPrices`**:
  - **Key**: `{ coin: string-ascii (10) }`
  - **Value**: 
    - `current-price`: Latest price of the coin (uint).
    - `previous-price`: Previous price of the coin (uint).
    - `timestamp`: Block height when the price was updated (uint).
    - `percentage-change`: Change in price as a percentage (int).
    - `is-profitable`: Whether the coin is considered profitable (bool).
- **`ProfitabilitySettings`**:
  - **Key**: `{ coin: string-ascii (10) }`
  - **Value**: 
    - `threshold`: Profitability threshold percentage (uint).

---

## Public Functions

### `set-coin-price`
- **Description**: Update the current price of a coin and compute profitability.
- **Parameters**:
  - `coin` (`string-ascii (10)`): The coin's ticker symbol.
  - `price` (`uint`): The new price of the coin.
- **Returns**: `true` on success.
- **Errors**:
  - `err-owner-only`: Only the contract owner can set prices.
  - `err-invalid-price`: The price must be greater than 0.

### `set-profitability-threshold`
- **Description**: Configure the profitability threshold for a specific coin.
- **Parameters**:
  - `coin` (`string-ascii (10)`): The coin's ticker symbol.
  - `threshold` (`uint`): The percentage threshold.
- **Returns**: `true` on success.
- **Errors**:
  - `err-owner-only`: Only the contract owner can set thresholds.

---

## Read-Only Functions

### `get-coin-data`
- **Description**: Retrieve data for a specific coin.
- **Parameters**:
  - `coin` (`string-ascii (10)`): The coin's ticker symbol.
- **Returns**:
  - A map containing:
    - `current-price` (`uint`): The latest price.
    - `previous-price` (`uint`): The last recorded price.
    - `timestamp` (`uint`): Block height of the last update.
    - `percentage-change` (`int`): Change in percentage.
    - `is-profitable` (`bool`): Profitability status.

### `get-profitability-threshold`
- **Description**: Retrieve the profitability threshold for a specific coin.
- **Parameters**:
  - `coin` (`string-ascii (10)`): The coin's ticker symbol.
- **Returns**:
  - A map containing:
    - `threshold` (`uint`): The profitability threshold. Defaults to `200` (2%) if not set.

---

## Private Functions

### `calculate-percentage-change`
- **Description**: Calculate the percentage change between two prices.
- **Parameters**:
  - `old-price` (`uint`): The previous price.
  - `new-price` (`uint`): The current price.
- **Returns**: Percentage change as an `int`.

### `check-profitability`
- **Description**: Check if a coin's price change exceeds the threshold.
- **Parameters**:
  - `coin` (`string-ascii (10)`): The coin's ticker symbol.
  - `change` (`int`): Percentage change.
- **Returns**: `true` if profitable, `false` otherwise.

---

## Deployment and Usage

1. **Deployment**: Deploy the contract to the desired blockchain network using the Clarity development tools like `clarinet`.
2. **Set Coin Price**: Use `set-coin-price` to update price data for a coin.
3. **Set Profitability Threshold**: Configure thresholds using `set-profitability-threshold`.
4. **Query Data**: Retrieve data using read-only functions:
   - `get-coin-data` for coin-specific information.
   - `get-profitability-threshold` for threshold settings.

---

## Development Tools

- **Clarity**: A functional, decidable smart contract language.
- **Clarinet**: For testing and debugging.

### Testing
Use `clarinet test` to execute predefined tests for the contract. Ensure all test cases pass to validate the logic.

---

## License

This project is licensed under the MIT License. Feel free to use, modify, and distribute with attribution.