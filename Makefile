.DEFAULT_GOAL := help

.PHONY: help dev stop migrate check

help:
	@printf '%s\n' \
		'Instant Chat development commands:' \
		'  make dev      Start MySQL, migrate, run the API, and open the macOS client.' \
		'  make stop     Stop the Docker development services.' \
		'  make migrate  Apply all pending database migrations.' \
		'  make check    Run the complete local verification suite.'

dev:
	@./scripts/dev.sh

stop:
	@./scripts/stop.sh

migrate:
	@./scripts/migrate.sh

check:
	@./scripts/check.sh
