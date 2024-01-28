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
    gio::{ActionEntry, SimpleAction, ListStore},
    glib::{VariantTy, variant::Variant},
};

pub enum CompletionCommand {
    Show,
    Complete,
}

impl CompletionCommand {
    fn name(name: &str) -> Result<CompletionCommand, &'static str>{
        match name {
            "show" => Ok(CompletionCommand::Show),
            "complete" => Ok(CompletionCommand::Complete),
            _ => Err("Command does not exist")
        }
    }
    pub fn execute<'a>(content: &str, list_completion: &ListBox, buffers: MutexGuard<'_, Vec<Buffer>>) -> Result<(), &'static str> {
        let mut iter = content.split(' ').collect::<Vec<&str>>().into_iter();
        match CompletionCommand::name(iter.next().unwrap())? {
            CompletionCommand::Show => {
                let command = iter.next();
                let argument = iter.last();

                if let Some(argument) = argument {
                    if let Ok(command) = BufferCommand::name(command.unwrap()) {
                        match command {
                            BufferCommand::Buffer => {
                                let mut boxes: Vec<gtk::Box> = Vec::new();
                                let argument_list = buffers
                                    .iter()
                                    .map(|b| &b.name[..])
                                    .filter(|name| name.contains(argument))
                                    .map(|s| s.to_string())
                                    .collect::<Vec<String>>();

                                for i in 0..argument_list.len() {
                                    if i % 3 == 0 {
                                        boxes.push(gtk::Box::builder().orientation(Orientation::Horizontal).build());
                                    }

                                    boxes
                                        .last_mut()
                                        .unwrap()
                                        .append(
                                            &Text::builder()
                                            .css_name("buffer")
                                            .buffer(&EntryBuffer::new(Some(&argument_list[i][..])))
                                            .build()
                                        );
                                }

                                list_completion.remove_all();
                                for row in boxes.iter() {
                                    list_completion.append(row);
                                }
                            }
                            _ => return Err("Command do not accept arguments"),
                        }
                    } else {
                        return Err("Invalid command")
                    }
                } else {
                    let mut boxes: Vec<gtk::Box> = Vec::new();
                    let command = command.unwrap_or_else(|| "");
                    let command_list = BufferCommand::list_commands()
                        .into_iter()
                        .filter(|s| s.contains(command))
                        .collect::<Vec<String>>();

                    for i in 0..command_list.len() {
                        if i % 3 == 0 {
                            boxes.push(gtk::Box::builder().orientation(Orientation::Horizontal).build());
                        }

                        boxes.last_mut().unwrap().append(&Text::builder().css_name("buffer").buffer(&EntryBuffer::new(Some(&command_list[i][..]))).build());
                    }

                    list_completion.remove_all();
                    for row in boxes.iter() {
                        list_completion.append(row);
                    }
                }
                list_completion.set_visible(true);
                Ok(())
            },
            CompletionCommand::Complete => {Err("Not implemented")},
        }
    }
}

pub enum CommandLineCommand {
    EditBufferName,
    Focus,
}

impl CommandLineCommand {
    fn name(name: &str) -> Result<CommandLineCommand, ()> {
        match name {
            "edit" => Ok(CommandLineCommand::EditBufferName),
            "focus" => Ok(CommandLineCommand::Focus),
            _ => Err(()),
        }
    }

    pub fn execute(command: &str, center_box: &gtk::CenterBox) -> Result<(), &'static str> {
        let text = command.split(' ').collect::<Vec<&str>>();

        if let Ok(command) = CommandLineCommand::name(text[0]) {
            match command {
                CommandLineCommand::EditBufferName => Function::edit_statusline_buffer_name(text[1], &center_box.center_widget().unwrap()),
                CommandLineCommand::Focus => Function::focus_command_line(&center_box.start_widget().unwrap()),
            }
        } else {
            Err("Command not found")
        }
    }
}

pub enum BufferCommand {
    Edit,
    Buffer,
    List,
}

impl BufferCommand {
    fn arguments_count(&self) -> usize {
        match self {
            BufferCommand::Edit => 1,
            BufferCommand::Buffer => 1,
            BufferCommand::List => 0,
        }
    }

    fn name(name: &str) -> Result<BufferCommand, ()> {
        match name {
            "edit" => Ok(BufferCommand::Edit),
            "buffer" => Ok(BufferCommand::Buffer),
            "list" => Ok(BufferCommand::List),
            _ => Err(()),
        }
    }

    fn list_commands() -> Vec<String> {
        vec![
            "edit".to_owned(),
            "buffer".to_owned(),
            "list".to_owned(),
        ]
    }

    pub fn validate(command: &str) -> Result<(), &'static str> {
        let mut text = command.split(' ').collect::<Vec<&str>>().into_iter();
        if let Some(command) = text.next() {
            if let Ok(command) = BufferCommand::name(command) {
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
                    BufferCommand::Edit => Function::open_file(argument, text_view, buffers),
                    BufferCommand::Buffer => Function::open_buffer(argument, text_view, buffers),
                    BufferCommand::List => Function::list_buffers(buffers),
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
}

#[derive(Debug)]
pub struct Function;

impl Function {
    pub fn open_command(widget: &Widget) {
        if let Err(err) = widget.activate_action("win.to_statusline", Some(&"focus".to_variant())) {
            println!("Error: {}", err);
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

    fn list_buffers(buffers: MutexGuard<'_, Vec<Buffer>>) -> Result<(), &'static str> {
        for i in 0..buffers.len() {
            println!("{:?}", buffers[i]);
        }
        Ok(())
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

   fn focus_command_line(command_line_widget: &Widget) -> Result<(), &'static str> {
       command_line_widget.grab_focus();
       Ok(())
   }

   fn edit_statusline_buffer_name(name: &str, center_widget: &Widget) -> Result<(), &'static str> {
        let center_widget = center_widget.downcast_ref::<Text>();

        if let Some(center_widget) = center_widget {
            center_widget.set_buffer(&EntryBuffer::new(Some(name)));
            Ok(())
        } else {
            Err("Could not get center widget")
        }
   }


    pub fn query_completion(content: &str, widget: &Text) -> Result<(), &'static str> {
        if let Err(_) = widget.activate_action("win.to_completion_list", Some(&content.to_variant())) {
            Err("Could not query completion")
        } else {
            Ok(())
        }
    }
}

enum Completion {
    Command,
    Argument,
}

impl Completion {
    fn new(typ: &str) -> Result<Completion, ()> {
        match typ {
            "command" => Ok(Completion::Command),
            "arg" => Ok(Completion::Argument),
            _ => Err(()),
        }
    }
}

#[derive(Clone, PartialEq, Debug, Copy)]
pub enum Binding {
    ControlX,
    ControlColon,

    ControlN,
    ControlP,
    ControlA,
    ControlE,

    ControlF,
    ControlB,
    ControlV,

    AltV,
    AltF,
    AltB,

    AltGreater,
    AltLess,
}

impl Binding {
    pub fn to_string<'a>(&'a self) -> &'a str{
        match self {
            Binding::ControlX => "<Control>x",
            Binding::ControlColon => "<Control>colon",
            Binding::ControlN => "<Control>n",
            Binding::ControlP => "<Control>p",
            Binding::ControlA => "<Control>a",
            Binding::ControlE => "<Control>e",

            Binding::ControlF => "<Control>f",
            Binding::ControlB => "<Control>b",
            Binding::ControlV => "<Control>v",

            Binding::AltV => "<Alt>v",
            Binding::AltF => "<Alt>f",
            Binding::AltB => "<Alt>b",

            Binding::AltGreater => "<Alt>greater",
            Binding::AltLess => "<Alt>less",
        }
    }
}

pub struct Action;

impl Action {
    pub fn key_base(bindings: Arc<Mutex<Vec<Binding>>>, binding: Binding, base: Vec<Binding>) -> Shortcut {
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

    pub fn key_final<F: Fn(&Widget) + 'static>(bindings: Arc<Mutex<Vec<Binding>>>, binding: Binding, base: Vec<Binding>, function: F) -> Shortcut {
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

    pub fn entry<W, F>(name: &str, typ: Cow<'static, VariantTy>, function: F) -> ActionEntry<W> where
        W: IsA<gtk::Window> + IsA<gtk::gio::ActionMap>,
        F: Fn(&W, &SimpleAction, Option<&Variant>) + 'static {

        ActionEntry::builder(name)
            .parameter_type(Some(&typ))
            .activate(function)
            .build()
    }
}
