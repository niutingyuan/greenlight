# Inclue variables from the .envrc file
include .envrc

# ======================================================================================================= #
# HELPERS
# ======================================================================================================= #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'

.PHONY: confirm
confirm:
	@echo -n 'Are you sure? [y/N]' && read ans && [ $${ans:-N} = y ]

# ======================================================================================================= #
# DEVELOPMENT
# ======================================================================================================= #

## run/api: run the cmd/api application
.PHONY: run/api
run/api:
	go run ./cmd/api -db-dsn=${GREENLIGHT_DB_DSN}

## db/psql: connect to the database using psql
.PHONY: db/psql
db/psql:
	psql ${GREENLIGHT_DB_DSN}

## db/migration/new name=$1: create a new database migration 
.PHONY: db/migrations/up
db/migrations/new:
	migrate create -seq -ext=.sql -dir=./migrations ${name}

## db/migration/up: apply all up database migrations
.PHONY: db/migrations/up
db/migrations/up: confirm
	migrate -path ./migrations -database ${GREENLIGHT_DB_DSN} up

# ======================================================================================================= #
# QUALITY CONTROL
# ======================================================================================================= #

## tidy: tidy and vendor module dependencies, and format and modernize all .go files
.PHONE: tidy
tidy:
	go mod tidy
	go mod verify
	go mod vendor
	go fix ./...
	go fmt ./...

## audit: run quality control checks
audit:
	go mod tidy -diff
	go mod verify
	go vet ./...
	go tool staticcheck ./...
	go test -race -vet=off ./...

# ======================================================================================================= #
# BUILD
# ======================================================================================================= #

## build/api: build the cmd/api application
.PHONY: build/api
build/api:
	go build -ldflags='-s' -o=./bin/api ./cmd/api
	GOOS=linux GOARCH=amd64 go build -ldflags='-s' -o=./bin/linux_amd64/api ./cmd/api
