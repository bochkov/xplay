
compile:
	mkdir -p out
	nim c -d:release --out:out/xplay xplay.nim

install: compile
	cp ./out/xplay /usr/local/bin/

clean:
	rm -rf ./out