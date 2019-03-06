using Gtk;

void main(string[] args) {
    var app = new Gtk.Application("com.aqnichol.exview", ApplicationFlags.HANDLES_OPEN);
    app.activate.connect((gapp) => {
        var pixbuf = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 400, 400);
        var window = new Exview(app, pixbuf, null);
        window.show_all();
    });
    app.open.connect((files, hint) => {
        foreach (GLib.File file in files) {
            try {
                var pixbuf = new Gdk.Pixbuf.from_file(file.get_path());
                new Exview(app, pixbuf, file.get_path()).show_all();
            } catch (GLib.Error error) {
                // TODO: error dialog here.
            }
        }
    });
    app.run(args);
}
