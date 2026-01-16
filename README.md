# accounts-receivable-analytics
This project demonstrates an end-to-end Open Accounts Receivable (AR) analysis built using SQL and a Power BI reporting layer.

# Open Accounts Receivable (AR) Analysis

This repository demonstrates a finance-grade Open Accounts Receivable (AR)
analysis built using SQL and designed for consumption in Power BI.

## Problem
Previous AR reporting was limited in scope and depth of detail and 
only available in a static download to Excel

Finance teams often rely on manual or spreadsheet-based AR reporting that is
slow, difficult to reconcile, and prone to error—especially when handling
partial payments, credits, and aging logic.

## Approach
- SQL-first data transformation, extraction and load
- Accurate AR aging buckets (Current, 30/60/90+)
- Handling partial payments, credits, and as-of date logic using DAX
- Outputs structured for efficient BI consumption and use for operations and accounting teams

## Output
The SQL produces:
- Open AR balances by installment / invoice and customer
- Standard aging buckets for collections and cash flow analysis
- Results that reconcile cleanly to source systems

## Notes
- Table and column names are anonymized
- Focus is on correctness, performance, and financial accuracy
- Intended as a representative example, not a turnkey solution
