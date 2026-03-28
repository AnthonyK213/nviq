use crate::code::CodeBlockHandler;

pub struct CmarkRenderer {
    code_block_handler: CodeBlockHandler,
    html_cleaner: ammonia::Builder<'static>,
}

impl CmarkRenderer {
    pub fn new() -> Self {
        let mut html_cleaner = ammonia::Builder::default();
        html_cleaner
            .add_tag_attributes("code", &["class"])
            .add_tag_attributes("pre", &["class"])
            .add_tags(&["span", "div"])
            .add_tag_attributes("span", &["class"])
            .add_tag_attributes("div", &["class"]);

        Self {
            code_block_handler: CodeBlockHandler::new(),
            html_cleaner,
        }
    }

    pub fn render(&mut self, markdown: &str) -> String {
        let mut options = pulldown_cmark::Options::empty();
        options.insert(pulldown_cmark::Options::ENABLE_FOOTNOTES);
        options.insert(pulldown_cmark::Options::ENABLE_MATH);
        options.insert(pulldown_cmark::Options::ENABLE_TABLES);
        options.insert(pulldown_cmark::Options::ENABLE_TASKLISTS);

        let parser = pulldown_cmark::Parser::new_ext(markdown, options);
        let iterator = pulldown_cmark::TextMergeStream::new(parser)
            .flat_map(|event| self.code_block_handler.process_event(event));

        let mut html_output = String::new();
        pulldown_cmark::html::push_html(&mut html_output, iterator);

        self.html_cleaner.clean(&html_output).to_string()
    }
}
