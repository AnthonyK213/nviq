use pulldown_cmark::{CodeBlockKind, Event, Tag, TagEnd};
use syntect::{
    highlighting::{Theme, ThemeSet},
    parsing::{SyntaxReference, SyntaxSet},
};

pub struct SyntaxHighlighter {
    syntax_set: SyntaxSet,
    in_code_block: bool,
    code_buffer: String,
    syntax: *const SyntaxReference,
    theme: Theme,
}

unsafe impl Send for SyntaxHighlighter {}

unsafe impl Sync for SyntaxHighlighter {}

impl SyntaxHighlighter {
    pub fn new() -> Self {
        let syntax_set = SyntaxSet::load_defaults_newlines();
        let theme_set = ThemeSet::load_defaults();

        let theme = theme_set.themes.get("base16-ocean.dark").unwrap().clone();
        let code_buffer = String::new();

        Self {
            syntax_set,
            in_code_block: false,
            code_buffer,
            syntax: std::ptr::null(),
            theme,
        }
    }

    fn reset(&mut self) {
        self.in_code_block = false;
        self.code_buffer.clear();
        self.syntax = std::ptr::null();
    }

    pub fn process_event<'e>(&mut self, event: Event<'e>) -> Vec<Event<'e>> {
        match &event {
            Event::Start(Tag::CodeBlock(kind)) => match kind {
                CodeBlockKind::Fenced(lang) => {
                    if lang.as_ref() == "mermaid" {
                        vec![Event::Html("<pre class=\"mermaid\">".into())]
                    } else {
                        if let Some(syntax) = self
                            .syntax_set
                            .find_syntax_by_token(&lang)
                            .or_else(|| self.syntax_set.find_syntax_by_token("txt"))
                        {
                            self.in_code_block = true;
                            self.syntax = syntax;
                        }
                        vec![Event::Html("<div class=\"code-container\">".into()), event]
                    }
                }
                CodeBlockKind::Indented => vec![event],
            },
            Event::Text(text) => {
                if self.in_code_block {
                    self.code_buffer.push_str(&text);
                    vec![]
                } else {
                    vec![event]
                }
            }
            Event::End(TagEnd::CodeBlock) => {
                if self.in_code_block && !self.syntax.is_null() {
                    unsafe {
                        match syntect::html::highlighted_html_for_string(
                            &self.code_buffer,
                            &self.syntax_set,
                            &*self.syntax,
                            &self.theme,
                        ) {
                            Ok(code_html) => {
                                self.reset();
                                vec![
                                    Event::Html(code_html.into()),
                                    event,
                                    Event::Html("</div>".into()),
                                ]
                            }
                            Err(e) => {
                                self.reset();
                                vec![
                                    Event::Html(e.to_string().into()),
                                    event,
                                    Event::Html("</div>".into()),
                                ]
                            }
                        }
                    }
                } else {
                    self.reset();
                    vec![Event::Html("</pre>".into())]
                }
            }
            _ => vec![event],
        }
    }
}
