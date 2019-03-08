using Gtk;

class ImageWindow : ApplicationWindow {
    private string? file_path;
    private ScrolledWindow scrolled;
    private Viewport viewport;
    private ScaledImage image;
    private RegionSelector selector;

    public ImageWindow(Gtk.Application app, Gdk.Pixbuf pixbuf, string? file_path) {
        Object(application: app);
        if (file_path != null) {
            this.set_title(GLib.Path.get_basename(file_path));
        } else {
            this.set_title("Exview");
        }
        this.file_path = file_path;
        this.scrolled = new ScrolledWindow(null, null);
        this.viewport = new Viewport(null, null);
        this.image = new ScaledImage(pixbuf, initial_scale(pixbuf));
        this.selector = new RegionSelector(this.image);
        var overlay = new SelectorOverlay(this.image, this.selector);
        overlay.halign = Align.CENTER;
        overlay.valign = Align.CENTER;
        this.viewport.add(overlay);
        this.scrolled.add(this.viewport);
        this.add(scrolled);

        int width = this.image.width;
        int height = this.image.height;
        if (width < 300) {
            width = 300;
        }
        if (height < 300) {
            height = 300;
        }
        this.scrolled.set_size_request(width, height);

        this.setup_actions();
    }

    public static void create_from_clipboard(Gtk.Application app) {
        var clip = Clipboard.get(Gdk.SELECTION_CLIPBOARD);
        var pixbuf = clip.wait_for_image();
        if (pixbuf != null) {
            new ImageWindow(app, pixbuf, null).show_all();
        }
    }

    private void setup_actions() {
        var zoom_in = new SimpleAction("zoom-in", null);
        var zoom_out = new SimpleAction("zoom-out", null);
        var unzoom = new SimpleAction("unzoom", null);
        var close = new SimpleAction("close", null);
        var copy = new SimpleAction("copy", null);
        var new_clipboard = new SimpleAction("new-clipboard", null);
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
        close.activate.connect(() => {
            this.close();
        });
        copy.activate.connect(() => {
            this.copy_selection();
        });
        new_clipboard.activate.connect(() => {
            ImageWindow.create_from_clipboard(this.application);
        });
        this.add_action(zoom_in);
        this.add_action(zoom_out);
        this.add_action(unzoom);
        this.add_action(close);
        this.add_action(copy);
        this.add_action(new_clipboard);
    }

    private void copy_selection() {
        var clip = Clipboard.get(Gdk.SELECTION_CLIPBOARD);
        clip.set_image(this.selector.cropped_image());
    }

    private static double initial_scale(Gdk.Pixbuf pixbuf) {
        var display = Gdk.Display.get_default();
        Gdk.Monitor monitor = null;
        for (int i = 0; i < display.get_n_monitors(); i++) {
            monitor = display.get_monitor(i);
            if (monitor.is_primary()) {
                break;
            }
        }
        var workarea = monitor.get_workarea();
        double max_width = (double)workarea.width - 200;
        double max_height = (double)workarea.height - 200;
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
