using Gtk;

class KeyState : Object {
    public signal void updated();

    public bool x = false;
    public bool y = false;

    public KeyState(Widget widget) {
        widget.key_press_event.connect((event) => {
            if (event.keyval == Gdk.Key.X) {
                this.x = true;
            } else if (event.keyval == Gdk.Key.Y) {
                this.y = true;
            }
            this.updated();
            return false;
        });
        widget.key_release_event.connect((event) => {
            if (event.keyval == Gdk.Key.X) {
                this.x = false;
            } else if (event.keyval == Gdk.Key.Y) {
                this.y = false;
            }
            this.updated();
            return false;
        });
    }
}
