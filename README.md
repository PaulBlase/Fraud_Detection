# Assessing Fraudulent Transactions

Repo of files created for final project in DSBA 6156. Project was run on synthesize transaction data to test fraud detection, provided on Kaggle (https://www.kaggle.com/ntnu-testimon/paysim1).

## Files

DSBA6156_FP_Logistic_Regression: Initial model run by group in order to evaluate data. Data manipulation, correlation heat map, and logistic regression to evaluate for fraudulent transactions.

Fraud_ML_Code: Continued assessment of dataset using random forest on both full and trimmed models to assess data.

## Assessment of data
A quick overview of the data details some aspects of the set as whole to account for when assessing for fraud:\

- **Dimensions:** 6,362,620 Observations, 11 Features
  - 8,213 Fraudulent (0.13%)
  - 6,354,407 Not Fraudulent (99.87%)
- **Fraud Transactions:**
  - Transaction Type: Transfer Or Cash Withdraw(~50/50)
  - Destination Account Type: Customer (Not Merchant)
- **Fraudulent Amount Range:**
  - Range: 0-10,000,000
  - Strong Left Skewed

In understanding the data, the team moved to implement dummy variables for transaction types, as well as a binary for the account type of the destination. Along with this, columns with nonvital information were dropped, such as flagged fraud. This left us with nine variables to test for fraud.
