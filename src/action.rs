use crate::window::Buffer;
use std::{
    sync::{Arc, Mutex, MutexGuard},
    borrow::Cow,
};

use gtk::{
    prelude::*,
    Widget,
    TextView,
    TextBuffer,
    MovementStep,
    Shortcut,
    ShortcutTrigger,
    EntryBuffer,
    CallbackAction,
    Text,
    ListBox,
    Orientation,
    gio::{ActionEntry, SimpleAction},
    glib::{VariantTy, variant::Variant},
};

pub struct CompletionCommand;

impl CompletionCommand {
    pub fn update<'a>(action: &SimpleAction, content: &str, completion_box: &ListBox, buffers: MutexGuard<'_, Vec<Buffer>>) -> Result<(), &'static str> {
        let mut iter = content.split(' ').collect::<Vec<&str>>().into_iter();

        let _ = iter.next();
        let command = iter.next();
        let argument = iter.last();

        let completion_list = if let Some(argument) = argument {
            if let Ok(command) = BufferCommand::name(command.unwrap()) {
                match command {
                    BufferCommand::Buffer => CompletionCommand::buffer_completion(argument, buffers),
                    BufferCommand::Edit => CompletionCommand::file_completion(argument),
                }
            } else {
                return Err("Invalid command");
            }
        } else {
            CompletionCommand::command_completion(command)
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

    pub fn complete(action: &SimpleAction, completion_box: &ListBox) {
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
            let _ = completion_box.activate_action("win.to_statusline", Some(&format!("content {}", text.buffer().text()).to_variant()));
            let _ = completion_box.activate_action("win.to_completion_list", Some(&"close".to_variant()));
        }
    }

    pub fn display(action: &SimpleAction, completion_box: &ListBox) {
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
                }
            }

            let prev_row = completion_box.row_at_index(prev_index_module as i32).unwrap();
            let row_box_widget = prev_row.first_child().unwrap();
            let mut prev_text_widget = row_box_widget.first_child().unwrap();

            for _ in 0..prev_rest {
                if let Some(widget) = prev_text_widget.next_sibling() {
                    prev_text_widget = widget;
                }
            }
            prev_text_widget.remove_css_class("on");
            text_widget.set_css_classes(&["on"]);
        }
    }

    pub fn change_index(factor: i32, action: &SimpleAction, completion_box: &ListBox) {
        let state = action.state().unwrap().get::<Vec<i32>>().unwrap();
        let mut index = (state[0] + factor) % state[2];
        if index < 0 {
            index = state[2] - 1;
        }

        action.set_state(&vec![index, state[0], state[2]].to_variant());
        if let Err(_) = completion_box.activate_action("win.to_completion_list", Some(&"display".to_variant())) {
            println!("Could not ask to window display new completion")
        }
    }

    fn command_completion(command: Option<&str>) -> Vec<String> {
        let command = command.unwrap_or_else(|| "");
        BufferCommand::list_commands()
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

pub enum CommandLineCommand {
    EditBufferName,
    EditCommandContent,
    Focus,
}

impl CommandLineCommand {
    fn name(name: &str) -> Result<CommandLineCommand, ()> {
        match name {
            "edit" => Ok(CommandLineCommand::EditBufferName),
            "focus" => Ok(CommandLineCommand::Focus),
            "content" => Ok(CommandLineCommand::EditCommandContent),
            _ => Err(()),
        }
    }

    pub fn execute(cmd: &str, center_box: &gtk::CenterBox) -> Result<(), &'static str> {
        let text = cmd.split(' ').collect::<Vec<&str>>();

        if let Ok(command) = CommandLineCommand::name(text[0]) {
            match command {
                CommandLineCommand::EditBufferName => CommandLineCommand::edit_buffer_name(text[1], &center_box.center_widget().unwrap()),
                CommandLineCommand::Focus => CommandLineCommand::focus(&center_box.start_widget().unwrap()),
                CommandLineCommand::EditCommandContent=> CommandLineCommand::edit_content(&text[1..], center_box),
            }
        } else {
            Err("Command not found")
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

        if let Err(_) = widget.activate_action("win.to_completion_list", Some(&format!("complete {}", content).to_variant())) {
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

pub enum BufferCommand {
    Edit,
    Buffer,
}

impl BufferCommand {
    fn arguments_count(&self) -> usize {
        match self {
            BufferCommand::Edit => 1,
            BufferCommand::Buffer => 1,
        }
    }

    fn name(name: &str) -> Result<BufferCommand, ()> {
        match name {
            "edit" => Ok(BufferCommand::Edit),
            "buffer" => Ok(BufferCommand::Buffer),
            _ => Err(()),
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
            if let Ok(_) = BufferCommand::name(command) {
                Ok(())
            } else {
                Err("Command not found")
            }
        } else {
            Err("No command provided")
        }
    }

    pub fn execute(command: &str, text_view: &TextView, buffers: MutexGuard<'_, Vec<Buffer>>) -> Result<(), &'static str> {
        let mut text = command.split(' ').collect::<Vec<&str>>().into_iter();
        if let Ok(command) = BufferCommand::name(text.next().unwrap()) {
            if let Some(argument) = text.next() {
                match command {
                    BufferCommand::Edit => BufferCommand::open_file(argument, text_view, buffers),
                    BufferCommand::Buffer => BufferCommand::open_buffer(argument, text_view, buffers),
                }
            } else if command.arguments_count() != 0 {
                Err("Not enough arguments")
            } else {
                Ok(())
            }
        } else {
            Err("Command not found")
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
            Err("Buffernot found")
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

#[derive(Clone, PartialEq, Debug, Copy)]
pub enum Bind {
    Esc,
    ControlX,
    ControlColon,

    ControlN,
    ControlP,
    ControlA,
    ControlE,

    ControlF,
    ControlB,
    ControlV,
    ControlG,

    AltV,
    AltF,
    AltB,

    AltGreater,
    AltLess,

    Tab,
}

impl Bind {
    pub fn to_string<'a>(&'a self) -> &'a str{
        match self {
            Bind::Esc => "Escape",
            Bind::Tab => "Tab",

            Bind::ControlX => "<Control>x",
            Bind::ControlN => "<Control>n",
            Bind::ControlP => "<Control>p",
            Bind::ControlA => "<Control>a",
            Bind::ControlE => "<Control>e",
            Bind::ControlF => "<Control>f",
            Bind::ControlB => "<Control>b",
            Bind::ControlV => "<Control>v",
            Bind::ControlG => "<Control>g",
            Bind::ControlColon => "<Control>colon",

            Bind::AltV => "<Alt>v",
            Bind::AltF => "<Alt>f",
            Bind::AltB => "<Alt>b",
            Bind::AltLess => "<Alt>less",
            Bind::AltGreater => "<Alt>greater",

        }
    }
}

pub struct Action;

impl Action {
    pub fn key_base(bindings: Arc<Mutex<Vec<Bind>>>, binding: Bind, base: Vec<Bind>) -> Shortcut {
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

    pub fn key_final<F: Fn(&Widget) + 'static>(bindings: Option<Arc<Mutex<Vec<Bind>>>>, binding: Bind, base: Vec<Bind>, function: F) -> Shortcut {
        let trigger = ShortcutTrigger::parse_string(binding.to_string()).unwrap();
        let action = CallbackAction::new(move |widget, _| {
            if let Some(bindings) = &bindings {
                if let std::sync::LockResult::Ok(mut bindings) = bindings.lock() {
                    if bindings.eq(&base) {
                        function(&widget);
                    }

                    bindings.clear();
                    true
                } else {
                    false
                }
            } else {
                function(&widget);
                true
            }
        });

        Shortcut::builder().trigger(&trigger).action(&action).build()
    }

    pub fn entry<W, F>(name: &str, typ: Cow<'static, VariantTy>, state: Variant, function: F) -> ActionEntry<W> where
        W: IsA<gtk::Window> + IsA<gtk::gio::ActionMap>,
        F: Fn(&W, &SimpleAction, Option<&Variant>) + 'static {

        ActionEntry::builder(name)
            .parameter_type(Some(&typ))
            .state(state)
            .activate(function)
            .build()
    }
}
