build:
	docker build -f Dockerfile . -t aciddensity/arkcluster:dev

clean:
	docker image rm aciddensity/arkcluster:dev ||:

push:
	docker image push aciddensity/arkcluster:dev

all: clean build push
