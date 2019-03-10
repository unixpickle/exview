using Gtk;

class RegionSelector : DrawingArea {
    private ScaledImage image;

    private DragState? drag_state = null;
    private int x1 = 0;
    private int y1 = 0;
    private int x2 = 0;
    private int y2 = 0;

    public signal void updated();

    public RegionSelector(ScaledImage image) {
        this.image = image;
        this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK);
        this.button_press_event.connect((event) => {
            this.drag_state = new DragState(this.image, this.x1, this.y1, this.x2, this.y2,
                event.x, event.y);
            this.update();
            return true;
        });
        this.button_release_event.connect((event) => {
            this.drag_state = null;
            return true;
        });
        this.motion_notify_event.connect((event) => {
            if (this.drag_state != null) {
                this.drag_state.mouse_move(event.x, event.y);
                this.update();
            }
            return true;
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
        int w = this.image.pixbuf.get_width();
        int h = this.image.pixbuf.get_height();
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
        this.x2 = this.image.pixbuf.get_width();
        this.y2 = this.image.pixbuf.get_height();
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

class DragState {
    private ScaledImage image;
    private bool dragging_x2 = false;
    private bool dragging_y2 = false;
    private int x1;
    private int y1;
    private int x2;
    private int y2;
    double mouse_x;
    double mouse_y;

    public DragState(ScaledImage img, int x1, int y1, int x2, int y2,
                     double mouse_x, double mouse_y) {
        this.image = img;
        this.x1 = x1;
        this.y1 = y1;
        this.x2 = x2;
        this.y2 = y2;
        this.mouse_x = mouse_x;
        this.mouse_y = mouse_y;
        if (!this.find_closest_corner()) {
            this.setup_new_drag();
        }
    }

    public void mouse_move(double x, double y) {
        this.mouse_x = x;
        this.mouse_y = y;
        int img_x;
        int img_y;
        this.image.view_to_image(x, y, out img_x, out img_y);
        if (this.dragging_x2) {
            this.x2 = img_x;
        } else {
            this.x1 = img_x;
        }
        if (this.dragging_y2) {
            this.y2 = img_y;
        } else {
            this.y1 = img_y;
        }
    }

    public void get_selection(out int x1, out int y1, out int x2, out int y2) {
        x1 = this.x1;
        y1 = this.y1;
        x2 = this.x2;
        y2 = this.y2;
    }

    private bool find_closest_corner() {
        if (this.x1 == this.x2 && this.y1 == this.y2) {
            return false;
        }
        double d1 = this.dist_to_corner(this.x1, this.y1);
        double d2 = this.dist_to_corner(this.x2, this.y1);
        double d3 = this.dist_to_corner(this.x1, this.y2);
        double d4 = this.dist_to_corner(this.x2, this.y2);
        double min = d1;
        double values[] = {d1, d2, d3, d4};
        foreach (double v in values) {
            if (v < min) {
                min = v;
            }
        }
        if (min > 10) {
            return false;
        }
        if (min == d2) {
            this.dragging_x2 = true;
        } else if (min == d3) {
            this.dragging_y2 = true;
        } else if (min == d4) {
            this.dragging_x2 = true;
            this.dragging_y2 = true;
        }
        return true;
    }

    private double dist_to_corner(int img_x, int img_y) {
        double x1, y1;
        this.image.image_to_view(img_x, img_y, out x1, out y1);
        double distance = Math.sqrt(Math.pow(this.mouse_x - x1, 2) +
            Math.pow(this.mouse_y - y1, 2));
        return distance;
    }

    private void setup_new_drag() {
        int img_x;
        int img_y;
        this.image.view_to_image(this.mouse_x, this.mouse_y, out img_x, out img_y);
        this.x1 = this.x2 = img_x;
        this.y1 = this.y2 = img_y;
        this.dragging_x2 = true;
        this.dragging_y2 = true;
    }
}
