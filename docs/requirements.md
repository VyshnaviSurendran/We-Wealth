# Requirements

## Purpose

Backend for a couple-focused finance app: shared household finances with
support for personal vs. shared visibility, pending vs. paid expenses,
transfers between accounts, savings goals, budgets, and recurring bills.

## Core business rules

- **Actual balance** = opening balance + received income + transfers in
  − paid expenses − transfers out. Computed on read from ledger rows
  (incomes/expenses/transfers), not stored, to avoid drift.
- **Pending balance** = sum of `PENDING` expenses tied to an account. Pending
  expenses do not affect actual balance until marked `PAID`.
- **Safe available balance** = actual balance − pending balance.
- **Transfers** move money between two accounts in the same household. They
  are never expenses or income, and never change net worth.
- **Savings goals** are targets/allocations, not separate pots of money.
  Money already sitting in a savings account is counted via that account's
  balance; a goal's `current_amount` must not be added again when computing
  net worth (avoids double counting).
- **Visibility**: every income, expense, savings goal, budget, and recurring
  bill is `SHARED` or `PERSONAL`.

## Household membership

- A household has members with role `OWNER` or `MEMBER`, and status
  `INVITED`, `ACTIVE`, or `REMOVED`.
- All household-scoped resources (accounts, categories, incomes, expenses,
  transfers, savings goals, budgets, recurring bills) require the requesting
  user to be an `ACTIVE` member of that household.

See `database-design.md` for the schema and `api-specification.md` for the
implemented endpoints.
