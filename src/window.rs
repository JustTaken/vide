use gtk::{
    prelude::*,
    Application,
    Widget,
    ApplicationWindow,
    ScrolledWindow,
    TextView,
    TextBuffer,
    Shortcut,
    ShortcutController,
    ShortcutTrigger,
    CallbackAction,
    NothingAction,
    Orientation,
    EntryBuffer,
    Text,
    CenterBox,
};

struct KeyMap {
    controller: ShortcutController,
}

impl KeyMap {
    fn default() -> KeyMap {
        let disabled_keys = ShortcutTrigger::parse_string("Delete|F7|Home|End|Insert|<Control>x|<Control>c|<Control>v|<Control>a|<Shift>Insert|<Shift><Control>a").unwrap();
        let shortcut_disable_action = CallbackAction::new(|_, _| { println!("acionando tecla"); true });
        let shortcut = Shortcut::builder().trigger(&disabled_keys).action(&shortcut_disable_action).build();

        // let control_f = ShortcutTrigger::parse_string("<Control>f").unwrap();
        // let control_f_action_callback = CallbackAction::new(|widget, _| { true });
        let controller = ShortcutController::new();

        controller.add_shortcut(shortcut);

        KeyMap {
            controller,
        }
    }
}

struct Buffer {
    content: ScrolledWindow,
}

impl Buffer {
    fn default() -> Buffer {
        let text = "This is just a text to test my custom text editor";
        let text_buffer = TextBuffer::builder()
            .text(text)
            .build();

        let text_view = TextView::builder()
            .css_name("buffer")
            .buffer(&text_buffer)
            .build();

        text_view.add_controller(KeyMap::default().controller);

        let content = ScrolledWindow::builder()
            .child(&text_view)
            .vexpand(true)
            .css_name("text_window")
            .build();

        Buffer {
            content,
        }
    }
}

pub struct Window {

}


impl Window {
    pub fn build(app: &Application) {
        let buffer = Buffer::default();
        let window_box = gtk::Box::builder()
            .orientation(Orientation::Vertical)
            .build();
        let mode_line = CenterBox::builder()
            .start_widget(&Text::with_buffer(&EntryBuffer::new(Some("Insert"))))
            .center_widget(&Text::with_buffer(&EntryBuffer::new(Some("file_name"))))
            .end_widget(&Text::with_buffer(&EntryBuffer::new(Some("line:col"))))
            .build();

        window_box.append(&buffer.content);
        window_box.append(&mode_line);

        let window = ApplicationWindow::builder()
            .application(app)
            .default_width(600)
            .default_height(400)
            .title("My App")
            .child(&window_box)
            .build();

        window.present();
    }
}
