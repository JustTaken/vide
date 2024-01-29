use crate::action::{BufferCommand, Binding, Action, CommandLineCommand};
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
        let base_bindings: Arc<Mutex<Vec<Binding>>> = Arc::new(Mutex::new(Vec::new()));
        let bindings: Vec<Shortcut> = vec![
            Action::key_final(base_bindings.clone(), Binding::ControlP, vec![], CommandLineCommand::prev_completion),
            Action::key_final(base_bindings.clone(), Binding::ControlN, vec![], CommandLineCommand::next_completion),
            Action::key_final(base_bindings.clone(), Binding::ControlG, vec![], CommandLineCommand::close_completion),
            Action::key_final(base_bindings.clone(), Binding::Esc, vec![], CommandLineCommand::close),
            Action::key_final(base_bindings.clone(), Binding::Tab, vec![], CommandLineCommand::complete),
            KeyMap::disable_keys_shortcut("<Control>semicolon|<Control>period"),
        ];

        let controller = ShortcutController::new();
        for binding in bindings {
            controller.add_shortcut(binding);
        }

        KeyMap {
            controller,
        }

    }

    pub fn buffer_controller() -> KeyMap {
        let base_bindings: Arc<Mutex<Vec<Binding>>> = Arc::new(Mutex::new(Vec::new()));
        let bindings: Vec<Shortcut> = vec![
            Action::key_base(base_bindings.clone(), Binding::ControlX, vec![]),
            Action::key_final(base_bindings.clone(), Binding::ControlColon, vec![], CommandLineCommand::open),

            Action::key_final(base_bindings.clone(), Binding::ControlN, vec![], BufferCommand::next_line),
            Action::key_final(base_bindings.clone(), Binding::ControlP, vec![], BufferCommand::prev_line),

            Action::key_final(base_bindings.clone(), Binding::ControlA, vec![], BufferCommand::begin_line),
            Action::key_final(base_bindings.clone(), Binding::ControlE, vec![], BufferCommand::end_line),

            Action::key_final(base_bindings.clone(), Binding::ControlF, vec![], BufferCommand::forward_char),
            Action::key_final(base_bindings.clone(), Binding::ControlB, vec![], BufferCommand::backward_char),

            Action::key_final(base_bindings.clone(), Binding::AltF, vec![], BufferCommand::forward_word),
            Action::key_final(base_bindings.clone(), Binding::AltB, vec![], BufferCommand::backward_word),

            Action::key_final(base_bindings.clone(), Binding::ControlV, vec![], BufferCommand::forward_page),
            Action::key_final(base_bindings.clone(), Binding::AltV, vec![], BufferCommand::backward_page),

            Action::key_final(base_bindings.clone(), Binding::AltGreater, vec![], BufferCommand::buffer_end),
            Action::key_final(base_bindings.clone(), Binding::AltLess, vec![], BufferCommand::buffer_begin),
            KeyMap::disable_keys_shortcut("<Control>semicolon|<Control>period|Delete|F7|Home|End|Insert|<Control>c|<Shift>Insert|<Shift><Control>a"),
        ];

        let controller = ShortcutController::new();
        for bind in bindings {
            controller.add_shortcut(bind);
        }

        KeyMap {
            controller,
        }
    }
}
