use vide::window::Window;
use gtk::{
    prelude::*,
    gdk,
    glib,
    Application,
    CssProvider,
};

fn main() -> glib::ExitCode{
    let app = Application::builder().build();
    app.connect_startup(load_style);
    app.connect_activate(Window::build);
    app.run()
}

fn load_style(_: &Application) {
    let provider = CssProvider::new();
    provider.load_from_path("assets/style.css");
    gtk::style_context_add_provider_for_display(
        &gdk::Display::default().expect("Could not connect to a display"),
        &provider,
        gtk::STYLE_PROVIDER_PRIORITY_APPLICATION
    );
}
