filepath        :=      $(PWD)
versionfile     :=      $(filepath)/version.txt
version         :=      $(shell cat $(versionfile))
image_repo      :=      0labs/teku
build_type      ?=      package

build:
	DOCKER_BUILDKIT=1 docker build --tag $(image_repo):build-$(version) --build-arg build_type=$(build_type) --build-arg teku_version=$(version) .

test:
	DOCKER_BUILDKIT=1 docker build --tag teku:test --target test --build-arg build_type=$(build_type) --build-arg teku_version=$(version) . && docker run --env-file test/test.env teku:test

test-compose-beacon:
	cd compose && docker-compose config && image=$(image_repo):$(version) docker-compose up -d teku-beacon && \
	sleep 90 && docker-compose logs 2>&1 | grep "Loaded initial state" && \
	docker-compose logs 2>&1 | grep "Syncing started" && \
	docker-compose logs 2>&1 | grep "Successfully loaded deposits" && \
	docker-compose down

test-compose-validator:
	cd compose && docker-compose config && image=$(image_repo):$(version) docker-compose up -d && \
	sleep 30 && docker-compose logs teku-validator 2>&1 | grep "Successfully connected to beacon chain event stream" && \
	docker-compose down

release:
	DOCKER_BUILDKIT=1 docker build --tag $(image_repo):$(version) --target release --build-arg build_type=$(build_type) --build-arg teku_version=$(version) .
	docker push $(image_repo):$(version)

latest:
	docker tag $(image_repo):$(version) $(image_repo):latest
	docker push $(image_repo):latest

.PHONY: test
