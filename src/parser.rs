use tree_sitter::{
    Parser,
    Language,
    TreeCursor,
    Tree,
    Point,
    InputEdit
};

use std::time::{
    Instant,
    Duration
};

use std::sync::{
    Mutex,
    Arc
};

use gtk::{
    prelude::*,
    TextTag,
    TextTagTable,
    TextBuffer,
};

extern "C" { fn tree_sitter_rust() -> Language; }

#[derive(Clone)]
pub enum Lang {
    Rust,
}

impl Lang {
    pub fn from_extension(file_name: &str) -> Option<Lang> {
        let ext = file_name.split('.').collect::<Vec<&str>>().pop();

        let extension = ext.unwrap_or("");
        match extension {
            "rs" => Some(Lang::Rust),
            _ => None,
        }
    }
}

pub enum Highlight {
    //Punctuation,
    Keyword,
    Field,
    Type,
    Identifier,
    String,
    Default,
}

impl Highlight {
    fn color_name(&self) -> &'static str {
        match self {
            Highlight::Keyword => "red",
            Highlight::Field => "green",
            Highlight::Type => "blue",
            Highlight::Identifier => "yellow",
            Highlight::String => "black",
            Highlight::Default => "white",
        }
    }

    fn from_id(id: u16) -> Option<Highlight> {
        match id {
            1 => Some(Highlight::Identifier),
            75 | 77 | 96 | 67 | 79 => Some(Highlight::Keyword),
            325 => Some(Highlight::Field),
            30 | 328 => Some(Highlight::Type),
            127 => Some(Highlight::String),
            // 2 | 55 | 7 | 5 | 4 | 58 | 53 | 56 | 102 | 54 | 51 => Some(Highlight::Ponctuation),
            _ => None,
        }
    }

    pub fn get_colored_buffer(content: &str, _: Lang) -> TextBuffer {
        let text_tag_table = TextTagTable::new();
        [   TextTag::builder().foreground("yellow").name("yellow").build(),
            TextTag::builder().foreground("red").name("red").build(),
            TextTag::builder().foreground("green").name("green").build(),
            TextTag::builder().foreground("blue").name("blue").build(),
            TextTag::builder().foreground("black").name("black").build(),
            TextTag::builder().foreground("white").name("white").build(),
        ].iter().for_each(|t| { text_tag_table.add(t); });

        let language = unsafe { tree_sitter_rust() };
        let mut parser = Arc::new(Mutex::new(Parser::new()));
        parser.lock().unwrap().set_language(language).unwrap();

        let text_buffer = TextBuffer::builder().tag_table(&text_tag_table).text(content).build();
        let tree = Arc::new(Mutex::new(parser.lock().unwrap().parse(content, None).unwrap()));

        if let Ok(tree) = tree.lock() {
            let mut cursor = tree.walk();
            Highlight::get_child(&mut cursor, &text_buffer);
        }

        let tree_clone = tree.clone();
        let parser_clone = parser.clone();
        text_buffer.connect_insert_text(move |buffer, iter, text| {
            let text_len = text.len();
            let offset = iter.offset() as usize;
            if let Ok(mut tree) = tree_clone.lock() {
                let mut node = tree.root_node().descendant_for_byte_range(offset, offset).unwrap();

                let mut content = buffer.text(&buffer.start_iter(), &buffer.end_iter(), false).as_str().to_owned();
                content.replace_range(offset..offset, text);
                let new_buffer = TextBuffer::builder().text(&content[..]).build();
                let start_iter = buffer.iter_at_offset(node.start_byte() as i32);
                let old_end_iter = buffer.iter_at_offset(node.end_byte() as i32);
                let end_iter = new_buffer.iter_at_offset((node.end_byte() + text_len) as i32);

                let edit = InputEdit {
                    start_byte: node.start_byte(),
                    old_end_byte: node.end_byte(),
                    new_end_byte: old_end_iter.offset() as usize + text_len,
                    start_position: Point::new(start_iter.line() as usize, start_iter.line_offset() as usize),
                    old_end_position: Point::new(old_end_iter.line() as usize, old_end_iter.line_offset() as usize),
                    new_end_position: Point::new(end_iter.line() as usize, end_iter.line_offset() as usize),
                };

                tree.edit(&edit);

                *tree = parser_clone.lock().unwrap().parse(content, Some(&tree)).unwrap();
            }
        });

        let tree_clone = tree.clone();
        text_buffer.connect_delete_range(move |buffer, start, end| {
            if let Ok(mut tree) = tree_clone.lock() {
                let offset = start.offset() as usize;
                let final_offset = end.offset() as usize;
                let mut node = tree.root_node().descendant_for_byte_range(offset, offset).unwrap();
                let mut node = node.parent().unwrap();

                let mut content = buffer.text(&buffer.start_iter(), &buffer.end_iter(), false).as_str().to_owned();
                content.replace_range(offset..final_offset, "");
                let new_buffer = TextBuffer::builder().text(&content[..]).build();
                let start_iter = buffer.iter_at_offset(node.start_byte() as i32);
                let old_end_iter = buffer.iter_at_offset(node.end_byte() as i32);
                let end_iter = new_buffer.iter_at_offset((node.end_byte() - (final_offset - offset)) as i32);

                let edit = InputEdit {
                    start_byte: node.start_byte(),
                    old_end_byte: node.end_byte(),
                    new_end_byte: old_end_iter.offset() as usize,
                    start_position: Point::new(start_iter.line() as usize, start_iter.line_offset() as usize),
                    old_end_position: Point::new(old_end_iter.line() as usize, old_end_iter.line_offset() as usize),
                    new_end_position: Point::new(end_iter.line() as usize, end_iter.line_offset() as usize),
                };

                tree.edit(&edit);

                *tree = parser.lock().unwrap().parse(content, Some(&tree)).unwrap();
            }
        });

        text_buffer.connect_changed(move |buffer| {
            if let Ok(tree) = tree.lock() {
                let offset = buffer.cursor_position() as usize;
                let mut node = tree.root_node().descendant_for_byte_range(offset, offset).unwrap();
                let mut cursor = node.walk();
                Highlight::get_child(&mut cursor, buffer);
            }
        });


        text_buffer
    }

    fn get_child(child: &mut TreeCursor, text_buffer: &TextBuffer) {
        if child.goto_first_child() {
            Highlight::get_child(child, text_buffer);
        } else {
            let node = child.node();
            let range = node.range();
            let start = text_buffer.iter_at_line_index(range.start_point.row as i32, range.start_point.column as i32).unwrap();
            let end = text_buffer.iter_at_line_index(range.end_point.row as i32, range.end_point.column as i32).unwrap();
            text_buffer.remove_all_tags(&start, &end);

            if let Some(typ) = Highlight::from_id(node.kind_id()) {
                if let Highlight::String = typ {
                    child.goto_next_sibling();
                    let range = child.node().range();
                    let end = text_buffer.iter_at_line_index(range.end_point.row as i32, range.end_point.column as i32).unwrap();
                    text_buffer.apply_tag_by_name(typ.color_name(), &start, &end);
                } else {
                    text_buffer.apply_tag_by_name(typ.color_name(), &start, &end);
                }
            }

            if child.goto_next_sibling() {
                Highlight::get_child(child, text_buffer);
            } else {
                child.goto_parent();
                Highlight::get_parent_sibling(child, text_buffer);
            }
        }
    }

    fn get_parent_sibling(sibling: &mut TreeCursor, text_buffer: &TextBuffer) {
        if sibling.goto_next_sibling() {
            Highlight::get_child(sibling, text_buffer);
        } else if sibling.goto_parent() {
            Highlight::get_parent_sibling(sibling, text_buffer);
        }
    }
}
