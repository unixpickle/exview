using Gtk;

class RegionSelector : DrawingArea {
    private ScaledImage image;
    private bool selecting;

    public RegionSelector(ScaledImage image) {
        this.image = image;
        this.selecting = false;
        this.set_events(Gdk.EventMask.BUTTON_PRESS_MASK | Gdk.EventMask.BUTTON_RELEASE_MASK |
            Gdk.EventMask.POINTER_MOTION_MASK);
        this.button_press_event.connect((event) => {
            stdout.printf("press\n");
            return true;
        });
        this.set_size_request(image.width, image.height);
        image.updated.connect(() => {
            this.set_size_request(image.width, image.height);
        });
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
