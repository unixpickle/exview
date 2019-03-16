using Gtk;

class ScaledImage : Bin {
    private Image image;
    private Gdk.Pixbuf _pixbuf;
    private double _scale;

    public int width {
        get {
            return this.image.pixbuf.width;
        }
    }

    public int height {
        get {
            return this.image.pixbuf.height;
        }
    }

    public Gdk.Pixbuf pixbuf {
        get {
            return this._pixbuf;
        }

        set {
            this._pixbuf = value;
            this.update_image();
        }
    }

    public double scale {
        get {
            return this._scale;
        }

        set {
            this._scale = value;
            this.update_image();
        }
    }

    public signal void updated();

    public ScaledImage(Gdk.Pixbuf pixbuf, double scale) {
        this._pixbuf = pixbuf;
        this._scale = scale;
        this.image = new Image.from_pixbuf(this.scaled_pixbuf());
        this.add(this.image);
    }

    public void view_to_image(double x, double y, out int x_img, out int y_img) {
        x_img = (int)Math.round(x / this._scale);
        y_img = (int)Math.round(y / this._scale);
    }

    public void image_to_view(int x_img, int y_img, out double x, out double y) {
        x = (double)x_img * this._scale;
        y = (double)y_img * this._scale;
    }

    private void update_image() {
        this.remove(this.image);
        this.image = new Image.from_pixbuf(this.scaled_pixbuf());
        this.add(this.image);
        this.image.show();
        this.updated();
    }

    private Gdk.Pixbuf scaled_pixbuf() {
        int width = (int)Math.round((double)this.pixbuf.width * this.scale);
        int height = (int)Math.round((double)this.pixbuf.height * this.scale);
        return this.pixbuf.scale_simple(width, height, Gdk.InterpType.BILINEAR);
    }
}
