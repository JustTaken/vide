use crate::window::Buffer;
use std::{
    sync::{Arc, Mutex},
};

use gtk::{
    prelude::*,
    Widget,
    TextView,
    TextBuffer,
    MovementStep,
    Shortcut,
    ShortcutTrigger,
    CallbackAction,
};

#[derive(Debug)]
pub enum Function {
    Edit,
    Buffer,
    List,
}

impl Function {
    fn arguments(&self) -> usize {
        match self {
            Function::Edit => 1,
            Function::Buffer => 1,
            Function::List => 0,
        }
    }

    fn name(name: &str) -> Result<Function, ()> {
        match name {
            "edit" => Ok(Function::Edit),
            "buffer" => Ok(Function::Buffer),
            "list" => Ok(Function::List),
            _ => Err(()),
        }
    }

    pub fn execute_command(command: &str, text_view: &TextView, buffers: Arc<Mutex<Vec<Buffer>>>) -> Result<(), &'static str> {
        let text = command.split(' ').collect::<Vec<&str>>();
        if let Ok(command) = Function::name(text[0]) {
            match command {
                Function::Edit => Function::open_file(text[1], text_view, buffers),
                Function::Buffer => Function::open_buffer(text[1], text_view, buffers),
                Function::List => Function::list_buffers(buffers),
                _ => Ok(()),
            }
        } else {
            Err("Command not found")
        }
    }

    pub fn open_command(widget: &Widget) {
        let window_box_widget = widget.parent().unwrap().parent().unwrap();
        let window_box = window_box_widget.downcast_ref::<gtk::Box>().unwrap();
        let mode_line = window_box.last_child().unwrap();
        mode_line.downcast_ref::<gtk::CenterBox>().unwrap().start_widget().unwrap().grab_focus();
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

    pub fn validate_command(command: &str) -> Result<(), &'static str> {
        let mut text = command.split(' ').collect::<Vec<&str>>().into_iter();
        if let Some(command) = text.next() {
            if let Ok(command) = Function::name(command) {
                if text.count() == command.arguments() {
                    Ok(())
                } else {
                    Err("Not a valida number of arguments")
                }
            } else {
                Err("Command not found")
            }
        } else {
            Err("No command provided")
        }
    }

    fn list_buffers(buffers: Arc<Mutex<Vec<Buffer>>>) -> Result<(), &'static str> {
        println!("listing buffers -------------");
        if let Ok(buffers) = buffers.lock() {
            for i in 0..buffers.len() {
                println!("{:?}", buffers[i]);
            }
            Ok(())
        } else {
            Err("Error opening the buffer list")
        }
    }

    fn open_buffer(buffer_name: &str, text_view: &TextView, buffers: Arc<Mutex<Vec<Buffer>>>) -> Result<(), &'static str> {
        if let Ok(mut buffers) = buffers.lock() {
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
                Ok(())
            } else {
                Err("Buffernot found")
            }
        } else {
            Err("Error locking buffer list")
        }
    }

   pub fn open_file(file_name: &str, text_view: &TextView, buffers: Arc<Mutex<Vec<Buffer>>>) -> Result<(), &'static str>{
        if let Ok(content) = std::fs::read_to_string(file_name) {
            if let Ok(mut buffers) = buffers.lock() {
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
                    buffers.push(Buffer {content: None, name: file_name.to_owned()});

                    let text_buffer = TextBuffer::builder().text(&content[..]).build();
                    text_view.set_buffer(Some(&text_buffer));
                }

                Ok(())
            } else {
                Err("Error opening buffer list")
            }
        } else {
            Err("Could not read the file")
        }
   }
}

#[derive(Clone, PartialEq, Debug, Copy)]
pub enum Binding {
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
    pub fn to_string<'a>(&'a self) -> &'a str{
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

    pub fn new_base(bindings: Arc<Mutex<Vec<Binding>>>, binding: Binding, base: Vec<Binding>) -> Shortcut {
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

    pub fn new_final<F: Fn(&Widget) + 'static>(bindings: Arc<Mutex<Vec<Binding>>>, binding: Binding, base: Vec<Binding>, function: F) -> Shortcut {
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
