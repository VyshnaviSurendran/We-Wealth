import enum


class HouseholdRole(str, enum.Enum):
    OWNER = "OWNER"
    MEMBER = "MEMBER"


class MemberStatus(str, enum.Enum):
    INVITED = "INVITED"
    ACTIVE = "ACTIVE"
    REMOVED = "REMOVED"


class AccountType(str, enum.Enum):
    BANK = "BANK"
    CASH = "CASH"
    WALLET = "WALLET"
    CREDIT_CARD = "CREDIT_CARD"
    SAVINGS = "SAVINGS"
    OTHER = "OTHER"


class CategoryType(str, enum.Enum):
    EXPENSE = "EXPENSE"
    INCOME = "INCOME"


class Visibility(str, enum.Enum):
    SHARED = "SHARED"
    PERSONAL = "PERSONAL"


class IncomeStatus(str, enum.Enum):
    EXPECTED = "EXPECTED"
    RECEIVED = "RECEIVED"
    CANCELLED = "CANCELLED"


class ExpenseStatus(str, enum.Enum):
    PENDING = "PENDING"
    PAID = "PAID"
    CANCELLED = "CANCELLED"


class SavingsGoalStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"
    PAUSED = "PAUSED"
    CANCELLED = "CANCELLED"


class BudgetPeriodType(str, enum.Enum):
    MONTHLY = "MONTHLY"
    WEEKLY = "WEEKLY"
    YEARLY = "YEARLY"
    CUSTOM = "CUSTOM"


class RecurringFrequency(str, enum.Enum):
    DAILY = "DAILY"
    WEEKLY = "WEEKLY"
    MONTHLY = "MONTHLY"
    YEARLY = "YEARLY"
    CUSTOM = "CUSTOM"


class RecurringBillStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    PAUSED = "PAUSED"
    CANCELLED = "CANCELLED"


DEFAULT_EXPENSE_CATEGORIES = [
    "Food",
    "Rent",
    "Utilities",
    "Travel",
    "Shopping",
    "Medical",
    "Education",
    "Entertainment",
    "Insurance",
    "Subscriptions",
    "Loan",
    "Family",
    "Personal",
    "Other",
]

DEFAULT_INCOME_CATEGORIES = [
    "Salary",
    "Freelance",
    "Business",
    "Interest",
    "Bonus",
    "Gift",
    "Other",
]
