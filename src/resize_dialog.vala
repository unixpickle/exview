using Gtk;

class ResizeDialog : Dialog {

    private int start_width;
    private int start_height;
    private Entry width_field;
    private Entry height_field;
    public int width;
    public int height;

    public ResizeDialog(int w, int h) {
        this.start_width = w;
        this.start_height = h;
        this.width = w;
        this.height = h;

        this.add_buttons("Cancel", ButtonsType.CLOSE, "Resize", ButtonsType.OK);

        var width_label = new Label("Width:");
        var height_label = new Label("Height:");
        this.width_field = new Entry();
        this.height_field = new Entry();
        this.width_field.set_text(@"$(w)");
        this.height_field.set_text(@"$(h)");

        this.width_field.changed.connect(() => {
            this.width = int.parse(this.width_field.get_text());
        });
        this.height_field.changed.connect(() => {
            this.height = int.parse(this.height_field.get_text());
        });

        var grid = new Grid();
        grid.set_row_spacing(10);
        grid.set_column_spacing(10);
        grid.attach(width_label, 0, 0, 1, 1);
        grid.attach(height_label, 0, 1, 1, 1);
        grid.attach(this.width_field, 1, 0, 1, 1);
        grid.attach(this.height_field, 1, 1, 1, 1);
        grid.show_all();

        grid.get_style_context().add_class("resize-content");

        var css = new CssProvider();
        try {
            css.load_from_data(".resize-content { padding: 6px; }");
        } catch (Error e) {
            assert(false);
        }

        var display = Gdk.Display.get_default();
        var screen = display.get_default_screen();
        StyleContext.add_provider_for_screen(screen, css, 600);

        this.get_content_area().add(grid);
    }

}
