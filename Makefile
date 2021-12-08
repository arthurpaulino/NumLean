.PHONY: clean build run test

clean:
	@lake clean

build:
	@make clean && lake build

run:
	@./build/bin/NumLean

test:
	@make build && make run