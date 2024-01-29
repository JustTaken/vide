use crate::{
    keymap::KeyMap,
    action::{
        Action,
        BufferCommand,
        CommandLineCommand,
        CompletionCommand
    },
};

use std::sync::{Arc, Mutex};

use gtk::{
    prelude::*,
    Application,
    ApplicationWindow,
    ScrolledWindow,
    TextView,
    TextBuffer,
    Orientation,
    EntryBuffer,
    Text,
    CenterBox,
    ListBox,
};

#[derive(Debug)]
pub struct Buffer {
    pub content: Option<TextBuffer>,
    pub name: String,
}

struct TextWindow {
    content: ScrolledWindow,
}

impl TextWindow {
    fn default() -> TextWindow {
        let text = std::fs::read_to_string("assets/scratch").unwrap();
        let text_buffer = TextBuffer::builder()
            .text(text)
            .build();

        let text_view = TextView::builder()
            .css_name("default")
            .indent(4)
            .buffer(&text_buffer)
            .build();

        text_view.add_controller(KeyMap::buffer_controller().controller);

        let content = ScrolledWindow::builder()
            .hscrollbar_policy(gtk::PolicyType::Never)
            .child(&text_view)
            .hexpand(true)
            .vexpand(true)
            .css_name("text_window")
            .build();

        TextWindow {
            content,
        }
    }
}

struct StatusLine {
    content: CenterBox,
    completion_list: ListBox,
}

impl StatusLine {
    fn default() -> StatusLine {
        let command_line = Text::builder()
            .css_name("default")
            .focus_on_click(false)
            .build();
        command_line.add_controller(KeyMap::command_line_controller().controller);

        command_line.connect_activate(|text| {
            let content = text.buffer().text();
            if let Err(err) = BufferCommand::validate(&content) {
                println!("Error: {}", err);
            } else {
                text.buffer().delete_text(0, None);
                text.emit_move_focus(gtk::DirectionType::TabBackward);

                if let Err(err) = text.activate_action("win.to_buffer", Some(&content.to_variant())) {
                    println!("Error: {}", err);
                }
            }
        });

        let center = Text::builder().can_focus(false).css_name("default").build();
        let right = Text::builder().buffer(&EntryBuffer::new(Some("line:col"))).can_focus(false).css_name("default").build();
        let content = CenterBox::builder()
            .start_widget(&command_line)
            .center_widget(&center)
            .end_widget(&right)
            .build();

        let completion_list = ListBox::builder()
            .css_name("completion")
            .visible(false)
            .build();

        // completion_list.connect_row_selected(|list_box, row| {
        //     if let Some(row) = row {
        //         let row_box_ref = row.first_child().unwrap();
        //         let row_box = row_box_ref.downcast_ref::<gtk::Box>().unwrap();
        //         println!("row_Box: {:?}", row_box);
        //     }
        // });

        StatusLine {
            content,
            completion_list,
        }
    }
}


pub struct Window;

impl Window {
    pub fn build(app: &Application) {
        let buffer = TextWindow::default();
        let statusline = StatusLine::default();

        let window_box = gtk::Box::builder().orientation(Orientation::Vertical).build();
        window_box.append(&buffer.content);
        window_box.append(&statusline.completion_list);
        window_box.append(&statusline.content);

        let window = ApplicationWindow::builder()
            .application(app)
            .default_width(600)
            .default_height(400)
            .title("My App")
            .child(&window_box)
            .build();

        let buffers: Arc<Mutex<Vec<Buffer>>> = Arc::new(Mutex::new(vec![Buffer {content: None, name: "scratch".to_owned()}]));
        let buffers_to_completion = buffers.clone();
        window.add_action_entries([Action::entry("to_buffer", String::static_variant_type(), 0, move |window, _, variant| {
                let text_view_ref = gtk::prelude::GtkWindowExt::focus(window).unwrap();
                let arguments = variant.unwrap().get::<String>().unwrap();

                if let Ok(buffers) = buffers.lock() {
                    if let Some(text_view) = text_view_ref.downcast_ref::<TextView>() {
                        if let Err(err) = BufferCommand::execute(&arguments[..], text_view, buffers) {
                            println!("Error: {err}");
                        }
                    }
                }
            }
        )]);

        window.add_action_entries([Action::entry("to_statusline", String::static_variant_type(), 0, move |window: &ApplicationWindow, _, variant| {
            let widget_centered_box_ref= window.first_child().unwrap().last_child().unwrap();
            let center_box = widget_centered_box_ref.downcast_ref::<gtk::CenterBox>();

            if let Some(center_box) = center_box {
                let arguments = variant.unwrap().get::<String>().unwrap();
                if let Err(err) = CommandLineCommand::execute(&arguments[..], center_box) {
                    println!("Error: {}", err);
                }
            }
        })]);

        window.add_action_entries([Action::completion_entry("to_completion_list", String::static_variant_type(), [0, 0, 0], move |window: &ApplicationWindow, action, variant| {
            let widget_centered_box_ref= window.first_child().unwrap().last_child().unwrap();
            let list_box_ref = widget_centered_box_ref.prev_sibling();

            if let Some(list_box) = list_box_ref {
                let arguments = variant.unwrap().get::<String>().unwrap();
                let list_box = list_box.downcast_ref::<ListBox>().unwrap();

                if arguments.starts_with("close") {
                    list_box.set_visible(false);
                } else if !list_box.get_visible() {
                    list_box.set_visible(true);
                    if let Err(err) = CompletionCommand::update(action, &arguments[..], list_box, buffers_to_completion.lock().unwrap()) {
                        println!("Errr: {}", err);
                    }
                } else if arguments.starts_with("display") {
                    CompletionCommand::display(action, list_box);
                } else if arguments.starts_with("next") {
                    CompletionCommand::change_index(1, action, list_box);
                } else if arguments.starts_with("prev") {
                    CompletionCommand::change_index(-1, action, list_box);
                }
            }
        })]);

        window.present();
    }
}

