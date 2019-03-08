using Gtk;

class RegionSelector : DrawingArea {
    private ScaledImage image;

    private bool dragging;
    private bool dragging_x2;
    private bool dragging_y2;
    private int x1 = 0;
    private int y1 = 0;
    private int x2 = 0;
    private int y2 = 0;

    public RegionSelector(ScaledImage image) {
        this.image = image;
        this.dragging = false;
        this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK);
        this.button_press_event.connect((event) => {
            this.mouse_down(event.x, event.y);
            return true;
        });
        this.button_release_event.connect((event) => {
            this.dragging = false;
            return true;
        });
        this.motion_notify_event.connect((event) => {
            if (!this.dragging) {
                return false;
            }
            this.mouse_move(event.x, event.y);
            return true;
        });
        this.set_size_request(image.width, image.height);
        image.updated.connect(() => {
            this.set_size_request(image.width, image.height);
            this.queue_draw();
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

    private void mouse_down(double x, double y) {
        int img_x;
        int img_y;
        this.image.view_to_image(x, y, out img_x, out img_y);

        if (!this.closest_corner(x, y, out this.dragging_x2, out this.dragging_y2)) {
            this.x1 = this.x2 = img_x;
            this.y1 = this.y2 = img_y;
            this.dragging_x2 = true;
            this.dragging_y2 = true;
        }
        this.dragging = true;
        this.queue_draw();
    }

    private void mouse_move(double x, double y) {
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
        this.queue_draw();
    }

    private bool closest_corner(double x, double y, out bool x2, out bool y2) {
        x2 = false;
        y2 = false;
        if (this.no_selection()) {
            return false;
        }
        double d1 = this.dist_to_corner(x, y, this.x1, this.y1);
        double d2 = this.dist_to_corner(x, y, this.x2, this.y1);
        double d3 = this.dist_to_corner(x, y, this.x1, this.y2);
        double d4 = this.dist_to_corner(x, y, this.x2, this.y2);
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
            x2 = true;
        } else if (min == d3) {
            y2 = true;
        } else if (min == d4) {
            x2 = true;
            y2 = true;
        }
        return true;
    }

    private double dist_to_corner(double x, double y, int img_x, int img_y) {
        double x1, y1;
        this.image.image_to_view(img_x, img_y, out x1, out y1);
        double distance = Math.sqrt(Math.pow(x - x1, 2) + Math.pow(y - y1, 2));
        return distance;
    }

    private bool no_selection() {
        return this.x1 == this.x2 && this.y1 == this.y2;
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
