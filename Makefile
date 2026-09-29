build:
	docker build -f Dockerfile . -t aciddensity/arkcluster:latest

build-alpine:
	docker build -f Dockerfile.alpine . -t aciddensity/arkcluster:latest-alpine

clean:
	docker image rm aciddensity/arkcluster:latest ||:

clean-alpine:
	docker image rm aciddensity/arkcluster:latest-alpine ||:

push:
	docker image push aciddensity/arkcluster:latest

push-alpine:
	docker image push aciddensity/arkcluster:latest-alpine

all: clean build push
