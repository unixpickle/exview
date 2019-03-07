build/exview: src/image_window.vala src/main.vala src/scaled_image.vala
	mkdir -p build
	valac --pkg gtk+-3.0 -X -lm -o build/exview $^

clean:
	rm -rf build/
