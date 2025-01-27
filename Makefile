# Default target
.PHONY: all
all: setup dev db-upgrade db-seed

# ------------------------------------------------------------------------------
# Environment Setup
# ------------------------------------------------------------------------------

.PHONY: setup
setup:
ifeq ($(OS),Windows_NT)
	powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
else
	curl -LsSf https://astral.sh/uv/install.sh | sh
endif
	uv python install 3.12
	uv venv --python 3.12
	uv sync
	uv tool install pre-commit && pre-commit install

# ------------------------------------------------------------------------------
# Development & Deployment
# ------------------------------------------------------------------------------

.PHONY: dev
dev:
	docker compose up --build -d

.PHONY: run
run:
	uv run uvicorn app.main:app --reload

.PHONY: deploy
deploy:
	docker compose --profile prod up --build

# ------------------------------------------------------------------------------
# Database Commands
# ------------------------------------------------------------------------------

.PHONY: db-revision
db-revision:
	uv run alembic revision --autogenerate -m "$(msg)"

.PHONY: db-upgrade
db-upgrade:
	uv run alembic upgrade head

.PHONY: db-downgrade
db-downgrade:
	uv run alembic downgrade -1

.PHONY: db-seed
db-seed:
ifeq ($(OS),Windows_NT)
	SET PYTHONPATH=. && uv run python app/infrastructure/cmd/seed.py
else
	PYTHONPATH=. uv run python3 app/infrastructure/cmd/seed.py
endif

# ------------------------------------------------------------------------------
# Testing
# ------------------------------------------------------------------------------

.PHONY: test
test:
	uv run pytest -n 4

.PHONY: test-coverage
test-coverage:
	uv run pytest -n 4 --cov
	uv run coverage report --fail-under=85
