build:
	docker build -f Dockerfile . -t r15ch13/arkcluster:dev

clean:
	docker image rm r15ch13/arkcluster:dev ||:

push:
	docker image push r15ch13/arkcluster:dev

all: clean build push
