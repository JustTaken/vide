use crate::action::{BufferCommand, Bind, Action, CommandLineCommand};
use std::{
    sync::{Arc, Mutex},
};

use gtk::{
    Shortcut,
    ShortcutController,
    ShortcutTrigger,
    CallbackAction,
};

pub struct KeyMap {
    pub controller: ShortcutController,
}

impl KeyMap {
    pub fn disable_keys_shortcut(keys: &str) -> Shortcut {
        let disabled_keys = ShortcutTrigger::parse_string(keys).unwrap();
        let shortcut_disable_action = CallbackAction::new(|_, _| { true });

        Shortcut::builder().trigger(&disabled_keys).action(&shortcut_disable_action).build()
    }

    pub fn command_line_controller() -> KeyMap {
        let bindings: Vec<Shortcut> = vec![
            Action::key_final(None, Bind::ControlP, vec![], CommandLineCommand::prev_completion),
            Action::key_final(None, Bind::ControlN, vec![], CommandLineCommand::next_completion),
            Action::key_final(None, Bind::ControlG, vec![], CommandLineCommand::close_completion),
            Action::key_final(None, Bind::Esc, vec![], CommandLineCommand::close),
            Action::key_final(None, Bind::Tab, vec![], CommandLineCommand::complete),

            KeyMap::disable_keys_shortcut("<Control>semicolon|<Control>period"),
        ];

        let controller = ShortcutController::new();
        bindings.into_iter().for_each(|b| controller.add_shortcut(b));

        KeyMap {
            controller,
        }

    }

    pub fn buffer_controller() -> KeyMap {
        let base_bindings: Arc<Mutex<Vec<Bind>>> = Arc::new(Mutex::new(Vec::new()));
        let bindings: Vec<Shortcut> = vec![
            Action::key_base(base_bindings.clone(), Bind::ControlX, vec![]),
            Action::key_final(Some(base_bindings.clone()), Bind::ControlColon, vec![], CommandLineCommand::open),

            Action::key_final(Some(base_bindings.clone()), Bind::ControlN, vec![], BufferCommand::next_line),
            Action::key_final(Some(base_bindings.clone()), Bind::ControlP, vec![], BufferCommand::prev_line),

            Action::key_final(Some(base_bindings.clone()), Bind::ControlA, vec![], BufferCommand::begin_line),
            Action::key_final(Some(base_bindings.clone()), Bind::ControlE, vec![], BufferCommand::end_line),

            Action::key_final(Some(base_bindings.clone()), Bind::ControlF, vec![], BufferCommand::forward_char),
            Action::key_final(Some(base_bindings.clone()), Bind::ControlB, vec![], BufferCommand::backward_char),

            Action::key_final(Some(base_bindings.clone()), Bind::AltF, vec![], BufferCommand::forward_word),
            Action::key_final(Some(base_bindings.clone()), Bind::AltB, vec![], BufferCommand::backward_word),

            Action::key_final(Some(base_bindings.clone()), Bind::ControlV, vec![], BufferCommand::forward_page),
            Action::key_final(Some(base_bindings.clone()), Bind::AltV, vec![], BufferCommand::backward_page),

            Action::key_final(Some(base_bindings.clone()), Bind::AltGreater, vec![], BufferCommand::buffer_end),
            Action::key_final(Some(base_bindings.clone()), Bind::AltLess, vec![], BufferCommand::buffer_begin),

            KeyMap::disable_keys_shortcut("<Control>semicolon|<Control>period|Delete|F7|Home|End|Insert|<Control>c|<Shift>Insert|<Shift><Control>a"),
        ];

        let controller = ShortcutController::new();
        bindings.into_iter().for_each(|b| controller.add_shortcut(b));

        KeyMap {
            controller,
        }
    }
}
