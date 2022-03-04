using Gtk;

class ImageWindow : ApplicationWindow {
    private string? _file_path;
    private bool _modified = false;
    private ScrolledWindow scrolled;
    private Viewport viewport;
    private ScaledImage image;
    private RegionSelector selector;

    private GLib.SimpleAction undo_action;
    private GLib.SimpleAction redo_action;
    private List<Gdk.Pixbuf> undo_buffer;
    private List<Gdk.Pixbuf> redo_buffer;

    private string? file_path {
        get {
            return this._file_path;
        }

        set {
            this._file_path = value;
            this.update_title();
        }
    }

    private bool modified {
        get {
            return this._modified;
        }

        set {
            this._modified = value;
            this.update_title();
        }
    }

    public ImageWindow(Gtk.Application app, Gdk.Pixbuf raw_pixbuf, string? file_path) {
        Object(application: app);
        var pixbuf = raw_pixbuf.apply_embedded_orientation();
        this.file_path = file_path;
        this.undo_buffer = new List<Gdk.Pixbuf>();
        this.redo_buffer = new List<Gdk.Pixbuf>();
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

        var container = new Box(Orientation.VERTICAL, 0);
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

    public static bool create_from_clipboard(Gtk.Application app) {
        var clip = Clipboard.get_default(Gdk.Display.get_default());
        var pixbuf = clip.wait_for_image();
        if (pixbuf != null) {
            new ImageWindow(app, pixbuf, null).show_all();
            return true;
        }
        return false;
    }

    public static void create_from_file(Gtk.Application app, string path) {
        try {
            var pixbuf = new Gdk.Pixbuf.from_file(path);
            new ImageWindow(app, pixbuf, path).show_all();
        } catch (Error error) {
            var dialog = new MessageDialog(null, 0, MessageType.ERROR, ButtonsType.CLOSE,
                @"Unable to process image: $(error.message)");
            dialog.run();
            dialog.close();
        }
    }

    private void style_scrolled() {
        this.scrolled.get_style_context().add_class("image-scroller");

        var css = new CssProvider();
        try {
            var code = ".image-scroller { background-color: black; }";
            css.load_from_data(code, code.length);
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
        var open = new SimpleAction("open", null);
        var rotate_right = new SimpleAction("rotate-right", null);
        var rotate_left = new SimpleAction("rotate-left", null);
        this.undo_action = new SimpleAction("undo", null);
        this.redo_action = new SimpleAction("redo", null);
        zoom_in.activate.connect(() => {
            if (this.image.scale < 5) {
                this.image.scale *= 1.5;
            }
        });
        zoom_out.activate.connect(() => {
            this.image.scale /= 1.5;
            if (double_abs(this.image.scale - 1) < 1e-5) {
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
        save.activate.connect(() => this.save());
        save_as.activate.connect(this.save_as);
        crop.activate.connect(this.crop);
        select_all.activate.connect(this.selector.select_all);
        resize.activate.connect(this.resize_image);
        open.activate.connect(this.open_file);
        rotate_right.activate.connect(() => this.rotate(true));
        rotate_left.activate.connect(() => this.rotate(false));
        this.undo_action.activate.connect(this.undo);
        this.redo_action.activate.connect(this.redo);
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
        this.add_action(open);
        this.add_action(rotate_right);
        this.add_action(rotate_left);
        this.add_action(this.undo_action);
        this.add_action(this.redo_action);

        this.update_undo_redo();
    }

    private void update_title() {
        string filename = "Untitled";
        if (this.file_path != null) {
            filename = Path.get_basename(this.file_path);
        }
        if (this.modified) {
            this.title = @"* $(filename)";
        } else {
            this.title = filename;
        }
    }

    private void copy_selection() {
        var clip = Clipboard.get(Gdk.SELECTION_CLIPBOARD);
        clip.set_image(this.selector.cropped_image());
    }

    private bool save() {
        if (this.file_path == null) {
            this.save_as();
            return true;
        }
        string[] comps = this.file_path.split(".");
        string file_type = comps[comps.length - 1].ascii_down();
        if (file_type == "jpg") {
            file_type = "jpeg";
        }
        try {
            this.image.pixbuf.save(this.file_path, file_type);
            this.clear_undo_redo();
            this.modified = false;
        } catch (Error error) {
            var dialog = new MessageDialog(this, 0, MessageType.ERROR, ButtonsType.CLOSE,
                @"Could not export image: $(error.message)");
            dialog.run();
            dialog.close();
            return false;
        }
        return true;
    }

    private void save_as() {
        var dialog = new FileChooserDialog("Choose Output Image", this, FileChooserAction.SAVE, "_Cancel", ResponseType.CANCEL, "_Export", ResponseType.ACCEPT, null);
        dialog.set_filename("Untitled.png");
        if (dialog.run() == ResponseType.ACCEPT) {
            var old_path = this.file_path;
            this.file_path = dialog.get_filename();
            if (!this.save()) {
                this.file_path = old_path;
            }
        }
        dialog.close();
    }

    private void crop() {
        this.modify(this.selector.cropped_image());
    }

    private void resize_image() {
        var dialog = new ResizeDialog(this.image.pixbuf.width, this.image.pixbuf.height);
        dialog.set_transient_for(this);
        var result = dialog.run();
        if (result == 1) {
            this.modify(this.image.pixbuf.scale_simple(dialog.width, dialog.height,
                Gdk.InterpType.BILINEAR));
        }
        dialog.close();
    }

    private void rotate(bool clockwise) {
        if (clockwise) {
            this.modify(this.image.pixbuf.rotate_simple(Gdk.PixbufRotation.CLOCKWISE));
        } else {
            this.modify(this.image.pixbuf.rotate_simple(Gdk.PixbufRotation.COUNTERCLOCKWISE));
        }
    }

    private void open_file() {
        var dialog = new FileChooserDialog("Open File", this, FileChooserAction.OPEN, "_Cancel", ResponseType.CANCEL, "_Open", ResponseType.ACCEPT, null);
        if (dialog.run() == ResponseType.ACCEPT) {
            ImageWindow.create_from_file(this.application, dialog.get_filename());
        }
        dialog.close();
    }

    private void modify(Gdk.Pixbuf new_image) {
        this.undo_buffer.prepend(this.image.pixbuf);
        this.redo_buffer = new List<Gdk.Pixbuf>();
        this.image.pixbuf = new_image;
        this.selector.deselect();
        this.modified = true;
        this.update_undo_redo();
    }

    private void clear_undo_redo() {
        this.redo_buffer = new List<Gdk.Pixbuf>();
        this.undo_buffer = new List<Gdk.Pixbuf>();
        this.update_undo_redo();
    }

    private void undo() {
        if (this.undo_buffer.length() == 0) {
            return;
        }
        var last = this.undo_buffer.data;
        this.undo_buffer.remove(last);
        this.redo_buffer.prepend(this.image.pixbuf);
        this.image.pixbuf = last;
        this.selector.deselect();
        this.modified = this.undo_buffer.length() > 0;
        this.update_undo_redo();
    }

    private void redo() {
        if (this.redo_buffer.length() == 0) {
            return;
        }
        var next = this.redo_buffer.data;
        this.redo_buffer.remove(next);
        this.undo_buffer.prepend(this.image.pixbuf);
        this.image.pixbuf = next;
        this.selector.deselect();
        this.modified = true;
        this.update_undo_redo();
    }

    private void update_undo_redo() {
        this.undo_action.set_enabled(this.undo_buffer.length() > 0);
        this.redo_action.set_enabled(this.redo_buffer.length() > 0);
    }

    private static double initial_scale(Gdk.Pixbuf pixbuf) {
        double max_width = (double)Gdk.Screen.width() - 300;
        double max_height = (double)Gdk.Screen.height() - 300;
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

private double double_abs(double x) {
    if (x < 0) {
        return -x;
    }
    return x;
}
