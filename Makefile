APP=skol
APP_TEST=skol-test

.PHONY: help
help:  ## This help
	@echo "Usage:"
	@echo "  make <target>"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[1m%-15s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: clean  ## Build the images
	docker-compose build ${APP}

.PHONY: build-test
build-test: clean  ## Build the images for testing
	docker-compose build ${APP_TEST}

.PHONY: clean
clean:  ## Remove cached files and dirs from workspace
	@echo "Cleaning workspace"
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@find . -type f -name "*.DS_Store" -delete
	@rm -f .coverage coverage.xml
	@rm -rf .pytest_cache

.PHONY: lint
lint:  ## Run linting
	docker-compose run --rm ${APP_TEST} sh -c 'flake8 && isort --recursive --check-only --diff app'

.PHONY: remove
remove:  ## Remove the containers
	docker container rm -fv ${APP} db || echo "Containers are removed"

.PHONY: start
start:  ## Start the containers
	docker-compose up -d ${APP}
	docker-compose logs -f ${APP} || echo "Exited container logs"

.PHONY: test
test:  ## Run tests
	@docker-compose run --rm ${APP_TEST} sh -c 'pytest -s --cov app --cov-report term --cov-report xml tests'

.PHONY: install
install:  ## Install packages
	@DEPS_FILE=deps.txt; \
	cp requirements.txt $$DEPS_FILE; \
	if [ "$$APP_ENV" = "dev" ] || [ "$$APP_ENV" = "test" ]; then \
		echo "Installing packages + dev"; \
		sed 's/# dev //g' requirements.txt > $$DEPS_FILE; \
	else \
		echo "Installing packages"; \
	fi; \
	pip install -r $$DEPS_FILE && rm $$DEPS_FILE

.PHONY: install-dev
install-dev:  ## Install dev + regular packages
	APP_ENV=dev $(MAKE) install
