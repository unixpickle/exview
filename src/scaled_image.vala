using Gtk;

class ScaledImage : Bin {
    private Image image;
    private Gdk.Pixbuf _pixbuf;
    private double _scale;

    public int width {
        get {
            return this.image.get_pixbuf().width;
        }
    }

    public int height {
        get {
            return this.image.get_pixbuf().height;
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