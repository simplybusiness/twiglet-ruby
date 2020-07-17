.PHONY: all build test

all: build test

build:
	docker build -t simplybusiness/ruby-dev:2.6.5 .

test:
	docker run -it -v `pwd`:/var/app simplybusiness/ruby-dev:2.6.5 bundle exec rake test
