build/exview: src/image_window.vala src/main.vala src/scaled_image.vala src/region_selector.vala src/measure_bar.vala src/key_state.vala src/drag_state.vala src/mouse_state.vala src/resize_dialog.vala
	mkdir -p build
	valac --pkg gtk+-3.0 -X -lm -o build/exview $^

install: build/exview
	mkdir -p ~/.local/share/exview
	cp build/exview ~/.local/share/exview
	cat exview.desktop | sed -E "s/USERNAME/${USER}/g" > ~/.local/share/applications/exview.desktop
	cp exview.svg ~/.local/share/icons/hicolor/48x48/apps/exview_v2.svg
	chmod +x ~/.local/share/applications/exview.desktop

uninstall:
	rm -rf ~/.local/share/exview
	rm -f ~/.local/share/applications/exview.desktop
	rm -f ~/.local/share/icons/hicolor/48x48/apps/exview_v2.svg

clean:
	rm -rf build/
