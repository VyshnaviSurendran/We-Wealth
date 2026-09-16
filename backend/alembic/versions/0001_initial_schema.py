"""initial schema

Revision ID: 0001
Revises:
Create Date: 2026-09-15
"""

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def _uuid_pk() -> sa.Column:
    return sa.Column(
        "id",
        postgresql.UUID(as_uuid=True),
        primary_key=True,
        server_default=sa.text("gen_random_uuid()"),
    )


def _timestamps() -> list[sa.Column]:
    return [
        sa.Column(
            "created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
        sa.Column(
            "updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False
        ),
    ]


def upgrade() -> None:
    op.execute('CREATE EXTENSION IF NOT EXISTS "pgcrypto"')

    op.create_table(
        "users",
        _uuid_pk(),
        sa.Column("name", sa.String(150), nullable=False),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("phone", sa.String(30), nullable=True),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        *_timestamps(),
    )
    op.create_index("ix_users_email", "users", ["email"])

    op.create_table(
        "households",
        _uuid_pk(),
        sa.Column("name", sa.String(150), nullable=False),
        sa.Column(
            "created_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False
        ),
        sa.Column("currency", sa.String(3), nullable=False, server_default="INR"),
        sa.Column("timezone", sa.String(64), nullable=False, server_default="Asia/Kolkata"),
        *_timestamps(),
    )

    op.create_table(
        "household_members",
        _uuid_pk(),
        sa.Column(
            "household_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("households.id"),
            nullable=False,
        ),
        sa.Column(
            "user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False
        ),
        sa.Column(
            "role",
            sa.Enum("OWNER", "MEMBER", name="household_role"),
            nullable=False,
            server_default="MEMBER",
        ),
        sa.Column(
            "status",
            sa.Enum("INVITED", "ACTIVE", "REMOVED", name="member_status"),
            nullable=False,
            server_default="ACTIVE",
        ),
        sa.Column("joined_at", sa.DateTime(timezone=True), nullable=True),
    )

    op.create_table(
        "household_invitations",
        _uuid_pk(),
        sa.Column(
            "household_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("households.id"),
            nullable=False,
        ),
        sa.Column("email", sa.String(255), nullable=False),
        sa.Column(
            "invited_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False
        ),
        sa.Column(
            "status",
            sa.Enum("INVITED", "ACTIVE", "REMOVED", name="member_status"),
            nullable=False,
            server_default="INVITED",
        ),
        *_timestamps(),
    )

    op.create_table(
        "categories",
        _uuid_pk(),
        sa.Column(
            "household_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("households.id"),
            nullable=False,
        ),
        sa.Column("name", sa.String(100), nullable=False),
        sa.Column(
            "category_type", sa.Enum("EXPENSE", "INCOME", name="category_type"), nullable=False
        ),
        sa.Column("is_shared", sa.Boolean, nullable=False, server_default=sa.true()),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        *_timestamps(),
    )

    op.create_table(
        "accounts",
        _uuid_pk(),
        sa.Column(
            "household_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("households.id"),
            nullable=False,
        ),
        sa.Column(
            "owner_user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True
        ),
        sa.Column("name", sa.String(150), nullable=False),
        sa.Column(
            "account_type",
            sa.Enum(
                "BANK", "CASH", "WALLET", "CREDIT_CARD", "SAVINGS", "OTHER", name="account_type"
            ),
            nullable=False,
        ),
        sa.Column("opening_balance", sa.Numeric(14, 2), nullable=False, server_default="0.00"),
        sa.Column("is_shared", sa.Boolean, nullable=False, server_default=sa.false()),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default=sa.true()),
        *_timestamps(),
    )

    op.create_table(
        "incomes",
        _uuid_pk(),
        sa.Column(
            "household_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("households.id"),
            nullable=False,
        ),
        sa.Column(
            "account_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("accounts.id"),
            nullable=False,
        ),
        sa.Column(
            "owner_user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id"),
            nullable=False,
        ),
        sa.Column(
            "category_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("categories.id"),
            nullable=True,
        ),
        sa.Column("title", sa.String(150), nullable=False),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("income_date", sa.Date, nullable=False),
        sa.Column(
            "status",
            sa.Enum("EXPECTED", "RECEIVED", "CANCELLED", name="income_status"),
            nullable=False,
            server_default="RECEIVED",
        ),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column(
            "visibility",
            sa.Enum("SHARED", "PERSONAL", name="visibility"),
            nullable=False,
            server_default="SHARED",
        ),
        sa.Column(
            "created_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False
        ),
        *_timestamps(),
    )

    op.create_table(
        "expenses",
        _uuid_pk(),
        sa.Column(
            "household_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("households.id"),
            nullable=False,
        ),
        sa.Column(
            "account_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("accounts.id"),
            nullable=False,
        ),
        sa.Column(
            "paid_by_user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id"),
            nullable=False,
        ),
        sa.Column(
            "category_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("categories.id"),
            nullable=True,
        ),
        sa.Column("title", sa.String(150), nullable=False),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("expense_date", sa.Date, nullable=False),
        sa.Column("due_date", sa.Date, nullable=True),
        sa.Column(
            "status",
            sa.Enum("PENDING", "PAID", "CANCELLED", name="expense_status"),
            nullable=False,
            server_default="PAID",
        ),
        sa.Column(
            "visibility",
            sa.Enum("SHARED", "PERSONAL", name="visibility"),
            nullable=False,
            server_default="SHARED",
        ),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column(
            "created_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False
        ),
        *_timestamps(),
    )

    op.create_table(
        "transfers",
        _uuid_pk(),
        sa.Column(
            "household_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("households.id"),
            nullable=False,
        ),
        sa.Column(
            "from_account_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("accounts.id"),
            nullable=False,
        ),
        sa.Column(
            "to_account_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("accounts.id"),
            nullable=False,
        ),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("transfer_date", sa.Date, nullable=False),
        sa.Column("notes", sa.Text, nullable=True),
        sa.Column(
            "created_by", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=False
        ),
        *_timestamps(),
        sa.CheckConstraint("from_account_id != to_account_id", name="ck_transfer_diff_accounts"),
        sa.CheckConstraint("amount > 0", name="ck_transfer_amount_positive"),
    )

    op.create_table(
        "savings_goals",
        _uuid_pk(),
        sa.Column(
            "household_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("households.id"),
            nullable=False,
        ),
        sa.Column(
            "owner_user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True
        ),
        sa.Column("name", sa.String(150), nullable=False),
        sa.Column("target_amount", sa.Numeric(14, 2), nullable=False),
        sa.Column("current_amount", sa.Numeric(14, 2), nullable=False, server_default="0.00"),
        sa.Column("target_date", sa.Date, nullable=True),
        sa.Column(
            "visibility",
            sa.Enum("SHARED", "PERSONAL", name="visibility"),
            nullable=False,
            server_default="SHARED",
        ),
        sa.Column(
            "status",
            sa.Enum(
                "ACTIVE", "COMPLETED", "PAUSED", "CANCELLED", name="savings_goal_status"
            ),
            nullable=False,
            server_default="ACTIVE",
        ),
        sa.Column("notes", sa.Text, nullable=True),
        *_timestamps(),
    )

    op.create_table(
        "budgets",
        _uuid_pk(),
        sa.Column(
            "household_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("households.id"),
            nullable=False,
        ),
        sa.Column(
            "owner_user_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("users.id"), nullable=True
        ),
        sa.Column(
            "category_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("categories.id"),
            nullable=True,
        ),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column(
            "period_type",
            sa.Enum("MONTHLY", "WEEKLY", "YEARLY", "CUSTOM", name="budget_period_type"),
            nullable=False,
            server_default="MONTHLY",
        ),
        sa.Column("start_date", sa.Date, nullable=False),
        sa.Column("end_date", sa.Date, nullable=True),
        sa.Column(
            "visibility",
            sa.Enum("SHARED", "PERSONAL", name="visibility"),
            nullable=False,
            server_default="SHARED",
        ),
        *_timestamps(),
    )

    op.create_table(
        "recurring_bills",
        _uuid_pk(),
        sa.Column(
            "household_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("households.id"),
            nullable=False,
        ),
        sa.Column(
            "account_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("accounts.id"), nullable=True
        ),
        sa.Column(
            "category_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("categories.id"),
            nullable=True,
        ),
        sa.Column("title", sa.String(150), nullable=False),
        sa.Column("amount", sa.Numeric(14, 2), nullable=False),
        sa.Column(
            "frequency",
            sa.Enum(
                "DAILY", "WEEKLY", "MONTHLY", "YEARLY", "CUSTOM", name="recurring_frequency"
            ),
            nullable=False,
            server_default="MONTHLY",
        ),
        sa.Column("next_due_date", sa.Date, nullable=False),
        sa.Column(
            "status",
            sa.Enum("ACTIVE", "PAUSED", "CANCELLED", name="recurring_bill_status"),
            nullable=False,
            server_default="ACTIVE",
        ),
        sa.Column(
            "visibility",
            sa.Enum("SHARED", "PERSONAL", name="visibility"),
            nullable=False,
            server_default="SHARED",
        ),
        sa.Column("notes", sa.Text, nullable=True),
        *_timestamps(),
    )


def downgrade() -> None:
    op.drop_table("recurring_bills")
    op.drop_table("budgets")
    op.drop_table("savings_goals")
    op.drop_table("transfers")
    op.drop_table("expenses")
    op.drop_table("incomes")
    op.drop_table("accounts")
    op.drop_table("categories")
    op.drop_table("household_invitations")
    op.drop_table("household_members")
    op.drop_table("households")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_table("users")

    for enum_name in (
        "recurring_bill_status",
        "recurring_frequency",
        "budget_period_type",
        "savings_goal_status",
        "visibility",
        "expense_status",
        "income_status",
        "account_type",
        "category_type",
        "member_status",
        "household_role",
    ):
        sa.Enum(name=enum_name).drop(op.get_bind(), checkfirst=True)
