use pulldown_cmark::{CodeBlockKind, Event, Tag, TagEnd};

enum BlockKind {
    Code,
    Mermaid,
}

pub struct CodeBlockHandler {
    block_kind: BlockKind,
}

unsafe impl Send for CodeBlockHandler {}

unsafe impl Sync for CodeBlockHandler {}

impl CodeBlockHandler {
    pub fn new() -> Self {
        Self {
            block_kind: BlockKind::Code,
        }
    }

    fn reset(&mut self) {
        self.block_kind = BlockKind::Code;
    }

    pub fn process_event<'e>(&mut self, event: Event<'e>) -> Vec<Event<'e>> {
        match &event {
            Event::Start(Tag::CodeBlock(kind)) => match kind {
                CodeBlockKind::Fenced(lang) => {
                    if lang.as_ref() == "mermaid" {
                        self.block_kind = BlockKind::Mermaid;
                        vec![Event::Html("<pre class=\"mermaid\">".into())]
                    } else {
                        vec![event]
                    }
                }
                CodeBlockKind::Indented => vec![event],
            },
            Event::Text(_) => {
                vec![event]
            }
            Event::End(TagEnd::CodeBlock) => match self.block_kind {
                BlockKind::Code => vec![event],
                BlockKind::Mermaid => {
                    self.reset();
                    vec![Event::Html("</pre>".into())]
                }
            },
            _ => vec![event],
        }
    }
}
