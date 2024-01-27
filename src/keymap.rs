use crate::action::Function;
use crate::action::Binding;

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
    pub fn buffer_controller() -> KeyMap {
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
