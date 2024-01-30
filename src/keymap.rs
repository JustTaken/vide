use crate::action::Action;
use crate::window::{TextWindow, StatusLine};
use std::{
    sync::{Arc, Mutex},
};

use gtk::{
    Shortcut,
    ShortcutController,
    ShortcutTrigger,
    CallbackAction,
};

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
            Action::key_final(None, Bind::ControlP, vec![], StatusLine::prev_completion),
            Action::key_final(None, Bind::ControlN, vec![], StatusLine::next_completion),
            Action::key_final(None, Bind::ControlG, vec![], StatusLine::close_completion),
            Action::key_final(None, Bind::Esc, vec![], StatusLine::close),
            Action::key_final(None, Bind::Tab, vec![], StatusLine::complete),

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
            Action::key_final(Some(base_bindings.clone()), Bind::ControlColon, vec![], StatusLine::open),

            Action::key_final(Some(base_bindings.clone()), Bind::ControlN, vec![], TextWindow::next_line),
            Action::key_final(Some(base_bindings.clone()), Bind::ControlP, vec![], TextWindow::prev_line),

            Action::key_final(Some(base_bindings.clone()), Bind::ControlA, vec![], TextWindow::begin_line),
            Action::key_final(Some(base_bindings.clone()), Bind::ControlE, vec![], TextWindow::end_line),

            Action::key_final(Some(base_bindings.clone()), Bind::ControlF, vec![], TextWindow::forward_char),
            Action::key_final(Some(base_bindings.clone()), Bind::ControlB, vec![], TextWindow::backward_char),

            Action::key_final(Some(base_bindings.clone()), Bind::AltF, vec![], TextWindow::forward_word),
            Action::key_final(Some(base_bindings.clone()), Bind::AltB, vec![], TextWindow::backward_word),

            Action::key_final(Some(base_bindings.clone()), Bind::ControlV, vec![], TextWindow::forward_page),
            Action::key_final(Some(base_bindings.clone()), Bind::AltV, vec![], TextWindow::backward_page),

            Action::key_final(Some(base_bindings.clone()), Bind::AltGreater, vec![], TextWindow::buffer_end),
            Action::key_final(Some(base_bindings.clone()), Bind::AltLess, vec![], TextWindow::buffer_begin),

            KeyMap::disable_keys_shortcut("<Control>semicolon|<Control>period|Delete|F7|Home|End|Insert|<Control>c|<Shift>Insert|<Shift><Control>a"),
        ];

        let controller = ShortcutController::new();
        bindings.into_iter().for_each(|b| controller.add_shortcut(b));

        KeyMap {
            controller,
        }
    }
}
