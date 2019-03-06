using Gtk;

void main(string[] args) {
    var app = new Gtk.Application("com.aqnichol.exview", ApplicationFlags.FLAGS_NONE);
    app.activate.connect((gapp) => {
        var pixbuf = new Gdk.Pixbuf(Gdk.Colorspace.RGB, true, 8, 400, 400);
        var window = new Exview(app, pixbuf, null);
        window.show_all();
    });
    app.run(args);
}
