build/exview: src/exview.vala src/main.vala
	mkdir -p build
	valac --pkg gtk+-3.0 -X -lm -o build/exview $^

clean:
	rm -rf build/
