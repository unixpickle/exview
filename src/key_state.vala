using Gtk;

class KeyState : GLib.Object {
    public signal void updated();

    public bool x;
    public bool y;

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
