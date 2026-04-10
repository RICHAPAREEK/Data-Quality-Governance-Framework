# Data Quality & Governance Framework
## RBI Scheduled Commercial Banks — NPA Dataset
**Source:** [data.gov.in](https://www.data.gov.in) | Ministry of Finance / Reserve Bank of India  
**Tools:** SQL (SQLite) · Excel · DB Browser for SQLite  
**Domain:** Banking & Financial Risk | Data Governance

---

## Project Overview

End-to-end data governance project on real Indian government data — NPA (Non-Performing Assets) written-off and recovery figures for Scheduled Commercial Banks published by the Reserve Bank of India via India's Open Government Data Platform.

The project covers the full governance lifecycle:
- Data profiling to understand structure and quality
- 10 SQL-based Data Quality rules across 6 DQ dimensions
- Critical business rule violation discovery (recovery exceeding written-off)
- Data Dictionary with Critical Data Elements (CDEs) and sensitivity classification
- DQ Scorecard with remediation actions and responsible owners
- Data Lineage from source to final deliverable

---

## Datasets Used

| Dataset | Source | Rows | Columns |
|---|---|---|---|
| Bank-wise NPA Written-off (2019–2025) | data.gov.in — Rajya Sabha Session 267 | 79 | 8 |
| Bank-wise NPA Recovery (2019–2025) | data.gov.in — Rajya Sabha Session 266 | 18 | 8 |

**Direct links:**
- [NPA Written-off dataset](https://www.data.gov.in/resource/bank-wise-details-non-performing-assets-npa-written-scheduled-commercial-banks-2019-20)
- [NPA Recovery dataset](https://www.data.gov.in/resource/bank-wise-details-recovery-non-performing-assets-npas-public-sector-banks-2019-20-2024-25)

---

## Data Lineage

```
data.gov.in (RBI / Ministry of Finance)
        │
        ▼
npa_writtenoff.csv (79 rows)    npa_recovery.csv (18 rows)
        │                               │
        └──────────────┬────────────────┘
                       ▼
            SQLite Database (DB Browser)
            banking_governance.db
                       │
                       ▼
            Data Profiling (8 SQL queries)
            → Nulls · Duplicates · Type issues · Referential gaps
                       │
                       ▼
            10 DQ Rules (6 dimensions)
            → 8 FAIL · 2 PASS · 3 Critical findings
                       │
                       ▼
        ┌──────────────┬──────────────┬──────────────┐
        ▼              ▼              ▼               ▼
  Data Dictionary  DQ Rule       DQ Scorecard   Lineage
  (16 columns,     Register      (64.5% score,  Diagram
   CDEs flagged)   (10 rules)     5 findings)
```

---

## Data Profiling Results

| Check | npa_writtenoff | npa_recovery |
|---|---|---|
| Total rows | 79 | 18 |
| Unique banks | 78 | 18 |
| Null / NA values (2021-22) | 22 | 6 |
| Duplicate bank names | 1 (HSBC) | 0 |
| Banks missing from other table | 61 | 0 |

**Key structural finding:** The recovery dataset covers only 18 Public Sector Banks (PSBs), while the written-off dataset covers all 79 scheduled commercial banks including private, foreign, and small finance banks. This is a dataset scope boundary issue — not a data error — and is documented in the data dictionary.

---

## DQ Rules Summary

| Rule ID | Dimension | Rule | Failures | Score | Severity | Status |
|---|---|---|---|---|---|---|
| DQ-001 | Completeness | NPA values not null | 29/79 | 63.3% | High | FAIL |
| DQ-002 | Uniqueness | No duplicate banks | 1/79 | 98.7% | Critical | FAIL |
| DQ-003 | Validity | NPA values are numeric | 0/57 | 100% | High | PASS |
| DQ-004 | Validity | NPA values are positive | 0/57 | 100% | Medium | PASS |
| DQ-005 | Referential Integrity | Every bank has recovery record | 61/79 | 22.8% | Critical | FAIL |
| DQ-006 | Consistency | Column names match across tables | 1/2 | 50% | Medium | FAIL |
| DQ-007 | Completeness | Recovery data 80% complete per year | 6/18 | 66.7% | High | FAIL |
| DQ-008 | Timeliness | Latest year data present | 6/18 | 66.7% | Medium | FAIL |
| DQ-009 | Business Rule | Recovery ≤ Written-off | 4/12 | 66.7% | Critical | FAIL |
| DQ-010 | Referential Integrity | Recovery banks match written-off | 0/18 | 100% | Critical | PASS |

**Overall DQ Score: 64.5%**

---

## Star Finding — Critical Business Rule Violation (DQ-009)

4 major Public Sector Banks show recovery amounts **exceeding** written-off NPA — which is logically impossible under standard NPA accounting:

| Bank | Written-off (₹ Cr) | Recovery (₹ Cr) | Excess (₹ Cr) |
|---|---|---|---|
| Canara Bank | 8,422 | 11,324 | **+2,902** |
| Central Bank of India | 1,236 | 3,441 | **+2,205** |
| Punjab National Bank | 18,312 | 19,229 | **+917** |
| Punjab and Sind Bank | 1,134 | 1,273 | **+139** |

**Root cause analysis:** Post-merger recovery from absorbed banks (e.g. Syndicate Bank merged into Canara, OBC + United Bank merged into PNB) is being reported under the surviving entity — inflating recovery figures against the pre-merger written-off base. Documented as a data lineage break requiring period-adjustment notes.

---

## Critical Findings & Remediation

| Finding | Rule | Issue | Remediation | Owner |
|---|---|---|---|---|
| F-001 | DQ-002 | HSBC duplicate — 2 rows with different values | Investigate: separate legal entities or reporting split | Data Owner |
| F-002 | DQ-005 | 61 banks have no recovery record | Document dataset scope boundary — PSBs only | Data Steward |
| F-003 | DQ-009 | 4 banks recovery > written-off | Apply merger period-adjustment note | Finance Team |
| F-004 | DQ-006 | 2024-25 column name inconsistent across tables | Standardise column names before any JOIN | Data Engineer |
| F-005 | DQ-008 | 6 merged banks show NA in latest year | Add Bank_Status column: Active / Merged / Exited | Data Steward |

---

## Repository Structure

```
📁 npa-data-governance/
│
├── 📄 README.md                          ← This file
├── 📄 NPA_Data_Governance_Framework.xlsx ← Full governance deliverable (4 sheets)
│
├── 📁 data/
│   ├── npa_writtenoff.csv               ← Source: data.gov.in
│   └── npa_recovery.csv                 ← Source: data.gov.in
│
├── 📁 sql/
│   ├── 01_profiling.sql                 ← 8 data profiling queries
│   └── 02_dq_rules.sql                  ← 10 DQ rule queries
│
└── 📁 screenshots/
    ├── profiling_results.png
    ├── dq_scorecard.png
    └── rule9_violation.png
```

---

## Excel Deliverable — 4 Sheets

| Sheet | Contents |
|---|---|
| Cover | Project metadata, document index, data source |
| Data Dictionary | 16 columns, business definitions, CDE flags, sensitivity levels |
| DQ Rule Register | 10 rules, SQL logic, failure counts, severity, root cause |
| DQ Scorecard | KPI summary, score by dimension, critical findings register |

---

## Key Governance Concepts Demonstrated

- **Data Profiling** — Null analysis, duplicate detection, type validation, referential integrity checks
- **Critical Data Elements (CDEs)** — Identified and flagged in data dictionary
- **Data Classification** — Public / Internal / Confidential sensitivity levels assigned
- **Data Lineage** — Source → ingest → profiling → DQ rules → output documented
- **DQ Dimensions** — Completeness, Uniqueness, Validity, Referential Integrity, Consistency, Timeliness, Business Rules
- **Root Cause Analysis** — Bank mergers, dataset scope boundaries, period-adjustment issues
- **Remediation Planning** — Each finding has a documented action and responsible owner

---

## Skills Demonstrated

`SQL` `Data Governance` `Data Quality Rules` `Data Profiling` `Data Dictionary` `Critical Data Elements` `Data Lineage` `Excel` `Banking Domain` `RBI Data` `SQLite` `Stakeholder Reporting`

---

## About

**Richa Pareek** | Data Analyst | [LinkedIn](https://linkedin.com/in/) | [GitHub](https://github.com/)  
M.Sc. Mathematics | Ex-Citi Bank | Ex-Axis Bank  
Specialisation: Banking analytics, risk data, data governance frameworks
