use std::sync::{Arc, Mutex, MutexGuard};
use crate::{
    keymap::KeyMap,
    action::Action,
};

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
    Widget,
    MovementStep,
    gio::{SimpleAction},
};

#[derive(Debug)]
pub struct Buffer {
    pub content: Option<TextBuffer>,
    pub name: String,
}

pub struct TextWindow {
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

    fn list_commands() -> Vec<String> {
        vec![
            "edit".to_owned(),
            "buffer".to_owned(),
        ]
    }

    pub fn validate(command: &str) -> Result<(), &'static str> {
        let mut text = command.split(' ').collect::<Vec<&str>>().into_iter();
        if let Some(command) = text.next() {
            match command {
                "edit" | "buffer" => Ok(()),
                _ => Err("Command not found"),
            }
        } else {
            Err("No command provided")
        }
    }

    pub fn execute(command: &str, text_view: &TextView, buffers: MutexGuard<'_, Vec<Buffer>>) -> Result<(), &'static str> {
        let mut text = command.split(' ').collect::<Vec<&str>>().into_iter();
        let command = text.next().unwrap();

        if let Some(argument) = text.next() {
            match command {
                "edit" => TextWindow::open_file(argument, text_view, buffers),
                "buffer" => TextWindow::open_buffer(argument, text_view, buffers),
                _ => Err("Command not found")
            }
        } else {
            Err("No argument provided")
        }
    }

    pub fn next_line(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::DisplayLines, 1, false);
    }

    pub fn prev_line(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::DisplayLines, -1, false);
    }

    pub fn end_line(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::DisplayLineEnds, 1, false);
    }

    pub fn begin_line(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::DisplayLineEnds, -1, false);
    }

    pub fn forward_word(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::Words, 1, false);
    }

    pub fn backward_word(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::Words, -1, false);
    }

    pub fn forward_char(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::LogicalPositions, 1, false);
    }

    pub fn backward_char(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::LogicalPositions, -1, false);
    }

    pub fn buffer_end(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::BufferEnds, 1, false);
    }

    pub fn buffer_begin(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::BufferEnds, -1, false);
    }

    pub fn forward_page(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::Pages, 1, false);
    }

    pub fn backward_page(widget: &Widget) {
        let text_view = widget.downcast_ref::<gtk::TextView>().unwrap();
        text_view.emit_move_cursor(MovementStep::Pages, -1, false);
    }

    fn open_buffer(buffer_name: &str, text_view: &TextView, mut buffers: MutexGuard<'_, Vec<Buffer>>) -> Result<(), &'static str> {
        let mut current_buffer_index: Option<usize> = None;
        let mut next_buffer_index: Option<usize> = None;

        for i in 0..buffers.len() {
            if let None = buffers[i].content {
                current_buffer_index = Some(i);
            }

            if buffer_name == buffers[i].name{
                next_buffer_index = Some(i);
            }
        }

        if let (Some(i), Some(j)) = (current_buffer_index, next_buffer_index) {
            buffers[i].content = Some(text_view.buffer());
            text_view.set_buffer(buffers[j].content.take().as_ref());

            if let Err(err) = text_view.activate_action("win.to_statusline", Some(&format!("edit {}", buffer_name).to_variant())) {
                println!("Error: {}", err);
            }
            Ok(())
        } else {
            Err("Buffer not found")
        }
    }

   pub fn open_file(file_name: &str, text_view: &TextView, mut buffers: MutexGuard<'_, Vec<Buffer>>) -> Result<(), &'static str>{
        if let Ok(content) = std::fs::read_to_string(file_name) {
            let mut current_buffer_index = None;
            let mut in_buffers = None;

            for i in 0..buffers.len() {
                if buffers[i].name == file_name {
                    in_buffers = Some(i)
                }

                if let None = buffers[i].content {
                    current_buffer_index = Some(i);
                }
            }

            if let (Some(i), Some(j)) = (in_buffers, current_buffer_index) {
                buffers[j].content = Some(text_view.buffer());
                text_view.set_buffer(buffers[i].content.take().as_ref());
            } else if let Some(i) = current_buffer_index {
                buffers[i].content = Some(text_view.buffer());
                buffers.push(Buffer {content: None, name: file_name.to_string()});

                let text_buffer = TextBuffer::builder().text(&content[..]).build();
                text_view.set_buffer(Some(&text_buffer));
            }

            if let Err(err) = text_view.activate_action("win.to_statusline", Some(&format!("edit {}", file_name).to_owned().to_variant())) {
                println!("Error: {}", err);
            }
            Ok(())
        } else {
            Err("Could not read the file")
        }
   }
}

struct CompletionList {
    content: ListBox,
}

impl CompletionList {
    fn default() -> CompletionList {
        CompletionList {
            content: ListBox::builder()
            .css_name("completion")
            .visible(false)
            .build()
        }
    }

    pub fn execute(arguments: &str, action: &SimpleAction, list_box: &ListBox, buffers: Arc<Mutex<Vec<Buffer>>>) -> Result<(), &'static str>  {
        let mut command = arguments.split(' ').collect::<Vec<&str>>().into_iter();
        let first_arg = command.next().unwrap();

        match first_arg {
            "show" => CompletionList::show(action, arguments, list_box, buffers.lock().unwrap()),
            "close" => CompletionList::close(action, list_box),
            "display" => CompletionList::display(action, list_box),
            "next" => CompletionList::change_index(1, action, list_box),
            "prev" => CompletionList::change_index(-1, action, list_box),
            _ => Err("Command not found"),
        }
    }

    fn close(action: &SimpleAction, list_box: &ListBox) -> Result<(), &'static str> {
        list_box.set_visible(false);
        action.set_state(&vec![0, 0, 0].to_variant());
        Ok(())
    }

    fn show<'a>(action: &SimpleAction, content: &str, completion_box: &ListBox, buffers: MutexGuard<'_, Vec<Buffer>>) -> Result<(), &'static str> {
        if completion_box.get_visible() {
            return CompletionList::complete(action, completion_box);
        } else {
            completion_box.set_visible(true);
        }

        let mut iter = content.split(' ').collect::<Vec<&str>>().into_iter();
        let _ = iter.next();
        let command = iter.next();
        let argument = iter.last();

        let completion_list = if let Some(argument) = argument {
            match command.unwrap() {
                "buffer" => CompletionList::buffer_completion(argument, buffers),
                "edit" => CompletionList::file_completion(argument),
                _ => return Err("Command not found"),
            }
        } else {
            CompletionList::command_completion(command)
        };

        completion_box.remove_all();
        let len = if completion_list.len() == 0 { return Err("No completion is possible") } else { completion_list.len() };

        let completion_list_rest = len % 3;
        let number_of_rows = if completion_list_rest == 0 { (len - completion_list_rest) / 3 } else { (len - completion_list_rest) / 3 + 1 };
        let boxes = (0..number_of_rows).map(|_| gtk::Box::builder().orientation(Orientation::Horizontal).build()).collect::<Vec<gtk::Box>>();

        completion_list.iter().enumerate().for_each(|(i, c)| boxes[(i - i % 3) / 3].append(&Text::builder().css_name("completion").hexpand(true).buffer(&EntryBuffer::new(Some(c))).build()));
        boxes.iter().for_each(|row| completion_box.append(row));

        let state = action.state().unwrap().get::<Vec<i32>>().unwrap();
        action.set_state(&vec![state[0], state[1], len as i32].to_variant());

        if let Err(_) = completion_box.activate_action("win.to_completion_list", Some(&"display".to_variant())) {
            Err("Could not ask to window display new completion")
        } else {
            Ok(())
        }
    }

    fn complete(action: &SimpleAction, completion_box: &ListBox) -> Result<(), &'static str> {
        let state = action.state().unwrap().get::<Vec<i32>>().unwrap();
        let rest = state[0] % 3;

        if let Some(row) = completion_box.row_at_index(((state[0] - rest ) / 3) as i32) {
            let box_widget = row.first_child().unwrap();
            let mut text_widget = box_widget.first_child().unwrap();

            for _ in 0..rest {
                if let Some(widget) = text_widget.next_sibling() {
                    text_widget = widget;
                }
            }

            let text = text_widget.downcast_ref::<Text>().unwrap();
            if let Err(_) =  completion_box.activate_action("win.to_statusline", Some(&format!("content {}", text.buffer().text()).to_variant())) {
                Err("Could not completion content to statusline")
            } else if let Err(_) = completion_box.activate_action("win.to_completion_list", Some(&"close".to_variant())) {
                Err("Could not close completion list")
            } else {
                Ok(())
            }
        } else {
            Err("No completion list at index")
        }
    }

    fn display(action: &SimpleAction, completion_box: &ListBox) -> Result<(), &'static str> {
        let state = action.state().unwrap().get::<Vec<i32>>().unwrap();
        let len = state[2] as usize;

        let prev_index = state[1] as usize % len;
        let prev_rest = prev_index % 3;
        let prev_index_module = (prev_index - prev_rest) / 3;

        let index = state[0] as usize % len;
        let rest = index % 3;
        let index_module = (index - rest) / 3;

        if let Some(row) = completion_box.row_at_index(index_module as i32) {
            let row_box_widget = row.first_child().unwrap();
            let mut text_widget = row_box_widget.first_child().unwrap();
            for _ in 0..rest {
                if let Some(widget) = text_widget.next_sibling() {
                    text_widget = widget;
                } else {
                    return Err("Could not get the right completion widget to highlight")
                }
            }

            let prev_row = completion_box.row_at_index(prev_index_module as i32).unwrap();
            let row_box_widget = prev_row.first_child().unwrap();
            let mut prev_text_widget = row_box_widget.first_child().unwrap();

            for _ in 0..prev_rest {
                if let Some(widget) = prev_text_widget.next_sibling() {
                    prev_text_widget = widget;
                } else {
                    return Err("Could not get the right completion widget to highlight")
                }
            }
            prev_text_widget.remove_css_class("on");
            text_widget.set_css_classes(&["on"]);
            Ok(())
        } else {
            Err("No completion box at index")
        }
    }

    fn change_index(factor: i32, action: &SimpleAction, completion_box: &ListBox) -> Result<(), &'static str> {
        let state = action.state().unwrap().get::<Vec<i32>>().unwrap();
        let mut index = (state[0] + factor) % state[2];
        if index < 0 {
            index = state[2] - 1;
        }

        action.set_state(&vec![index, state[0], state[2]].to_variant());
        if let Err(_) = completion_box.activate_action("win.to_completion_list", Some(&"display".to_variant())) {
            Err("Could not ask to window display new completion")
        } else {
            Ok(())
        }
    }

    fn command_completion(command: Option<&str>) -> Vec<String> {
        let command = command.unwrap_or_else(|| "");
        TextWindow::list_commands()
            .into_iter()
            .filter(|s| s.contains(command))
            .map(|s| s[command.len()..].to_owned())
            .collect::<Vec<String>>()
    }

    fn buffer_completion(argument: &str, buffers: MutexGuard<'_, Vec<Buffer>>) -> Vec<String> {
        buffers
            .iter()
            .map(|b| &b.name[..])
            .filter(|name| name.contains(argument))
            .map(|s| s[argument.len()..].to_string())
            .collect::<Vec<String>>()
    }

    fn file_completion(argument: &str) -> Vec<String> {
        if argument.contains(" ") {
            return Vec::new();
        }

        let mut text = argument.split('/').collect::<Vec<&str>>();
        let last = text.pop().unwrap_or_else(|| "");
        if text.len() == 0 {
            text.push(".");
        }
        if let Ok(entries) = std::fs::read_dir(text.join("/")) {
            entries.
                filter(|e| e.is_ok())
                    .map(|e| {
                            let e = e.unwrap();
                            if e.file_type().unwrap().is_dir() {
                                format!("{}/", e.file_name().into_string().unwrap())
                            } else {
                                format!("{}", e.file_name().into_string().unwrap())
                            }
                        }
                    )
                    .filter(|e| e.contains(last))
                    .map(|e| e[last.len()..].to_owned())
                    .filter(|e| e != "")
                    .collect::<Vec<String>>()
        } else {
            Vec::new()
        }
    }

}

pub struct StatusLine {
    content: CenterBox,
}

impl StatusLine {
    fn default() -> StatusLine {
        let command_line = Text::builder()
            .css_name("default")
            .hexpand(true)
            .focus_on_click(false)
            .build();
        command_line.add_controller(KeyMap::command_line_controller().controller);

        command_line.connect_activate(|text| {
            let content = text.buffer().text();
            if let Err(err) = TextWindow::validate(&content) {
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

        StatusLine {
            content,
        }
    }

    pub fn execute(cmd: &str, center_box: &gtk::CenterBox) -> Result<(), &'static str> {
        let text = cmd.split(' ').collect::<Vec<&str>>();

        match text[0] {
            "edit" => StatusLine::edit_buffer_name(text[1], &center_box.center_widget().unwrap()),
            "focus" => StatusLine::focus(&center_box.start_widget().unwrap()),
            "content" => StatusLine::edit_content(&text[1..], center_box),
            _ => Err("Command not found")
        }
    }

   fn edit_buffer_name(name: &str, center_widget: &Widget) -> Result<(), &'static str> {
        let center_widget = center_widget.downcast_ref::<Text>();

        if let Some(center_widget) = center_widget {
            center_widget.set_buffer(&EntryBuffer::new(Some(name)));
            Ok(())
        } else {
            Err("Could not get center widget")
        }
   }

    fn edit_content(content: &[&str], center_box: &gtk::CenterBox) -> Result<(), &'static str> {
        let content = content.join(" ");

        if let Some(command_line) = center_box.start_widget() {
            if let Some(text) = command_line.downcast_ref::<Text>() {
                let len = text.text_length();
                let content_len = content.len() as usize;

                text.buffer().insert_text(len, &content[..]);
                text.emit_move_cursor(MovementStep::LogicalPositions, content_len as i32, false);
                Ok(())
            } else {
                Err("Could not cast command line to Text widget")
            }
        } else {
            Err("Could not get command line widget")
        }

    }

   fn focus(command_line_widget: &Widget) -> Result<(), &'static str> {
       command_line_widget.grab_focus();
       Ok(())
   }

    pub fn open(widget: &Widget) {
        if let Err(err) = widget.activate_action("win.to_statusline", Some(&"focus".to_variant())) {
            println!("Error: {}", err);
        }
    }

    pub fn close_completion(widget: &Widget) {
        if let Err(_) = widget.activate_action("win.to_completion_list", Some(&"close".to_variant())) {
            println!("Error: Could not close completion list");
        }
    }

    pub fn prev_completion(widget: &Widget) {
        let text = widget.downcast_ref::<Text>().unwrap();
        let content = text.buffer().text();

        if let Err(_) = widget.activate_action("win.to_completion_list", Some(&format!("prev {}", content).to_variant())) {
            println!("Error: Could not get next completion element");
        }
    }

    pub fn next_completion(widget: &Widget) {
        let text = widget.downcast_ref::<Text>().unwrap();
        let content = text.buffer().text();

        if let Err(_) = widget.activate_action("win.to_completion_list", Some(&format!("next {}", content).to_variant())) {
            println!("Error: Could not get next completion element");
        }
    }

    pub fn complete(widget: &Widget) {
        let text = widget.downcast_ref::<Text>().unwrap();
        let content = text.buffer().text();

        if let Err(_) = widget.activate_action("win.to_completion_list", Some(&format!("show {}", content).to_variant())) {
            println!("Could not query completion")
        }
    }
    pub fn close(widget: &Widget) {
        let text = widget.downcast_ref::<Text>().unwrap();
        text.buffer().delete_text(0, None);
        text.emit_move_focus(gtk::DirectionType::TabBackward);

        if let Err(_) = widget.activate_action("win.to_completion_list", Some(&"close".to_variant())) {
            println!("Error: Could not close completion list");
        }
    }
}

pub struct Window;

impl Window {
    pub fn build(app: &Application) {
        let buffer = TextWindow::default();
        let statusline = StatusLine::default();
        let completion_list = CompletionList::default();
        let window_box = gtk::Box::builder().orientation(Orientation::Vertical).build();

        window_box.append(&buffer.content);
        window_box.append(&completion_list.content);
        window_box.append(&statusline.content);

        let window = ApplicationWindow::builder()
            .application(app)
            .default_width(600)
            .default_height(400)
            .title("vide")
            .child(&window_box)
            .build();

        let buffers: Arc<Mutex<Vec<Buffer>>> = Arc::new(Mutex::new(vec![Buffer {content: None, name: "scratch".to_owned()}]));
        let buffers_to_completion = buffers.clone();

        window.add_action_entries([
            Action::entry("to_buffer", String::static_variant_type(), 0.to_variant(), move |window, _, variant| {
                let text_view_ref = gtk::prelude::GtkWindowExt::focus(window).unwrap();
                let arguments = variant.unwrap().get::<String>().unwrap();

                if let Ok(buffers) = buffers.clone().lock() {
                    if let Some(text_view) = text_view_ref.downcast_ref::<TextView>() {
                        if let Err(err) = TextWindow::execute(&arguments[..], text_view, buffers) {
                            println!("Error: {err}");
                        }
                    }
                }
            }),
            Action::entry("to_statusline", String::static_variant_type(), 0.to_variant(), move |window: &ApplicationWindow, _, variant| {
                let widget_centered_box_ref= window.first_child().unwrap().last_child().unwrap();
                let center_box = widget_centered_box_ref.downcast_ref::<gtk::CenterBox>();

                if let Some(center_box) = center_box {
                    let arguments = variant.unwrap().get::<String>().unwrap();
                    if let Err(err) = StatusLine::execute(&arguments[..], center_box) {
                        println!("Error: {}", err);
                    }
                }
            }),
            Action::entry("to_completion_list", String::static_variant_type(), [0, 0, 0].to_variant(), move |window: &ApplicationWindow, action, variant| {
                let widget_centered_box_ref= window.first_child().unwrap().last_child().unwrap();
                let list_box_ref = widget_centered_box_ref.prev_sibling();

                if let Some(list_box) = list_box_ref {
                    let arguments = variant.unwrap().get::<String>().unwrap();
                    let list_box = list_box.downcast_ref::<ListBox>().unwrap();
                    if let Err(err) = CompletionList::execute(&arguments[..], action, &list_box, buffers_to_completion.clone()) {
                        println!("Error: {err}");
                    }
                }
            })
        ]);

        window.present();
    }
}

