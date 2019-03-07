using Gtk;

class ImageWindow : ApplicationWindow {
    private string? file_path;
    private ScrolledWindow scrolled;
    private Viewport viewport;
    private ScaledImage image;

    public ImageWindow(Gtk.Application app, Gdk.Pixbuf pixbuf, string? file_path) {
        Object(application: app);
        this.file_path = file_path;
        this.scrolled = new ScrolledWindow(null, null);
        this.viewport = new Viewport(null, null);
        this.image = new ScaledImage(pixbuf, initial_scale(pixbuf));
        this.viewport.add(this.image);
        this.scrolled.add(this.viewport);
        this.add(scrolled);
        this.set_default_size(this.image.width, this.image.height);

        this.setup_actions();
    }

    private void setup_actions() {
        var zoom_in = new SimpleAction("zoom-in", null);
        var zoom_out = new SimpleAction("zoom-out", null);
        var unzoom = new SimpleAction("unzoom", null);
        zoom_in.activate.connect(() => {
            if (this.image.scale < 5) {
                this.image.scale *= 1.5;
            }
        });
        zoom_out.activate.connect(() => {
            this.image.scale /= 1.5;
            if ((this.image.scale - 1).abs() < 1e-5) {
                this.image.scale = 1.0;
            }
        });
        unzoom.activate.connect(() => {
            this.image.scale = 1.0;
        });
        this.add_action(zoom_in);
        this.add_action(zoom_out);
        this.add_action(unzoom);
    }

    private static double initial_scale(Gdk.Pixbuf pixbuf) {
        // TODO: get default screen size here.
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
