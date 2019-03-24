using Gtk;

class ResizeDialog : Dialog {

    private int start_width;
    private int start_height;
    private Widget resize_button;
    private Entry width_field;
    private Entry height_field;
    private CheckButton proportional;
    public int width;
    public int height;

    public ResizeDialog(int w, int h) {
        this.start_width = w;
        this.start_height = h;
        this.width = w;
        this.height = h;

        this.add_button("Cancel", ButtonsType.CLOSE);
        this.resize_button = this.add_button("Resize", ButtonsType.OK);

        this.proportional = new CheckButton.with_label("Keep aspect ratio");
        this.proportional.active = true;

        var width_label = new Label("Width:");
        var height_label = new Label("Height:");
        this.width_field = new Entry();
        this.height_field = new Entry();
        this.width_field.text = @"$(w)";
        this.height_field.text = @"$(h)";

        this.setup_field_events();

        var grid = new Grid();
        grid.row_spacing = 10;
        grid.column_spacing = 10;
        grid.attach(width_label, 0, 0, 1, 1);
        grid.attach(height_label, 0, 1, 1, 1);
        grid.attach(this.width_field, 1, 0, 1, 1);
        grid.attach(this.height_field, 1, 1, 1, 1);
        grid.attach(this.proportional, 0, 2, 2, 1);
        grid.show_all();

        grid.get_style_context().add_class("resize-content");

        var css = new CssProvider();
        try {
            var code = ".resize-content { padding: 6px; }";
            css.load_from_data(code, code.length);
        } catch (Error e) {
            assert(false);
        }

        var display = Gdk.Display.get_default();
        var screen = display.get_default_screen();
        StyleContext.add_provider_for_screen(screen, css, 600);

        this.get_content_area().add(grid);
    }

    private void setup_field_events() {
        var changing_text = false;
        this.width_field.changed.connect(() => {
            if (changing_text) {
                return;
            }
            if (is_valid_int(this.width_field.text)) {
                this.width = int.parse(this.width_field.text);
                if (this.proportional.active) {
                    double ratio = (double)this.width / (double)this.start_width;
                    this.height = (int)Math.round(ratio * (double)this.start_height);
                    changing_text = true;
                    this.height_field.text = @"$(this.height)";
                    changing_text = false;
                }
            }
            this.enable_or_disable();
        });
        this.height_field.changed.connect(() => {
            if (changing_text) {
                return;
            }
            if (is_valid_int(this.height_field.text)) {
                this.height = int.parse(this.height_field.text);
                if (this.proportional.active) {
                    double ratio = (double)this.height / (double)this.start_height;
                    this.width = (int)Math.round(ratio * (double)this.start_width);
                    changing_text = true;
                    this.width_field.text = @"$(this.width)";
                    changing_text = false;
                }
            }
            this.enable_or_disable();
        });
    }

    private void enable_or_disable() {
        this.resize_button.sensitive = (is_valid_int(this.width_field.text) &&
            is_valid_int(this.height_field.text));
    }

}

bool is_valid_int(string s) {
    return int.parse(s).to_string() == s;
}
