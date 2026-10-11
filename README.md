# KYC Operations Dashboard (Power BI + SQL)

A two-page Power BI dashboard that tracks KYC onboarding and periodic-review operations: case volumes, turnaround time (TAT) against SLA, screening alerts, EDD backlog, analyst quality and the oldest open EDD cases.

> **All data is synthetic.** Customer names, countries and case records were randomly generated for practice. No real customer data is used.

## What it shows

**Page 1 - KYC Operations Overview**
- KPI cards: total cases (2,552), open cases (40), average TAT (4.9 days), SLA breach % (17.5%), EDD backlog (10), false-positive rate (90.2%)
- Cases opened per month
- Average TAT by risk rating against the SLA allowance (Low 3.3 / Medium 5.6 / High 11.6 days vs SLA 5 / 7 / 10)
- Screening alert outcomes
- High-risk customers by country

**Page 2 - Quality and Team**
- Closed cases (2,512), QC pass rate (92.95%), QC fails (177), true-match alerts (80)
- Analyst performance table with QC pass rate (red = below 92% target)
- False-positive rate by alert type (Sanctions 96.8%, Adverse Media 86.6%, PEP 84.4%)
- Oldest open EDD cases, with age in red when past SLA

## Key takeaways
- High-risk cases average 11.6 days against a 10-day SLA, the only risk tier that runs over.
- About 90% of resolved screening alerts are false positives, so alert tuning would free up analyst time.
- Three analysts sit below the 92% QC target; five open EDD cases are past SLA.

## Tools and skills
Power BI Desktop, DAX (measures, calculated columns, calendar table), data modelling (relationships across analysts, customers, kyc_cases, screening_alerts), SQL (SQLite) for validating figures, conditional formatting and report design.

## Files
- `KYC_Operations_Dashboard.pdf` - both dashboard pages
- `KYC_Operations_Dashboard.pbix` - Power BI file (open with Power BI Desktop)
- `data/` - synthetic CSV files (customers, kyc_cases, screening_alerts, analysts)
- `sql/practice_queries.sql` - SQL queries used to validate the dashboard numbers

## Key DAX measures
```
Total Cases = COUNTROWS(kyc_cases)
Avg TAT (days) = AVERAGEX(FILTER(kyc_cases, kyc_cases[status] = "Closed"), kyc_cases[tat_days])
EDD Backlog = CALCULATE(COUNTROWS(kyc_cases), kyc_cases[edd_required] = 1, kyc_cases[status] <> "Closed")
```

## About
Built by Kirti as a portfolio project while preparing for KYC/AML and financial operations roles.
