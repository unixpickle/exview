using Gtk;

void main(string[] args) {
    var app = new Gtk.Application("com.aqnichol.exview", ApplicationFlags.HANDLES_OPEN);
    app.activate.connect((gapp) => {
        if (!ImageWindow.create_from_clipboard(app)) {
            var dialog = new FileChooserDialog("Open File", null, FileChooserAction.OPEN,
                "_Cancel", ResponseType.CANCEL, "_Open", ResponseType.ACCEPT, null);
            if (dialog.run() == ResponseType.ACCEPT) {
                ImageWindow.create_from_file(app, dialog.get_filename());
            }
            dialog.close();
        }
    });
    app.open.connect((files, hint) => {
        foreach (File file in files) {
            ImageWindow.create_from_file(app, file.get_path());
        }
    });
    app.startup.connect(() => {
        app.menubar = create_menubar();
    });
    app.run(args);
}

MenuModel create_menubar() {
    var menu = new GLib.Menu();

    var file_menu = new GLib.Menu();
    append_menu_item(file_menu, "_New From Clipboard", "win.new-clipboard", "<Control>N");
    append_menu_item(file_menu, "_Open File...", "win.open", "<Control>O");
    append_menu_item(file_menu, "_Save", "win.save", "<Control>S");
    append_menu_item(file_menu, "Save _As...", "win.save-as", "<Shift><Control>S");
    append_menu_item(file_menu, "_Print...", "win.print", "<Control>P");
    append_menu_item(file_menu, "_Close Window", "win.close", "<Control>W");
    menu.append_submenu("_File", file_menu);

    var edit_menu = new GLib.Menu();
    append_menu_item(edit_menu, "_Copy", "win.copy", "<Control>C");
    append_menu_item(edit_menu, "C_rop", "win.crop", "<Control>K");
    append_menu_item(edit_menu, "_Select All", "win.select-all", "<Control>A");
    append_menu_item(edit_menu, "_Undo", "win.undo", "<Control>Z");
    append_menu_item(edit_menu, "_Redo", "win.redo", "<Control>Y");
    menu.append_submenu("_Edit", edit_menu);

    var view_menu = new GLib.Menu();
    append_menu_item(view_menu, "_Zoom In", "win.zoom-in", "<Control>equal");
    append_menu_item(view_menu, "_Zoom Out", "win.zoom-out", "<Control>minus");
    append_menu_item(view_menu, "_Normal Size", "win.unzoom", "<Control>0");
    menu.append_submenu("_View", view_menu);

    var image_menu = new GLib.Menu();
    append_menu_item(image_menu, "_Resize...", "win.resize", "<Control><Shift>R");
    append_menu_item(image_menu, "Rotate R_ight", "win.rotate-right", "<Control>R");
    append_menu_item(image_menu, "Rotate _Left", "win.rotate-left", "<Control>L");
    menu.append_submenu("_Image", image_menu);

    return menu;
}

void append_menu_item(GLib.Menu menu,
                      string label,
                      string action,
                      string accel) {
    var menu_item = new GLib.MenuItem(label, action);
    menu_item.set_attribute("accel", "s", accel);
    menu.append_item(menu_item);
}
