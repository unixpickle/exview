using Gtk;

class Exview : ApplicationWindow {
    private string? file_path;
    private ScrolledWindow scrolled;
    private Viewport viewport;
    private ScaledImage image;

    public Exview(Gtk.Application app, Gdk.Pixbuf pixbuf, string? file_path) {
        Object(application: app);
        this.file_path = file_path;
        this.scrolled = new ScrolledWindow(null, null);
        this.viewport = new Viewport(null, null);
        this.image = new ScaledImage(pixbuf, initial_scale(pixbuf));
        this.viewport.add(this.image);
        this.scrolled.add(this.viewport);
        this.add(scrolled);
        this.set_default_size(this.image.width, this.image.height);
    }

    private static double initial_scale(Gdk.Pixbuf pixbuf) {
        double max_width = 800;
        double max_height = 600;
        if ((double)pixbuf.width > max_width || (double)pixbuf.height > max_height) {
            double width_scale = max_width / (double)pixbuf.width;
            double height_scale = max_height / (double)pixbuf.height;
            if (width_scale < height_scale) {
                return width_scale;
            } else {
                return height_scale;
            }
        }
        return 1.0;
    }
}
