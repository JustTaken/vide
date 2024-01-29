use crate::action::Function;
use crate::action::Binding;
use crate::action::Action;

use std::{
    sync::{Arc, Mutex},
};

use gtk::{
    prelude::*,
    Shortcut,
    ShortcutController,
    ShortcutTrigger,
    CallbackAction,
    Text,
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
        let cancel_trigger = ShortcutTrigger::parse_string("Escape").unwrap();
        let completion_trigger = ShortcutTrigger::parse_string("Tab").unwrap();
        let next_completion_trigger = ShortcutTrigger::parse_string("<Control>n").unwrap();
        let prev_completion_trigger = ShortcutTrigger::parse_string("<Control>p").unwrap();
        let cancel_completion_trigger = ShortcutTrigger::parse_string("<Control>g").unwrap();
        let cancel_action = CallbackAction::new(|widget, _| {
            let text = widget.downcast_ref::<Text>().unwrap();
            text.buffer().delete_text(0, None);
            text.emit_move_focus(gtk::DirectionType::TabBackward);

            if let Err(_) = widget.activate_action("win.to_completion_list", Some(&"close".to_variant())) {
                println!("Error: Could not close completion list");
            }

            true
        });

        let cancel_completion_action = CallbackAction::new(|widget, _| {
            if let Err(_) = widget.activate_action("win.to_completion_list", Some(&"close".to_variant())) {
                println!("Error: Could not close completion list");
            }

            true
        });

        let prev_completion_action = CallbackAction::new(|widget, _| {
            let text = widget.downcast_ref::<Text>().unwrap();
            let content = text.buffer().text();

            if let Err(_) = widget.activate_action("win.to_completion_list", Some(&format!("prev {}", content).to_variant())) {
                println!("Error: Could not get next completion element");
            }

            true
        });

        let next_completion_action = CallbackAction::new(|widget, _| {
            let text = widget.downcast_ref::<Text>().unwrap();
            let content = text.buffer().text();

            if let Err(_) = widget.activate_action("win.to_completion_list", Some(&format!("next {}", content).to_variant())) {
                println!("Error: Could not get next completion element");
            }

            true
        });

        let completion_action = CallbackAction::new(|widget, _| {
            let text = widget.downcast_ref::<Text>().unwrap();
            let content = text.buffer().text();

            if let Err(_) = widget.activate_action("win.to_completion_list", Some(&format!("complete {}", content).to_variant())) {
                println!("Could not query completion")
            }
            true
        });

        let escape = Shortcut::builder().trigger(&cancel_trigger).action(&cancel_action).build();
        let complete = Shortcut::builder().trigger(&completion_trigger).action(&completion_action).build();
        let cancel_completion = Shortcut::builder().trigger(&cancel_completion_trigger).action(&cancel_completion_action).build();
        let next_completion = Shortcut::builder().trigger(&next_completion_trigger).action(&next_completion_action).build();
        let prev_completion = Shortcut::builder().trigger(&prev_completion_trigger).action(&prev_completion_action).build();

        let controller = ShortcutController::new();
        controller.add_shortcut(escape);
        controller.add_shortcut(complete);
        controller.add_shortcut(cancel_completion);
        controller.add_shortcut(next_completion);
        controller.add_shortcut(prev_completion);
        controller.add_shortcut(KeyMap::disable_keys_shortcut("<Control>semicolon|<Control>period"));

        KeyMap {
            controller,
        }

    }

    pub fn buffer_controller() -> KeyMap {
        let base_bindings: Arc<Mutex<Vec<Binding>>> = Arc::new(Mutex::new(Vec::new()));
        let bindings: Vec<Shortcut> = vec![
            Action::key_base(base_bindings.clone(), Binding::ControlX, vec![]),
            Action::key_final(base_bindings.clone(), Binding::ControlColon, vec![], Function::open_command),

            Action::key_final(base_bindings.clone(), Binding::ControlN, vec![], Function::next_line),
            Action::key_final(base_bindings.clone(), Binding::ControlP, vec![], Function::prev_line),

            Action::key_final(base_bindings.clone(), Binding::ControlA, vec![], Function::begin_line),
            Action::key_final(base_bindings.clone(), Binding::ControlE, vec![], Function::end_line),

            Action::key_final(base_bindings.clone(), Binding::ControlF, vec![], Function::forward_char),
            Action::key_final(base_bindings.clone(), Binding::ControlB, vec![], Function::backward_char),

            Action::key_final(base_bindings.clone(), Binding::AltF, vec![], Function::forward_word),
            Action::key_final(base_bindings.clone(), Binding::AltB, vec![], Function::backward_word),

            Action::key_final(base_bindings.clone(), Binding::ControlV, vec![], Function::forward_page),
            Action::key_final(base_bindings.clone(), Binding::AltV, vec![], Function::backward_page),

            Action::key_final(base_bindings.clone(), Binding::AltGreater, vec![], Function::buffer_end),
            Action::key_final(base_bindings.clone(), Binding::AltLess, vec![], Function::buffer_begin),
        ];

        let controller = ShortcutController::new();
        controller.add_shortcut(KeyMap::disable_keys_shortcut(
            "<Control>semicolon|<Control>period|Delete|F7|Home|End|Insert|<Control>c|<Shift>Insert|<Shift><Control>a")
        );
        for bind in bindings {
            controller.add_shortcut(bind);
        }

        KeyMap {
            controller,
        }
    }
}
