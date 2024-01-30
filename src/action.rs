use crate::keymap::Bind;
use std::{
    sync::{Arc, Mutex},
    borrow::Cow,
};

use gtk::{
    prelude::*,
    Widget,
    Shortcut,
    ShortcutTrigger,
    CallbackAction,
    gio::{ActionEntry, SimpleAction},
    glib::{VariantTy, variant::Variant},
};

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
