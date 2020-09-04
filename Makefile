.PHONY: all build clean shell test

all: clean build test

build:
	docker build -t simplybusiness/ruby-dev:2.6.5 .

clean:
	rm -f *~

shell:
	docker run -it \
	-v `pwd`:/var/app \
	simplybusiness/ruby-dev:2.6.5 \
	bash

test:
	docker run -it \
	-v `pwd`:/var/app \
	simplybusiness/ruby-dev:2.6.5 \
	bundle exec rake test
