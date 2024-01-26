use std::{
    sync::{Arc, Mutex},
};
use gtk::{
    gio::{ActionEntry, SimpleActionGroup},
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
    Orientation,
    EntryBuffer,
    Text,
    CenterBox,
    MovementStep,
};

#[derive(Debug)]
enum Function {}

impl Function {
    fn open_command(widget: &Widget) {
        let window_box_widget = widget.parent().unwrap().parent().unwrap();
        let window_box = window_box_widget.downcast_ref::<gtk::Box>().unwrap();
        let mode_line = window_box.last_child().unwrap();
        
        println!("widget parent: {:?}", mode_line.downcast_ref::<gtk::CenterBox>().unwrap().start_widget().unwrap().grab_focus());
    }

    fn next_line(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::DisplayLines, 1, false);
    }

    fn prev_line(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::DisplayLines, -1, false);
    }

    fn end_line(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::DisplayLineEnds, 1, false);
    }

    fn begin_line(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::DisplayLineEnds, -1, false);
    }

    fn forward_word(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::Words, 1, false);
    }

    fn backward_word(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::Words, -1, false);
    }

    fn forward_char(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::LogicalPositions, 1, false);
    }

    fn backward_char(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::LogicalPositions, -1, false);
    }

   fn execute(command: &str, widget: &Text) -> Result<(), &'static str>{
        let mut text = command.split(' ').collect::<Vec<&str>>().into_iter();
        if let Some(command) = text.next() {
            if command == "e" {
                if let Some(argument) = text.next() {
                    let window_box_widget = widget.parent().unwrap().parent().unwrap();
                    let window_box = window_box_widget.downcast_ref::<gtk::Box>().unwrap();
                    let scrolled_window = window_box.first_child().unwrap();
                    let text_view_widget = scrolled_window.first_child().unwrap();
                    let text_view = text_view_widget.downcast_ref::<gtk::TextView>().unwrap();

                    if let Ok(content) = std::fs::read_to_string(argument) {
                        widget.buffer().delete_text(0, None);
                        text_view.buffer().set_text(&content[..]);
                        text_view.grab_focus();
                        Ok(())
                    } else {
                        Err("file not found")
                    }
                } else {
                    Err("no argument provided")
                }
            } else {
                Err("command not found")
            }
        } else {
            Err("no command provided")
        }
   }

}

#[derive(Clone, PartialEq, Debug, Copy)]
enum Binding {
    ControlX,
    ControlSemicolon,

    ControlN,
    ControlP,
    ControlA,
    ControlE,

    ControlF,
    ControlB,
    AltF,
    AltB,
}

impl Binding {
    fn to_string<'a>(&'a self) -> &'a str{
        match self {
            Binding::ControlX => "<Control>x",
            Binding::ControlSemicolon => "<Control>semicolon",
            Binding::ControlN => "<Control>n",
            Binding::ControlP => "<Control>p",
            Binding::ControlA => "<Control>a",
            Binding::ControlE => "<Control>e",

            Binding::ControlF => "<Control>f",
            Binding::ControlB => "<Control>b",
            Binding::AltF => "<Alt>f",
            Binding::AltB => "<Alt>b",
        }
    }

    fn new_base(bindings: Arc<Mutex<Vec<Binding>>>, binding: Binding, base: Vec<Binding>) -> Shortcut {
        let trigger = ShortcutTrigger::parse_string(binding.to_string()).unwrap();
        let action = CallbackAction::new(move |_, _| {
            let mut flag = false;
            if let std::sync::LockResult::Ok(mut bindings) = bindings.lock() {
                if bindings.eq(&base) {
                    bindings.push(binding.clone());
                    flag = true;
                }
            }

            flag
        });

        Shortcut::builder().trigger(&trigger).action(&action).build()
    }

    fn new_final<F: Fn(&Widget) + 'static>(bindings: Arc<Mutex<Vec<Binding>>>, binding: Binding, base: Vec<Binding>, function: F) -> Shortcut {
        let trigger = ShortcutTrigger::parse_string(binding.to_string()).unwrap();
        let action = CallbackAction::new(move |widget, _| {
            if let std::sync::LockResult::Ok(mut bindings) = bindings.lock() {
                if bindings.eq(&base) {
                    function(&widget);
                }

                bindings.clear();

                true
            } else {
                false
            }
        });

        Shortcut::builder().trigger(&trigger).action(&action).build()
    }
}

struct KeyMap {
    controller: ShortcutController,
}

impl KeyMap {
    fn buffer_controller() -> KeyMap {
        let disabled_keys = ShortcutTrigger::parse_string("Delete|F7|Home|End|Insert|<Control>c|<Control>v|<Shift>Insert|<Shift><Control>a").unwrap();
        let shortcut_disable_action = CallbackAction::new(|_, _| { true });
        let disableds = Shortcut::builder().trigger(&disabled_keys).action(&shortcut_disable_action).build();

        let base_bindings: Arc<Mutex<Vec<Binding>>> = Arc::new(Mutex::new(Vec::new()));
        let bindings: Vec<Shortcut> = vec![
            Binding::new_base(base_bindings.clone(), Binding::ControlX, vec![]),
            Binding::new_final(base_bindings.clone(), Binding::ControlSemicolon, vec![], Function::open_command),

            Binding::new_final(base_bindings.clone(), Binding::ControlN, vec![], Function::next_line),
            Binding::new_final(base_bindings.clone(), Binding::ControlP, vec![], Function::prev_line),

            Binding::new_final(base_bindings.clone(), Binding::ControlA, vec![], Function::begin_line),
            Binding::new_final(base_bindings.clone(), Binding::ControlE, vec![], Function::end_line),

            Binding::new_final(base_bindings.clone(), Binding::ControlF, vec![], Function::forward_char),
            Binding::new_final(base_bindings.clone(), Binding::ControlB, vec![], Function::backward_char),

            Binding::new_final(base_bindings.clone(), Binding::AltF, vec![], Function::forward_word),
            Binding::new_final(base_bindings.clone(), Binding::AltB, vec![], Function::backward_word),
        ];

        let controller = ShortcutController::new();
        controller.add_shortcut(disableds);
        for bind in bindings {
            controller.add_shortcut(bind);
        }

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

        let action_print = ActionEntry::builder("command")
            .activate(|action_group: &SimpleActionGroup, _, _| {
                println!("lkasjdfklja de maconha: {:?}", action_group);
            })
            .build();
        let actions = SimpleActionGroup::new();

        actions.add_action_entries([action_print]);
        text_view.insert_action_group("buffer", Some(&actions));
        text_view.add_controller(KeyMap::buffer_controller().controller);

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

struct ModeLine {
    content: CenterBox,
}

impl ModeLine {
    fn default() -> ModeLine {
        let command_line = Text::builder().focus_on_click(false).build();
        let disabled_keys = ShortcutTrigger::parse_string("Tab").unwrap();
        let shortcut_disable_action = CallbackAction::new(|_, _| { true });
        let disableds = Shortcut::builder().trigger(&disabled_keys).action(&shortcut_disable_action).build();
        let controller = ShortcutController::new();

        controller.add_shortcut(disableds);
        command_line.add_controller(controller);

        command_line.connect_activate(|text| {
            let content = text.buffer().text();
            text.emit_move_focus(gtk::DirectionType::TabBackward);
            let _ = text.activate_action("win.command_to_buffer", None);
            // _ = Function::execute(content.as_str(), text).map_err(|err| println!("Error: {}", err));
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

pub struct Window;

impl Window {
    pub fn build(app: &Application) {
        let buffer = Buffer::default();
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

        let action_print = ActionEntry::builder("command_to_buffer")
            .activate(|window: &ApplicationWindow, _, _| {
                let text_view_ref = gtk::prelude::GtkWindowExt::focus(window).unwrap();
                if let Some(text_view) = text_view_ref.downcast_ref::<TextView>() {
                    let _ = text_view.activate_action("buffer.command", None);
                }
            })
            .build();

        window.add_action_entries([action_print]);
        window.present();
    }
}
