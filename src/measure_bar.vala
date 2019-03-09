using Gtk;

class MeasureBar : Label {
    public MeasureBar(RegionSelector selector) {
        this.label = "No selection";
        this.set_size_request(100, 30);
        selector.updated.connect(() => {
            if (selector.no_selection()) {
                this.label = "No selection";
            } else {
                this.label = @"$(selector.selection_width())x$(selector.selection_height())";
            }
        });
    }
}
