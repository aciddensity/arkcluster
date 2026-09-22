build:
	docker build -f Dockerfile . -t aciddensity/arkcluster:latest

clean:
	docker image rm aciddensity/arkcluster:latest ||:

push:
	docker image push aciddensity/arkcluster:latest

all: clean build push
