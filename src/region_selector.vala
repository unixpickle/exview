using Gtk;

class RegionSelector : DrawingArea {
    private ScaledImage image;

    private DragState? drag_state = null;
    private KeyState key_state;
    private MouseState mouse_state;
    private int x1 = 0;
    private int y1 = 0;
    private int x2 = 0;
    private int y2 = 0;

    public signal void updated();

    public RegionSelector(ScaledImage image, KeyState key_state) {
        this.image = image;
        this.mouse_state = new MouseState(this);
        this.key_state = key_state;
        this.events = Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK;
        this.button_press_event.connect((event) => {
            this.drag_state = new DragState(this.image, this.x1, this.y1, this.x2, this.y2,
                this.mouse_state, this.key_state);
            this.drag_state.updated.connect(this.update);
            this.update();
            return false;
        });
        this.button_release_event.connect((event) => {
            this.drag_state = null;
            return false;
        });
        this.set_size_request(image.width, image.height);
        image.updated.connect(() => {
            this.set_size_request(image.width, image.height);
            this.update();
        });
        this.draw.connect((ctx) => {
            this.draw_selection(ctx);
            return true;
        });
    }

    public Gdk.Pixbuf cropped_image() {
        if (this.no_selection()) {
            return this.image.pixbuf;
        }
        int w = this.image.pixbuf.width;
        int h = this.image.pixbuf.height;
        int x1 = (this.x1 < this.x2 ? this.x1 : this.x2).clamp(0, w);
        int x2 = (this.x1 < this.x2 ? this.x2 : this.x1).clamp(0, w);
        int y1 = (this.y1 < this.y2 ? this.y1 : this.y2).clamp(0, h);
        int y2 = (this.y1 < this.y2 ? this.y2 : this.y1).clamp(0, h);
        if (x1 == x2 || y1 == y2) {
            return this.image.pixbuf;
        }
        return new Gdk.Pixbuf.subpixbuf(this.image.pixbuf, x1, y1, x2 - x1, y2 - y1);
    }

    public void deselect() {
        this.drag_state = null;
        this.x1 = 0;
        this.y1 = 0;
        this.x2 = 0;
        this.y2 = 0;
        this.update();
    }

    public void select_all() {
        this.drag_state = null;
        this.x1 = 0;
        this.y1 = 0;
        this.x2 = this.image.pixbuf.width;
        this.y2 = this.image.pixbuf.height;
        this.update();
    }

    public bool no_selection() {
        return this.x1 == this.x2 && this.y1 == this.y2;
    }

    public int selection_width() {
        return x1 < x2 ? x2 - x1 : x1 - x2;
    }

    public int selection_height() {
        return y1 < y2 ? y2 - y1 : y1 - y2;
    }

    private void update() {
        if (this.drag_state != null) {
            this.drag_state.get_selection(out this.x1, out this.y1, out this.x2, out this.y2);
        }
        this.updated();
        this.queue_draw();
    }

    private void draw_selection(Cairo.Context ctx) {
        if (this.no_selection()) {
            ctx.set_source_rgba(0, 0, 0, 0);
            ctx.paint();
            return;
        }

        double x1, y1;
        double x2, y2;
        this.image.image_to_view(this.x1, this.y1, out x1, out y1);
        this.image.image_to_view(this.x2, this.y2, out x2, out y2);

        if (x1 > x2) {
            double tmp = x2;
            x2 = x1;
            x1 = tmp;
        }

        if (y1 > y2) {
            double tmp = y2;
            y2 = y1;
            y1 = tmp;
        }

        ctx.save();
        ctx.rectangle(0, 0, (double)this.image.width, y1);
        ctx.rectangle(0, y2, (double)this.image.width, (double)this.image.height);
        ctx.rectangle(0, 0, x1, (double)this.image.height);
        ctx.rectangle(x2, 0, (double)this.image.width, (double)this.image.height);
        ctx.clip();
        ctx.set_source_rgba(1, 1, 1, 0.5);
        ctx.paint();
        ctx.restore();

        ctx.save();
        ctx.set_source_rgba(0, 0, 0, 1.0);
        ctx.rectangle(x1, y1, x2 - x1, y2 - y1);
        ctx.stroke();
        ctx.restore();
    }
}

class SelectorOverlay : Fixed {
    public SelectorOverlay(ScaledImage image, RegionSelector selector) {
        this.put(image, 0, 0);
        this.put(selector, 0, 0);
        image.updated.connect(() => {
            this.set_size_request(image.width, image.height);
        });
        this.set_size_request(image.width, image.height);
    }
}
