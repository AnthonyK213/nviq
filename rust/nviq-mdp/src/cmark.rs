use crate::code::SyntaxHighlighter;

pub struct CmarkRenderer {
    pub syntax_highlighter: SyntaxHighlighter,
}

impl CmarkRenderer {
    pub fn new() -> Self {
        Self {
            syntax_highlighter: SyntaxHighlighter::new(),
        }
    }

    pub fn render(&mut self, markdown: &str) -> String {
        let mut options = pulldown_cmark::Options::empty();
        options.insert(pulldown_cmark::Options::ENABLE_FOOTNOTES);
        // options.insert(pulldown_cmark::Options::ENABLE_MATH);
        options.insert(pulldown_cmark::Options::ENABLE_TABLES);
        options.insert(pulldown_cmark::Options::ENABLE_TASKLISTS);

        let parser = pulldown_cmark::Parser::new_ext(markdown, options);
        let iterator = pulldown_cmark::TextMergeStream::new(parser)
            .flat_map(|event| self.syntax_highlighter.process_event(event));

        let mut html_output = String::new();
        pulldown_cmark::html::push_html(&mut html_output, iterator);

        html_output
    }
}
