require "test_helper"

class WidgetsTest < ViewComponent::TestCase
  test "widget component exposes payload, fields and dynamic method readers" do
    comp = Macron::Cms::WidgetComponent.new(
      payload: { "title" => "Widget Title", "score" => 42 },
      fields: [ { "name" => "title", "kind" => "string" }, { "name" => "score", "kind" => "integer" } ]
    )

    assert_equal "Widget Title", comp.title
    assert_equal 42, comp.score
    assert_equal "Widget Title", comp.field_value("title")
    assert_equal({ "title" => "Widget Title", "score" => 42 }, comp.payload)
  end

  test "heading component normalizes level and renders appropriate tag" do
    render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Section 1", "level" => "h1" }))
    assert_selector "h1", text: "Section 1"

    render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Section 3", "level" => "3" }))
    assert_selector "h3", text: "Section 3"

    render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Default Level", "level" => "" }))
    assert_selector "h2", text: "Default Level"
  end

  test "heading component defaults to text-zinc-900 when color is omitted or blank" do
    render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Default Color Heading", "level" => "h2" }))
    assert_selector "h2.text-zinc-900", text: "Default Color Heading"
    assert_no_selector "h2[style]"

    render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Blank Color Heading", "level" => "h2", "color" => "" }))
    assert_selector "h2.text-zinc-900", text: "Blank Color Heading"
    assert_no_selector "h2[style]"
  end

  test "heading component applies custom inline color and strips text-zinc-900 class" do
    rendered = render_inline(Widgets::HeadingComponent.new(payload: { "title" => "Blue Heading", "level" => "h1", "color" => "#2563eb" }))
    assert_selector "h1[style='color: #2563eb;']", text: "Blue Heading"
    assert_no_selector "h1.text-zinc-900"
    assert_includes rendered.to_html, "text-3xl"
  end

  test "heading component adopts article text_color as fallback and allows widget color override" do
    article = Macron::Cms::Article.create!(title: "Themed Art", text_color: "#10b981")
    heading_type = Macron::Cms::Content.create!(name: "heading", fields: [])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: heading_type)

    # Fallback to article text_color when heading color is blank
    render_inline(Widgets::HeadingComponent.new(article_content: ac, payload: { "title" => "Green Heading", "level" => "h2" }))
    assert_selector "h2[style='color: #10b981;']", text: "Green Heading"
    assert_no_selector "h2.text-zinc-900"

    # Specific heading color overrides article text_color
    render_inline(Widgets::HeadingComponent.new(article_content: ac, payload: { "title" => "Red Heading", "level" => "h2", "color" => "#ef4444" }))
    assert_selector "h2[style='color: #ef4444;']", text: "Red Heading"
    assert_no_selector "h2[style='color: #10b981;']"
    assert_no_selector "h2.text-zinc-900"
  end

  test "paragraph component renders formatted paragraph text" do
    render_inline(Widgets::ParagraphComponent.new(payload: { "content" => "Lorem ipsum dolor sit amet." }))
    assert_selector "p.text-zinc-700", text: "Lorem ipsum dolor sit amet."
    assert_no_selector "p[style]"
  end

  test "paragraph component applies article text_color when set" do
    article = Macron::Cms::Article.create!(title: "Themed Para Art", text_color: "#6366f1")
    para_type = Macron::Cms::Content.create!(name: "paragraph", fields: [])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: para_type)

    render_inline(Widgets::ParagraphComponent.new(article_content: ac, payload: { "content" => "Custom color paragraph." }))
    assert_selector "p[style='color: #6366f1;']", text: "Custom color paragraph."
    assert_no_selector "p.text-zinc-700"
  end

  test "image component renders image tag when file is attached" do
    article = Macron::Cms::Article.create!(title: "Img Article", name: "img-article")
    content = Macron::Cms::Content.create!(name: "image", fields: [ { "name" => "upload", "kind" => "file" } ])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: content)
    file = Rack::Test::UploadedFile.new(StringIO.new("img content"), "image/png", original_filename: "photo.png")
    ac.files.attach(file)

    render_inline(Widgets::ImageComponent.new(article_content: ac, payload: ac.payload))
    assert_selector "figure"
    assert_selector "img[alt='Article image']"
  end

  test "image component does not render when no upload exists" do
    rendered = render_inline(Widgets::ImageComponent.new(payload: {}))
    assert_empty rendered.to_html.strip
  end

  test "embed component renders iframe with srcdoc when html file is attached" do
    article = Macron::Cms::Article.create!(title: "Embed Article", name: "embed-article")
    content = Macron::Cms::Content.create!(name: "embed", fields: [ { "name" => "upload", "kind" => "file" } ])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: content)
    file = Rack::Test::UploadedFile.new(StringIO.new("<h1>Interactive chart</h1>"), "text/html", original_filename: "chart.html")
    ac.files.attach(file)

    rendered = render_inline(Widgets::EmbedComponent.new(article_content: ac, payload: ac.payload))
    assert_selector "iframe[title='Embedded HTML content']"
    assert_selector "iframe[sandbox='allow-scripts allow-same-origin allow-popups']"
    assert_includes rendered.to_html, "<h1>Interactive chart</h1>"
  end

  test "embed component does not render when no upload exists" do
    rendered = render_inline(Widgets::EmbedComponent.new(payload: {}))
    assert_empty rendered.to_html.strip
  end

  test "image component applies responsive sizing classes and defaults to md" do
    article = Macron::Cms::Article.create!(title: "Img Size Article", name: "img-size-article")
    content = Macron::Cms::Content.create!(name: "image", fields: [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: content)
    file = Rack::Test::UploadedFile.new(StringIO.new("img"), "image/png", original_filename: "photo.png")
    ac.files.attach(file)

    # Default (unspecified or nil size) -> w-full sm:w-1/2 mx-auto
    render_inline(Widgets::ImageComponent.new(article_content: ac, payload: {}))
    assert_selector "figure.w-full.sm\\:w-1\\/2.mx-auto"

    # Small size -> w-full sm:w-1/3 mx-auto
    render_inline(Widgets::ImageComponent.new(article_content: ac, payload: { "size" => "sm" }))
    assert_selector "figure.w-full.sm\\:w-1\\/3.mx-auto"

    # Large size -> w-full sm:w-3/4 mx-auto
    render_inline(Widgets::ImageComponent.new(article_content: ac, payload: { "size" => "lg" }))
    assert_selector "figure.w-full.sm\\:w-3\\/4.mx-auto"

    # Full size -> w-full
    render_inline(Widgets::ImageComponent.new(article_content: ac, payload: { "size" => "full" }))
    assert_selector "figure.w-full"
  end

  test "embed component applies responsive sizing classes and defaults to md" do
    article = Macron::Cms::Article.create!(title: "Embed Size Article", name: "embed-size-article")
    content = Macron::Cms::Content.create!(name: "embed", fields: [ { "name" => "upload", "kind" => "file" }, { "name" => "size", "kind" => "dropdown" } ])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: content)
    file = Rack::Test::UploadedFile.new(StringIO.new("<b>chart</b>"), "text/html", original_filename: "chart.html")
    ac.files.attach(file)

    # Default (unspecified size) -> w-full sm:w-1/2 mx-auto
    render_inline(Widgets::EmbedComponent.new(article_content: ac, payload: {}))
    assert_selector "div.w-full.sm\\:w-1\\/2.mx-auto"

    # Small size -> w-full sm:w-1/3 mx-auto
    render_inline(Widgets::EmbedComponent.new(article_content: ac, payload: { "size" => "sm" }))
    assert_selector "div.w-full.sm\\:w-1\\/3.mx-auto"

    # Large size -> w-full sm:w-3/4 mx-auto
    render_inline(Widgets::EmbedComponent.new(article_content: ac, payload: { "size" => "lg" }))
    assert_selector "div.w-full.sm\\:w-3\\/4.mx-auto"

    # Full size -> w-full
    render_inline(Widgets::EmbedComponent.new(article_content: ac, payload: { "size" => "full" }))
    assert_selector "div.w-full"
  end

  test "markdown component renders formatted markdown to html with prose classes" do
    markdown_text = <<~MD
      # Heading 1
      Here is **bold** text and [a link](https://example.com).

      - Item 1
      - Item 2
    MD

    render_inline(Widgets::MarkdownComponent.new(payload: { "content" => markdown_text }))
    assert_selector "div.prose.prose-zinc"
    assert_selector "h1", text: "Heading 1"
    assert_selector "strong", text: "bold"
    assert_selector "a[href='https://example.com']", text: "a link"
    assert_selector "ul li", text: "Item 1"
  end

  test "markdown component sanitizes unsafe html script tags" do
    unsafe_md = "Hello <script>alert('xss')</script> world"
    render_inline(Widgets::MarkdownComponent.new(payload: { "content" => unsafe_md }))
    assert_no_selector "script"
    assert_includes rendered_content, "Hello"
  end

  test "markdown component applies article text_color when set" do
    article = Macron::Cms::Article.create!(title: "Markdown Color Art", text_color: "#7c3aed")
    md_type = Macron::Cms::Content.find_or_create_by!(name: "markdown") { |c| c.fields = [ { "name" => "content", "kind" => "markdown" } ] }
    ac = Macron::Cms::ArticleContent.create!(article: article, content: md_type)

    render_inline(Widgets::MarkdownComponent.new(article_content: ac, payload: { "content" => "# Colored Title\n\n**Bold term** and `code`" }))
    assert_selector "div.prose"
    assert_no_selector "div.prose-zinc"
    assert_includes rendered_content, "color: #7c3aed;"
    assert_includes rendered_content, "--tw-prose-headings: #7c3aed;"
    assert_includes rendered_content, "--tw-prose-bold: #7c3aed;"
    assert_includes rendered_content, "--tw-prose-code: #7c3aed;"
    assert_selector "h1", text: "Colored Title"
    assert_selector "strong", text: "Bold term"
    assert_selector "code", text: "code"
  end

  test "markdown component handles empty or nil content gracefully" do
    render_inline(Widgets::MarkdownComponent.new(payload: { "content" => "" }))
    assert_selector "div.prose.prose-zinc"
    assert_equal "", rendered_content.strip.gsub(/<[^>]*>/, "")
  end

  test "three_js_quote component renders framed card, sr-only quote, and mount attributes with default color" do
    render_inline(Widgets::ThreeJsQuoteComponent.new(payload: { "text" => "Simplicity is prerequisite for reliability." }))

    assert_selector "figure[data-three-js-quote-card].rounded-xl.border.border-zinc-200"
    assert_selector "blockquote.sr-only", text: "Simplicity is prerequisite for reliability."
    assert_selector "div[data-three-js-quote-mount].h-64.sm\\:h-80[data-quote-text='Simplicity is prerequisite for reliability.'][data-quote-color='#18181b'][data-rotation-axis='x'][data-rotation-speed='1'][data-canvas-height='md'][data-font-size='md'][data-font='helvetiker'][data-background-mode='stretch'][data-scanlines-intensity='off'][data-scanlines-density='medium'][data-scanlines-speed='normal']"
    assert_no_selector "div[data-three-js-quote-mount][data-background-color]"
    assert_no_selector "div[data-three-js-quote-mount][data-background-image]"
  end

  test "three_js_quote component renders custom rotation axis, speed, height, scanlines, background color, image URL, and tile mode" do
    render_inline(Widgets::ThreeJsQuoteComponent.new(payload: {
      "text" => "Design is intelligence made visible.",
      "rotation_axis" => "y",
      "rotation_speed" => "2",
      "canvas_height" => "lg",
      "font_size" => "lg",
      "font" => "optimer",
      "background_color" => "#09090b",
      "upload" => "https://example.com/stars.png",
      "background_mode" => "tile",
      "scanlines_intensity" => "strong",
      "scanlines_density" => "fine",
      "scanlines_speed" => "fast"
    }))

    assert_selector "div[data-three-js-quote-mount].h-96.sm\\:h-\\[480px\\][data-rotation-axis='y'][data-rotation-speed='2'][data-canvas-height='lg'][data-font-size='lg'][data-font='optimer'][data-background-color='#09090b'][data-background-image='https://example.com/stars.png'][data-background-mode='tile'][data-scanlines-intensity='strong'][data-scanlines-density='fine'][data-scanlines-speed='fast']"
  end

  test "three_js_quote component resolves ActiveStorage attached background image" do
    article = Macron::Cms::Article.create!(title: "3D Quote with Image")
    content = Macron::Cms::Content.create!(name: "three_js_quote", fields: [
      { "name" => "text", "kind" => "string" },
      { "name" => "upload", "kind" => "file" }
    ])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: content)
    file = Rack::Test::UploadedFile.new(StringIO.new("fake-image"), "image/png", original_filename: "bg.png")
    ac.files.attach(file)

    render_inline(Widgets::ThreeJsQuoteComponent.new(article_content: ac, payload: { "text" => "Starlight", "rotation_axis" => "z" }))
    assert_selector "div[data-three-js-quote-mount][data-rotation-axis='z']"
    assert_selector "div[data-three-js-quote-mount][data-background-image*='bg.png']"
  end

  test "three_js_quote component adopts article text_color as fallback and allows widget color override" do
    article = Macron::Cms::Article.create!(title: "3D Quote Art", text_color: "#0ea5e9")
    quote_type = Macron::Cms::Content.find_or_create_by!(name: "three_js_quote") do |c|
      c.fields = [ { "name" => "text", "kind" => "string" }, { "name" => "color", "kind" => "color" } ]
    end
    ac = Macron::Cms::ArticleContent.create!(article: article, content: quote_type)

    render_inline(Widgets::ThreeJsQuoteComponent.new(article_content: ac, payload: { "text" => "Stay curious", "color" => "" }))
    assert_selector "div[data-three-js-quote-mount][data-quote-color='#0ea5e9']"

    render_inline(Widgets::ThreeJsQuoteComponent.new(article_content: ac, payload: { "text" => "Stay curious", "color" => "#e11d48" }))
    assert_selector "div[data-three-js-quote-mount][data-quote-color='#e11d48']"
  end

  test "three_js_quote component does not render when text is blank" do
    rendered = render_inline(Widgets::ThreeJsQuoteComponent.new(payload: { "text" => "   " }))
    assert_empty rendered.to_html.strip

    rendered_nil = render_inline(Widgets::ThreeJsQuoteComponent.new(payload: {}))
    assert_empty rendered_nil.to_html.strip
  end

  test "latex component renders container with data-cms-latex and fallback formula" do
    formula = "\\int_{-\\infty}^{\\infty} e^{-x^2} dx = \\sqrt{\\pi}"
    rendered = render_inline(Widgets::LatexComponent.new(payload: { "content" => formula }))

    assert_selector "div.cms-latex-widget[data-cms-latex][data-cms-latex-display='true']"
    assert_includes rendered.to_html, %(data-cms-latex="#{formula}")
    assert_includes rendered_content, formula
  end

  test "latex component applies article text_color when present" do
    article = Macron::Cms::Article.create!(title: "Math Art", text_color: "#6366f1")
    latex_type = Macron::Cms::Content.find_or_create_by!(name: "latex") do |c|
      c.fields = [ { "name" => "content", "kind" => "latex" } ]
    end
    ac = Macron::Cms::ArticleContent.create!(article: article, content: latex_type)

    render_inline(Widgets::LatexComponent.new(article_content: ac, payload: { "content" => "E = mc^2" }))
    assert_selector "div.cms-latex-widget[style='color: #6366f1;']"
  end

  test "latex component does not render when formula is blank" do
    rendered = render_inline(Widgets::LatexComponent.new(payload: { "content" => "" }))
    assert_empty rendered.to_html.strip

    rendered_nil = render_inline(Widgets::LatexComponent.new(payload: {}))
    assert_empty rendered_nil.to_html.strip
  end

  test "blockquote component renders markdown formatted html inside blockquote" do
    markdown_text = <<~MD
      "Simplicity is the soul of efficiency."

      -- **Austin Freeman** with a [link](https://example.com)
    MD

    render_inline(Widgets::BlockquoteComponent.new(payload: { "content" => markdown_text }))
    assert_selector "blockquote.border-l-4.pl-4.italic.my-6"
    assert_selector "strong", text: "Austin Freeman"
    assert_selector "a[href='https://example.com']", text: "link"
  end

  test "blockquote component sanitizes unsafe html script tags" do
    unsafe_md = "Quote with <script>alert('xss')</script> in it"
    render_inline(Widgets::BlockquoteComponent.new(payload: { "content" => unsafe_md }))
    assert_no_selector "script"
    assert_includes rendered_content, "Quote with"
  end

  test "blockquote component applies article text_color to inline style and border" do
    article = Macron::Cms::Article.create!(title: "Quote Color Article", text_color: "#2563eb")
    bq_type = Macron::Cms::Content.find_or_create_by!(name: "blockquote") { |c| c.fields = [ { "name" => "content", "kind" => "markdown" } ] }
    ac = Macron::Cms::ArticleContent.create!(article: article, content: bq_type)

    render_inline(Widgets::BlockquoteComponent.new(article_content: ac, payload: { "content" => "**Bold quote**" }))
    assert_selector "blockquote.border-l-4"
    assert_no_selector "blockquote.border-zinc-300"
    assert_includes rendered_content, "color: #2563eb;"
    assert_includes rendered_content, "border-color: #2563eb;"
    assert_selector "strong", text: "Bold quote"
  end

  test "blockquote component handles empty or nil content gracefully" do
    render_inline(Widgets::BlockquoteComponent.new(payload: { "content" => "" }))
    assert_selector "blockquote.border-l-4.border-zinc-300.text-zinc-800"
    assert_equal "", rendered_content.strip.gsub(/<[^>]*>/, "")

    render_inline(Widgets::BlockquoteComponent.new(payload: {}))
    assert_selector "blockquote.border-l-4.border-zinc-300.text-zinc-800"
  end

  test "three_js_image component does not render when upload is blank" do
    rendered = render_inline(Widgets::ThreeJsImageComponent.new(payload: { "upload" => "" }))
    assert_empty rendered.to_html.strip

    rendered_nil = render_inline(Widgets::ThreeJsImageComponent.new(payload: {}))
    assert_empty rendered_nil.to_html.strip
  end

  test "three_js_image component renders mount container with default options and placeholder" do
    render_inline(Widgets::ThreeJsImageComponent.new(payload: { "upload" => "https://example.com/photo.jpg" }))

    assert_selector "figure[data-three-js-image-card].w-full.sm\\:w-1\\/2.mx-auto"
    assert_selector "div[data-three-js-image-mount].h-64.sm\\:h-80[data-image-url='https://example.com/photo.jpg'][data-effect='ripple'][data-animation-speed='normal'][data-intensity='medium'][data-canvas-height='md'][data-fit-mode='cover']"
    assert_selector "div[data-three-js-image-placeholder]"
    assert_selector "svg.animate-spin"
  end

  test "three_js_image component renders custom effect, speed, intensity, canvas height, size, and fit mode" do
    render_inline(Widgets::ThreeJsImageComponent.new(payload: {
      "upload" => "https://example.com/wave.jpg",
      "size" => "lg",
      "effect" => "wave",
      "animation_speed" => "fast",
      "intensity" => "strong",
      "canvas_height" => "xl",
      "fit_mode" => "contain"
    }))

    assert_selector "figure[data-three-js-image-card].w-full.sm\\:w-3\\/4.mx-auto"
    assert_selector "div[data-three-js-image-mount].h-\\[540px\\].sm\\:h-\\[640px\\][data-effect='wave'][data-animation-speed='fast'][data-intensity='strong'][data-canvas-height='xl'][data-fit-mode='contain']"
  end

  test "three_js_image component resolves ActiveStorage attached image" do
    article = Macron::Cms::Article.create!(title: "Shader FX Article")
    content = Macron::Cms::Content.create!(name: "three_js_image", fields: [
      { "name" => "upload", "kind" => "file" }
    ])
    ac = Macron::Cms::ArticleContent.create!(article: article, content: content)
    file = Rack::Test::UploadedFile.new(StringIO.new("fake-image-bytes"), "image/jpeg", original_filename: "nature.jpg")
    ac.files.attach(file)

    render_inline(Widgets::ThreeJsImageComponent.new(article_content: ac, payload: { "effect" => "glitch" }))
    assert_selector "div[data-three-js-image-mount][data-effect='glitch']"
    assert_selector "div[data-three-js-image-mount][data-image-url*='nature.jpg']"
  end
end
