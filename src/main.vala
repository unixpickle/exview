using Gtk;

void main(string[] args) {
    var app = new Gtk.Application("com.aqnichol.exview", ApplicationFlags.HANDLES_OPEN);
    app.activate.connect((gapp) => {
        ImageWindow.create_from_clipboard(app);
    });
    app.open.connect((files, hint) => {
        foreach (GLib.File file in files) {
            try {
                var pixbuf = new Gdk.Pixbuf.from_file(file.get_path());
                new ImageWindow(app, pixbuf, file.get_path()).show_all();
            } catch (GLib.Error error) {
                // TODO: error dialog here.
            }
        }
    });
    app.startup.connect(() => {
        app.set_menubar(create_menubar());
    });
    app.run(args);
}

GLib.MenuModel create_menubar() {
    var menu = new GLib.Menu();

    var file_menu = new GLib.Menu();
    append_menu_item(file_menu, "_Save", "win.save", "<Control>S");
    append_menu_item(file_menu, "Save _As", "win.save-as", "<Shift><Control>S");
    append_menu_item(file_menu, "_Close Window", "win.close", "<Control>W");
    append_menu_item(file_menu, "_New From Clipboard", "win.new-clipboard", "<Control>N");
    menu.append_submenu("_File", file_menu);

    var edit_menu = new GLib.Menu();
    append_menu_item(edit_menu, "_Copy", "win.copy", "<Control>C");
    append_menu_item(edit_menu, "C_rop", "win.crop", "<Control>K");
    append_menu_item(edit_menu, "Select All", "win.select-all", "<Control>A");
    menu.append_submenu("_Edit", edit_menu);

    var view_menu = new GLib.Menu();
    append_menu_item(view_menu, "_Zoom In", "win.zoom-in", "<Control>equal");
    append_menu_item(view_menu, "_Zoom Out", "win.zoom-out", "<Control>minus");
    append_menu_item(view_menu, "_Normal Size", "win.unzoom", "<Control>0");
    menu.append_submenu("_View", view_menu);

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
