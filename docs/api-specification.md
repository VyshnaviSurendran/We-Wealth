# API Specification

Base prefix: `/api/v1`. Interactive docs at `/docs` (Swagger) and `/redoc`.
Auth: `Authorization: Bearer <access_token>` (JWT, obtained from
`POST /auth/login`).

## Auth

| Method | Path | Notes |
|---|---|---|
| POST | `/auth/register` | |
| POST | `/auth/login` | returns `access_token` + `user` |
| GET | `/auth/me` | |
| POST | `/auth/change-password` | |
| PATCH | `/users/me` | |

## Households

| Method | Path |
|---|---|
| POST | `/households` |
| GET | `/households` |
| GET | `/households/{household_id}` |
| PATCH | `/households/{household_id}` |
| POST | `/households/{household_id}/invitations` |
| POST | `/invitations/{invitation_id}/accept` |
| GET | `/households/{household_id}/members` |
| PATCH | `/households/{household_id}/members/{member_id}` |

## Accounts

| Method | Path |
|---|---|
| POST | `/households/{household_id}/accounts` |
| GET | `/households/{household_id}/accounts` (filters: `account_type`, `owner_user_id`, `is_shared`, `is_active`) |
| GET | `/accounts/{account_id}` (includes `actual_balance`, `pending_amount`, `safe_available_balance`) |
| PATCH | `/accounts/{account_id}` |
| DELETE | `/accounts/{account_id}` (soft-archive: `is_active = false`) |
| GET | `/accounts/{account_id}/transactions` (filters: `from_date`, `to_date`, `transaction_type`) |

## Categories

| Method | Path |
|---|---|
| POST | `/households/{household_id}/categories` |
| GET | `/households/{household_id}/categories` (filters: `category_type`, `is_active`) |
| PATCH | `/categories/{category_id}` |

## Incomes / Expenses / Transfers

| Method | Path |
|---|---|
| POST/GET | `/households/{household_id}/incomes` |
| GET/PATCH | `/incomes/{income_id}` |
| POST/GET | `/households/{household_id}/expenses` |
| GET/PATCH | `/expenses/{expense_id}` |
| POST | `/expenses/{expense_id}/pay` (moves `PENDING` → `PAID`, affects account balance) |
| POST/GET | `/households/{household_id}/transfers` |
| GET | `/transfers/{transfer_id}` |

## Savings / Budgets / Recurring bills

| Method | Path |
|---|---|
| POST/GET | `/households/{household_id}/savings-goals` |
| GET/PATCH | `/savings-goals/{goal_id}` |
| POST | `/savings-goals/{goal_id}/contributions` |
| POST/GET | `/households/{household_id}/budgets` |
| GET/PATCH | `/budgets/{budget_id}` |
| POST/GET | `/households/{household_id}/recurring-bills` |
| GET/PATCH | `/recurring-bills/{bill_id}` |

## Dashboard / Reports

| Method | Path |
|---|---|
| GET | `/households/{household_id}/dashboard/summary` |
| GET | `/households/{household_id}/reports/monthly?year=&month=` |

This list reflects the routes actually registered — cross-check against
`GET /openapi.json` if the two ever drift.
