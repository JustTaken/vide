use crate::{keymap::KeyMap, action::Function};

use std::sync::{Arc, Mutex};

use gtk::{
    gio::{ActionEntry, SimpleActionGroup},
    prelude::*,
    Application,
    ApplicationWindow,
    ScrolledWindow,
    TextView,
    TextBuffer,
    Shortcut,
    ShortcutController,
    ShortcutTrigger,
    CallbackAction,
    Orientation,
    EntryBuffer,
    Text,
    CenterBox,
};

struct TextWindow {
    content: ScrolledWindow,
}

impl TextWindow {
    fn default() -> TextWindow {
        let text = "This is just a text to test my custom text editor";
        let text_buffer = TextBuffer::builder()
            .text(text)
            .build();

        let text_view = TextView::builder()
            .css_name("buffer")
            .indent(4)
            .buffer(&text_buffer)
            .build();

        text_view.add_controller(KeyMap::buffer_controller().controller);

        let content = ScrolledWindow::builder()
            .child(&text_view)
            .vexpand(true)
            .css_name("text_window")
            .build();

        TextWindow {
            content,
        }
    }
}

struct ModeLine {
    content: CenterBox,
}

impl ModeLine {
    fn default() -> ModeLine {
        let command_line = Text::builder().focus_on_click(false).build();
        let disabled_keys = ShortcutTrigger::parse_string("Tab").unwrap();
        let cancel_key = ShortcutTrigger::parse_string("Escape").unwrap();
        let shortcut_disable_action = CallbackAction::new(|_, _| { true });
        let shortcut_cancel= CallbackAction::new(|widget, _| {
            let text = widget.downcast_ref::<Text>().unwrap();
            text.buffer().delete_text(0, None);
            text.emit_move_focus(gtk::DirectionType::TabBackward);
            true
        });

        let disableds = Shortcut::builder().trigger(&disabled_keys).action(&shortcut_disable_action).build();
        let escape = Shortcut::builder().trigger(&cancel_key).action(&shortcut_cancel).build();

        let controller = ShortcutController::new();

        controller.add_shortcut(disableds);
        controller.add_shortcut(escape);
        command_line.add_controller(controller);

        command_line.connect_activate(|text| {
            let content = text.buffer().text();
            if let Err(err) = Function::validate_command(&content) {
                println!("Error: {}", err);
            } else {
                text.buffer().delete_text(0, None);
                text.emit_move_focus(gtk::DirectionType::TabBackward);
                let _ = text.activate_action("win.command_to_buffer", Some(&content.to_variant()));
            }
        });

        let center = Text::builder().buffer(&EntryBuffer::new(Some("file_name"))).can_focus(false).css_name("buffer").build();
        let right = Text::builder().buffer(&EntryBuffer::new(Some("line:col"))).can_focus(false).css_name("buffer").build();
        let content = CenterBox::builder()
            .start_widget(&command_line)
            .center_widget(&center)
            .end_widget(&right)
            .build();

        ModeLine {
            content,
        }
    }
}

#[derive(Debug)]
pub struct Buffer {
    pub content: Option<TextBuffer>,
    pub name: String,
}

pub struct Window;

impl Window {
    pub fn build(app: &Application) {
        let buffer = TextWindow::default();
        let mode_line = ModeLine::default();

        let window_box = gtk::Box::builder().orientation(Orientation::Vertical).build();
        window_box.append(&buffer.content);
        window_box.append(&mode_line.content);

        let window = ApplicationWindow::builder()
            .application(app)
            .default_width(600)
            .default_height(400)
            .title("My App")
            .child(&window_box)
            .build();

        let mut buffers: Arc<Mutex<Vec<Buffer>>> = Arc::new(Mutex::new(vec![Buffer {content: None, name: "scratch".to_owned()}]));
        let send_command_to_buffer = ActionEntry::builder("command_to_buffer")
            .parameter_type(Some(&String::static_variant_type()))
            .activate(move |window: &ApplicationWindow, _, variant| {
                let text_view_ref = gtk::prelude::GtkWindowExt::focus(window).unwrap();
                let arguments = variant.unwrap().get::<String>().unwrap();

                if let Some(text_view) = text_view_ref.downcast_ref::<TextView>() {
                    if let Err(err) = Function::execute_command(&arguments[..], text_view, buffers.clone()) {
                        println!("Error: {err}");
                    }
                }
            })
            .build();

        window.add_action_entries([send_command_to_buffer]);
        window.present();
    }
}

// let command_action = ActionEntry::builder("command")
//     .parameter_type(Some(&String::static_variant_type()))
//     .activate(move |map, action, parameters| {
//         let arguments  = parameters.unwrap().get::<String>().unwrap();
//         println!("map: {:?}, action: {:?}", map, action);
//         // buffers.lock().unwrap().push("maconha".to_owned());
//     })
//     .build();

// let action_group = SimpleActionGroup::new();
// action_group.add_action_entries([command_action]);
// text_view.insert_action_group("buffer", Some(&action_group));
