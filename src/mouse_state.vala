using Gtk;

class MouseState : Object {
    public signal void updated();

    public double x = 0.0;
    public double y = 0.0;

    public MouseState(Widget widget) {
        widget.button_press_event.connect((event) => {
            this.x = event.x;
            this.y = event.y;
            this.updated();
            return false;
        });
        widget.motion_notify_event.connect((event) => {
            this.x = event.x;
            this.y = event.y;
            this.updated();
            return false;
        });
    }
}
