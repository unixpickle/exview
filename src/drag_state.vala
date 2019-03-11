class DragState : GLib.Object {
    public signal void updated();

    private ScaledImage image;
    private bool dragging_x2 = false;
    private bool dragging_y2 = false;
    private int x1_init;
    private int y1_init;
    private int x2_init;
    private int y2_init;
    private int x1;
    private int y1;
    private int x2;
    private int y2;

    private KeyState key_state;
    private MouseState mouse_state;

    public DragState(ScaledImage img, int x1, int y1, int x2, int y2,
                     MouseState mouse_state, KeyState key_state) {
        this.image = img;
        this.x1 = this.x1_init = x1;
        this.y1 = this.y1_init = y1;
        this.x2 = this.x2_init = x2;
        this.y2 = this.y2_init = y2;
        this.mouse_state = mouse_state;
        this.key_state = key_state;
        mouse_state.updated.connect(this.mouse_moved);
        key_state.updated.connect(this.keys_changed);
        if (!this.find_closest_corner()) {
            this.setup_new_drag();
        }
    }

    public void mouse_moved() {
        int img_x;
        int img_y;
        this.image.view_to_image(this.mouse_state.x, this.mouse_state.y, out img_x, out img_y);
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
        this.updated();
    }

    public void keys_changed() {
        this.updated();
    }

    public void get_selection(out int x1, out int y1, out int x2, out int y2) {
        x1 = this.x1_init;
        y1 = this.y1_init;
        x2 = this.x2_init;
        y2 = this.y2_init;
        bool pressing_anything = this.key_state.x || this.key_state.y;
        if (this.key_state.x || !pressing_anything) {
            x1 = this.x1;
            x2 = this.x2;
        }
        if (this.key_state.y || !pressing_anything) {
            y1 = this.y1;
            y2 = this.y2;
        }
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
        double distance = Math.sqrt(Math.pow(this.mouse_state.x - x1, 2) +
            Math.pow(this.mouse_state.y - y1, 2));
        return distance;
    }

    private void setup_new_drag() {
        int img_x;
        int img_y;
        this.image.view_to_image(this.mouse_state.x, this.mouse_state.y, out img_x, out img_y);
        this.x1 = this.x2 = img_x;
        this.y1 = this.y2 = img_y;
        this.dragging_x2 = true;
        this.dragging_y2 = true;
    }
}
