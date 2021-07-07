VERSION := $(shell git describe --tags --always --dirty="-dev")
LDFLAGS := -ldflags='-X "main.version=$(VERSION)"'
NAME := server
Q=@

GOTESTFLAGS = -race
ifndef Q
	GOTESTFLAGS += -v
endif

.PHONY: clean
clean:
	$Qrm -rf vendor/ && git checkout ./vendor

.PHONY: check
check: vet fmtcheck
	$Qecho "checking vet and format"

.PHONY: vet
vet:
	$Qgo vet ./...

.PHONY: fmtcheck
fmtchk:
	$Qexit $(shell goimports -l . | grep -v '^vendor' | wc -l)

.PHONY: fmtfix
fmtfix:
	$Qgoimports -w $(shell find . -iname '*.go' | grep -v vendor)

$(GOPATH)/bin/migrate:
	$Qgo get github.com/golang-migrate/migrate
	$Qgo build -o $(GOPATH)/bin/migrate github.com/golang-migrate/migrate/cli

.PHONY: create-migration
create-migration: $(GOPATH)/bin/migrate
	migrate create -dir data/migrations -ext sql $$MIGRATION

.PHONY: build
build: vet
	$Qgo build $(LDFLAGS) -o ./build/$(NAME) ./cmd/$(NAME)

# .PHONY: docker-push
# docker-push: docker-build
#   $Qecho docker push not implemented

GOTAGS = testing

.PHONY: test
test: vet
	$Qgo test -tags='$(GOTAGS)' $(GOTESTFLAGS) -coverpkg="./..." -coverprofile=.coverprofile ./...
	$Qgrep -v 'cmd' < .coverprofile > .covprof && mv .covprof .coverprofile
	$Qgo tool cover -func=.coverprofile


MODEL_VERSION=v1

.PHONY: pg-users
pg-users:
	$Qdocker build --no-cache data \
		-t abraithwaite/pg-users:$(MODEL_VERSION)
