using Gtk;

class Exview : ApplicationWindow {
    private Gdk.Pixbuf pixbuf;
    private double scale;
    private string? file_path;
    private Viewport viewport;
    private Image image;

    public Exview(Gtk.Application app, Gdk.Pixbuf pixbuf, string? file_path) {
        Object(application: app);
        this.pixbuf = pixbuf;
        this.scale = this.initial_scale();
        this.file_path = file_path;
        this.viewport = new Viewport(null, null);
        this.image = new Image.from_pixbuf(this.scaled_pixbuf());
        this.viewport.add(this.image);
        this.add(this.viewport);
    }

    private double initial_scale() {
        double max_width = 800;
        double max_height = 600;
        if ((double)this.pixbuf.width > max_width || (double)this.pixbuf.height > max_height) {
            double width_scale = max_width / (double)this.pixbuf.width;
            double height_scale = max_height / (double)this.pixbuf.height;
            if (width_scale < height_scale) {
                return width_scale;
            } else {
                return height_scale;
            }
        }
        return 1.0;
    }

    private Gdk.Pixbuf scaled_pixbuf() {
        int width = (int)Math.round((double)this.pixbuf.width * this.scale);
        int height = (int)Math.round((double)this.pixbuf.height * this.scale);
        return this.pixbuf.scale_simple(width, height, Gdk.InterpType.BILINEAR);
    }
}
