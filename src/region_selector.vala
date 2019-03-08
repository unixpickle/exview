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
            int x;
            int y;
            this.image.view_to_image(event.x, event.y, out x, out y);
            this.x1 = this.x2 = x;
            this.y1 = this.y2 = y;
            this.dragging = true;
            this.dragging_x2 = true;
            this.dragging_y2 = true;
            this.queue_draw();
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
            int x;
            int y;
            this.image.view_to_image(event.x, event.y, out x, out y);
            if (this.dragging_x2) {
                this.x2 = x;
            } else {
                this.x1 = x;
            }
            if (this.dragging_y2) {
                this.y2 = y;
            } else {
                this.y1 = y;
            }
            this.queue_draw();
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

    private void draw_selection(Cairo.Context ctx) {
        double x1, y1;
        double x2, y2;
        this.image.image_to_view(this.x1, this.y1, out x1, out y1);
        this.image.image_to_view(this.x2, this.y2, out x2, out y2);

        if (x1 - x2 == 0 && y1 == y2) {
            ctx.set_source_rgba(0, 0, 0, 0);
            ctx.paint();
            return;
        }

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
