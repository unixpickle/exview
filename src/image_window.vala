using Gtk;

class ImageWindow : ApplicationWindow {
    private string? file_path;
    private ScrolledWindow scrolled;
    private Viewport viewport;
    private ScaledImage image;
    private RegionSelector selector;

    public ImageWindow(Gtk.Application app, Gdk.Pixbuf raw_pixbuf, string? file_path) {
        Object(application: app);
        var pixbuf = raw_pixbuf.apply_embedded_orientation();
        if (file_path != null) {
            this.set_title(Path.get_basename(file_path));
        } else {
            this.set_title("Exview");
        }
        this.file_path = file_path;
        this.scrolled = new ScrolledWindow(null, null);
        this.viewport = new Viewport(null, null);
        this.image = new ScaledImage(pixbuf, initial_scale(pixbuf));
        this.selector = new RegionSelector(this.image, new KeyState(this));
        var overlay = new SelectorOverlay(this.image, this.selector);
        overlay.halign = Align.CENTER;
        overlay.valign = Align.CENTER;
        this.viewport.add(overlay);
        this.scrolled.add(this.viewport);
        this.style_scrolled();

        var container = new Box(VERTICAL, 0);
        container.pack_start(scrolled);
        container.add(new MeasureBar(selector));

        this.add(container);

        int width = this.image.width;
        int height = this.image.height;
        if (width < 300) {
            width = 300;
        }
        if (height < 300) {
            height = 300;
        }
        this.scrolled.set_size_request(width + 100, height + 100);

        this.setup_actions();
    }

    public new void show_all() {
        base.show_all();
        this.scrolled.set_size_request(200, 200);
    }

    public static void create_from_clipboard(Gtk.Application app) {
        var clip = Clipboard.get(Gdk.SELECTION_CLIPBOARD);
        var pixbuf = clip.wait_for_image();
        if (pixbuf != null) {
            new ImageWindow(app, pixbuf, null).show_all();
        } else {
            var dialog = new MessageDialog(null, 0, MessageType.ERROR, ButtonsType.CLOSE,
                "No image in clipboard.");
            dialog.run();
            dialog.close();
        }
    }

    private void style_scrolled() {
        this.scrolled.get_style_context().add_class("image-scroller");

        var css = new CssProvider();
        try {
            css.load_from_data(".image-scroller { background-color: black; }");
        } catch (Error e) {
            assert(false);
        }

        var display = Gdk.Display.get_default();
        var screen = display.get_default_screen();
        StyleContext.add_provider_for_screen(screen, css, 600);
    }

    private void setup_actions() {
        var zoom_in = new SimpleAction("zoom-in", null);
        var zoom_out = new SimpleAction("zoom-out", null);
        var unzoom = new SimpleAction("unzoom", null);
        var close = new SimpleAction("close", null);
        var copy = new SimpleAction("copy", null);
        var new_clipboard = new SimpleAction("new-clipboard", null);
        var save = new SimpleAction("save", null);
        var save_as = new SimpleAction("save-as", null);
        var crop = new SimpleAction("crop", null);
        var select_all = new SimpleAction("select-all", null);
        var resize = new SimpleAction("resize", null);
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
        close.activate.connect(this.close);
        copy.activate.connect(this.copy_selection);
        new_clipboard.activate.connect(() => {
            ImageWindow.create_from_clipboard(this.application);
        });
        save.activate.connect(this.save);
        save_as.activate.connect(this.save_as);
        crop.activate.connect(this.crop);
        select_all.activate.connect(this.selector.select_all);
        resize.activate.connect(this.resize_image);
        this.add_action(zoom_in);
        this.add_action(zoom_out);
        this.add_action(unzoom);
        this.add_action(close);
        this.add_action(copy);
        this.add_action(new_clipboard);
        this.add_action(save);
        this.add_action(save_as);
        this.add_action(crop);
        this.add_action(select_all);
        this.add_action(resize);
    }

    private void copy_selection() {
        var clip = Clipboard.get(Gdk.SELECTION_CLIPBOARD);
        clip.set_image(this.selector.cropped_image());
    }

    private void save() {
        if (this.file_path == null) {
            this.save_as();
            return;
        }
        string[] comps = this.file_path.split(".");
        try {
            this.image.pixbuf.save(this.file_path, comps[comps.length - 1].ascii_down());
        } catch (Error error) {
            var dialog = new MessageDialog(this, 0, MessageType.ERROR, ButtonsType.CLOSE,
                @"Could not export image: $(error.message)");
            dialog.run();
            dialog.close();
        }
    }

    private void save_as() {
        var dialog = new FileChooserDialog("Choose Output Image", this, FileChooserAction.SAVE, "_Cancel", ResponseType.CANCEL, "_Export", ResponseType.ACCEPT, null);
        dialog.set_filename("Untitled.png");
        if (dialog.run() == ResponseType.ACCEPT) {
            this.file_path = dialog.get_filename();
            this.set_title(Path.get_basename(this.file_path));
            this.save();
        }
        dialog.close();
    }

    private void crop() {
        this.image.pixbuf = this.selector.cropped_image();
        this.selector.deselect();
    }

    private void resize_image() {
        var dialog = new ResizeDialog(this.image.pixbuf.width, this.image.pixbuf.height);
        dialog.set_transient_for(this);
        var result = dialog.run();
        if (result == 1) {
            this.selector.deselect();
            this.image.pixbuf = this.image.pixbuf.scale_simple(dialog.width, dialog.height,
                BILINEAR);
        }
        dialog.close();
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
        double max_width = (double)workarea.width - 300;
        double max_height = (double)workarea.height - 300;
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
