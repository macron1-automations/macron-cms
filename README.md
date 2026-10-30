# MacronCMS

[![Gem Version](https://img.shields.io/badge/version-4.0.0-emerald.svg)](#version)
[![Rails 8+](https://img.shields.io/badge/rails-8%2B-red.svg)](https://rubyonrails.org)
[![React](https://img.shields.io/badge/React-20232A?logo=react&logoColor=61DAFB)](https://react.dev)
[![Three.js](https://img.shields.io/badge/Three.js-black?logo=three.js&logoColor=white)](https://threejs.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](MIT-LICENSE)

A simple, flexible CMS engine for Ruby on Rails, designed for building highly interactive content with dynamic content blocks, declarative schemas, and ViewComponent widgets.

---

## Overview

**MacronCMS** brings simplicity and developer joy back to content management, without sacrificing the power needed to create dynamic digital experiences. Built natively for Ruby on Rails 8, it gives developers total freedom to define content structures with Rails models while effortlessly powering modern front-end presentations.

---

## Features

### 🛠️ Dedicated Admin Dashboard (`/cms`)
- **Modern Zinc Aesthetic**: Clean, responsive monochrome layout with sticky sidebar navigation, top breadcrumbs, metric cards, quick-action buttons, and flash notification banners.
- **Article CRUD & Canonical Slugs**: Manage articles (`Macron::Cms::Article`) out-of-the-box with dedicated create, edit, show, and delete interfaces. Automatic slug generation via `friendly_id` produces clean SEO URLs.
- **Slug History & Canonical 301 Redirects**: Automatic FriendlyId slug history tracking. Host controllers use the `Macron::Cms::SlugRedirectable` concern to automatically issue permanent 301 redirects when an article is accessed via a previous slug, maintaining SEO equity and preventing 404s.
- **Deletion Safeguards**: Browser confirmation dialogs on delete actions with article titles to prevent accidental deletion.
- **Host App Integration**: Quick links between the CMS admin console and public-facing host views.

### 🧱 Dynamic Article Content Blocks & In-Place Inserters
- **Multiple Blocks Per Article**: Associate an arbitrary series of content blocks with an article (`Macron::Cms::ArticleContent`). Add multiple blocks of the same content type (e.g. headings, markdown blocks, images) with distinct values.
- **In-Place Block Inserters**: Add new blocks directly above, between, or below existing blocks on the Article management screen with one click.
- **Declarative In-Place Block Conversion**: Convert blocks between compatible content types directly in-place (e.g. `image` <-> `three_js_image`) via the `convertible_to` schema definition. Conversions update records in place without duplicating Active Storage file attachments, and preserve existing and dormant JSONB `payload` attributes non-destructively.
- **Inline Turbo Stream Updates**: Add, edit, and reorder content blocks with instantaneous Turbo Stream updates—no full-page reloads.
- **Dynamic Field Generation**: Field controls are generated dynamically based on the content type schema and validated before saving into the block's `payload` JSONB column.
- **8 Extensible Field Kinds**:
  - `string`: Single-line text input.
  - `text`: Multiline text area.
  - `dropdown`: Select menu configured with custom option lists from the schema YAML.
  - `color`: Interactive color picker with hex value support.
  - `markdown`: CodeMirror-backed markdown editor with formatted preview on the article show page.
  - `file`: Direct file attachment powered by Active Storage.
  - `json`: Dedicated JSON data editor.
  - `latex`: CodeMirror LaTeX editor with `stex` syntax mode and KaTeX mathematical equation preview.
- **File Attachment Purging**: Remove or replace existing Active Storage attachments directly from the block editor with a dedicated purge checkbox, keeping payloads clean without recreating blocks.

### 🖼️ Automatic Featured Image Bubbling
- **Declarative Tagging**: Tag image-bearing content types with `featured_image: true` in their YAML schemas (`config/content_types/*.yml`).
- **Write-Time Image Bubbling**: Active Storage image attachments on eligible blocks automatically bubble up to `article.featured_image_blob` upon saving or deleting blocks, pointing to the first attached image in block sort order.
- **Zero-Join Editorial Streams**: Eager-load and render article feeds or homepage streams (`@articles = Macron::Cms::Article.includes(:featured_image_blob)`) and access `article.featured_image` without expensive multi-table joins across heterogeneous content blocks.

### 🎨 Article Background & Typography Customization
- **Custom Background Colors & Images**: Configure an optional background color or attach a background image directly to any article via Active Storage, with live image previews and one-click purge.
- **CSS Background Display Controls**: Fine-tune background display settings per article:
  - **Size**: `cover`, `contain`, `auto`
  - **Repeat**: `no-repeat`, `repeat`, `repeat-x`, `repeat-y`
  - **Position**: `center`, `top`, `bottom`, `left`, `right`
  - **Attachment**: `scroll`, `fixed`
- **Article-Wide Text Color Propagation**: Set a custom text color at the article level that automatically propagates to the host view's `<body>` and header, as well as to child `WidgetComponent` instances (headings, paragraphs, and markdown prose).
- **Public Style Helper**: Use `cms_article_background_style(@article)` to generate clean inline CSS applied directly to the host application's `<body>` tag.

### 📝 CodeMirror Markdown, LaTeX & Rich Media
- **CodeMirror Markdown & LaTeX Editors**: Integrated CodeMirror editors in the CMS admin for writing Markdown content and raw LaTeX expressions with syntax highlighting (`stex` mode).
- **Fast KaTeX Math Rendering**: Embedded KaTeX engine renders complex LaTeX equations, mathematical notation, and symbols instantaneously in both admin previews and front-end layouts.
- **Formatted Markdown Previews**: Formatted GitHub Flavored Markdown (GFM) previews rendered directly on the article management page.
- **Sandboxed Embeds with Configurable Heights**: Render third-party media and raw HTML snippets safely inside isolated `<iframe>` elements using `srcdoc` to prevent Active Storage download blocks and script collisions. Configure display heights (`sm`: 240px, `md`: 320px, `lg`: 480px, `xl`: 640px, `2xl`: 800px) alongside responsive widths (`25%` to `100%`).
- **Native Fullscreen Maximize**: Embed containers feature a floating toggle button powered by the HTML5 Fullscreen API (`widgets/embed.js`), allowing users to expand embedded presentations, charts, or maps to full screen.
- **Responsive Media Controls**: Configure image and embed widgets with responsive width options (`25%`, `33%`, `50%`, `66%`, `75%`, `100%`) and alignment (`left`, `center`, `right`).

### ↕️ Drag-and-Drop, Compact View & Batch Reordering
- **HTML5 Drag-and-Drop**: Easily re-arrange article content blocks on the Article show page with immediate position updates and asynchronous persistence.
- **Accessible Move Up / Down Buttons**: Keyboard- and mobile-friendly reordering buttons on each block card as a built-in fallback.
- **High-Density Compact View**: Segmented toggle (`?view=compact`) for rapid content reordering across long articles. Compact mode hides in-between inserters, displays the primary field defined in the schema (`primary_field`), and clamps text output to two lines for streamlined scanning.
- **Shift+Click Multi-Selection & Multi-Drag**: Select multiple blocks in compact view using checkboxes or Shift+Click contiguous range selection with an active selection count badge. Dragging any selected card moves the entire group contiguously to the drop target.

### 🧩 Declarative Content Types & Generators
- **YAML-Defined Schemas**: Define structured content types with typed fields (`name:kind`) stored directly in source control (`config/content_types/*.yml`).
- **Full Scaffolding Generator**: Rapidly scaffold content types via `bin/rails generate macron:cms:content_type NAME [field:kind ...]`, which generates both the YAML schema and the host ViewComponent widget files.
- **Rake Import Pipeline**: Idempotently sync YAML definitions into database records (`Macron::Cms::Content`) with automatic schema introspection and admin dashboard views.

### ⚡ Front-End ViewComponent Widgets
- **`Macron::Cms::WidgetComponent`**: Base component class providing automatic method accessors for schema fields, payload values, attached files (`file`, `upload`), and article-level styles (`article_text_color`).
- **Seamless Rendering Helpers**: Render all article content blocks ordered by `sort_order` with `<%= cms_render_article_contents(@article) %>`, or render individual blocks via `<%= cms_render_widget(article_content) %>`.
- **Informative Error Handling**: Raises `Macron::Cms::MissingWidgetError` if a content type does not have a corresponding `Widgets::<Name>Component` in the host application.

### 🔒 Devise Authentication & Authorization
- **Configurable Access Guard**: Protect the `/cms` engine namespace behind host application authentication.
- **Role Customization**: Configure custom user models (`user_class`) and admin flags (`admin_flag`) via initializers.

### 🤖 REST API & AI Content Ingestion (`/cms/api/v1`)
- **Atomic Nested Import**: Create or update articles and complete sequences of typed content blocks in a single atomic transaction.
- **Automated Remote Asset Ingestion**: Remote image URLs (e.g. Substack, Medium, WordPress) are automatically downloaded, validated, and attached to Active Storage blobs.
- **Idempotent Upsert Support**: Re-run imports safely using `upsert: true` matching on canonical `slug` or `title` without creating duplicate articles.
- **Historical Slug Resolution**: Requests referencing previous slugs resolve with `200 OK` and return the current canonical slug in the response, preventing integration breaks.
- **Content Type Schema Introspection**: Query `GET /cms/api/v1/content_types` dynamically so AI agents know exact fields and widget types available.
- **Bearer Token Auth**: Secure endpoints with `Authorization: Bearer <token>` or `X-API-Key`.
- **Full API Documentation**: Complete endpoint specifications, payload schemas, and response models in [`docs/api.md`](docs/api.md).

### 🎨 Self-Contained Tailwind CSS v4
- **Zero Host Setup Required**: MacronCMS packages its own standalone, precompiled Tailwind CSS v4 bundle (`app/assets/stylesheets/macron/cms/application.css`). Host applications do not need Tailwind installed to display the CMS admin interface.
- **Isolated Styling**: The admin layout operates within its own styling boundary to avoid conflicts with host application design systems.

### 🔍 Built-in SEO Metadata Helpers
- **`cms_seo_meta(@article)`**: Helper to inject `<title>`, canonical `<link>`, and Open Graph meta tags into the view `<head>` using an article's title, meta title, and meta description overrides.

### 🌊 React & Three.js 3D Hydration
- **Interactive 3D Client Components**: Effortlessly hydrate rich client-side experiences—such as interactive 3D typography in [Three.js](https://threejs.org/)—wrapped cleanly in ViewComponent widgets.
- **Rich 3D Customization**: Supports selectable 3D fonts (Helvetiker, Optimer, Gentilis, Droid Serif), customizable font sizes, 3-axis rotation (`x`, `y`, `z`), and variable rotation speeds.
- **Visual CRT Shader Effects & Backgrounds**: Built-in CRT scanline shader overlays (intensity, density, speed) and dual-mode background support (hex colors or Active Storage background image in stretch/tile modes).
- **Turbo-Resilient Lifecycle**: Cleanly mounts, re-renders, and disposes React roots and Three.js animation loops across Turbo navigation (`turbo:load`, `turbo:render`, `turbo:before-cache`).

---

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem "macron-cms"
```

And then execute:

```bash
$ bundle install
```

Or install it directly:

```bash
$ gem install macron-cms
```

### 1. Active Storage Setup

MacronCMS utilizes Active Storage for block file attachments (such as images) and article background images. If your application does not already have Active Storage installed, set it up:

```bash
$ bin/rails active_storage:install
```

### 2. Engine Mounting & Migrations

Mount the engine inside your host application's `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount Macron::Cms::Engine => "/cms"
end
```

Copy and run the engine migrations:

```bash
$ bin/rails macron_cms:install:migrations
$ bin/rails db:migrate
```

---

## Content Types & Widgets

### 1. Generating a Content Type & ViewComponent Widget

Scaffold content types using the built-in Rails generator:

```bash
$ bin/rails generate macron:cms:content_type heading title:string level:dropdown color:color
$ bin/rails generate macron:cms:content_type paragraph content:text
$ bin/rails generate macron:cms:content_type markdown content:markdown
$ bin/rails generate macron:cms:content_type blockquote content:markdown
$ bin/rails generate macron:cms:content_type latex content:latex
$ bin/rails generate macron:cms:content_type image file:file width:dropdown align:dropdown caption:string
$ bin/rails generate macron:cms:content_type embed html:text width:dropdown align:dropdown
```

This generates:
1. `config/content_types/<name>.yml` (the schema definition)
2. `app/components/widgets/<name>_component.rb` (the ViewComponent class)
3. `app/components/widgets/<name>_component.html.erb` (the ViewComponent template)

---

### 2. Supported Field Kinds & Schema Options

| Kind | Description | Config Options | Accessor in Widget |
|---|---|---|---|
| `string` | Single-line text input | — | `field_name` |
| `text` | Multiline textarea | — | `field_name` |
| `dropdown` | Select dropdown menu | `options: [...]` in YAML schema | `field_name` |
| `color` | Color picker input (hex color code) | — | `field_name` |
| `markdown` | Multiline markdown with CodeMirror editor | — | `field_name` |
| `file` | File upload backed by Active Storage | — | `file` or `upload` (Active Storage attachment) |
| `json` | Formatted JSON editor | — | `field_name` |
| `latex` | Mathematical formula editor with CodeMirror & KaTeX | — | `field_name` |

#### Schema Configuration Options

In addition to fields, content type schemas support top-level configuration options:

| Option | Type | Description |
|---|---|---|
| `name` | String | Human-readable name of the content type |
| `description` | String | Detailed description displayed in the CMS admin dashboard |
| `featured_image` | Boolean | Set to `true` to declare this block as an image source for article featured image bubbling |
| `convertible_to` | Array of strings | Target content types eligible for declarative in-place conversion |
| `primary_field` | String | Designation of the field displayed as the primary preview in compact block view |

---

### 3. Schema Examples

#### Section Heading (`config/content_types/heading.yml`)
```yaml
name: Heading
description: Section heading with customizable level and color
fields:
  - name: title
    kind: string
  - name: level
    kind: dropdown
    options:
      - h1
      - h2
      - h3
      - h4
      - h5
      - h6
  - name: color
    kind: color
```

#### GitHub-Flavored Markdown (`config/content_types/markdown.yml`)
```yaml
name: Markdown
description: Rich formatted content using GitHub-flavored Markdown
fields:
  - name: content
    kind: markdown
```

#### Responsive Image with Active Storage (`config/content_types/image.yml`)
```yaml
name: Image
description: Image with configurable responsive width, alignment, and optional caption
featured_image: true
convertible_to:
  - three_js_image
fields:
  - name: file
    kind: file
  - name: width
    kind: dropdown
    options:
      - 25%
      - 33%
      - 50%
      - 66%
      - 75%
      - 100%
  - name: align
    kind: dropdown
    options:
      - left
      - center
      - right
  - name: caption
    kind: string
```

#### Sandboxed Embed / HTML (`config/content_types/embed.yml`)
```yaml
name: Embed
description: Embed external rich media or raw HTML snippets safely
fields:
  - name: html
    kind: text
  - name: width
    kind: dropdown
    options:
      - 25%
      - 33%
      - 50%
      - 66%
      - 75%
      - 100%
  - name: height
    kind: dropdown
    options:
      - name: Small (240px)
        value: sm
      - name: Medium (320px)
        value: md
      - name: Large (480px)
        value: lg
      - name: Extra Large (640px)
        value: xl
      - name: Very Large (800px)
        value: 2xl
  - name: align
    kind: dropdown
    options:
      - left
      - center
      - right
```

#### Mathematical Equation (`config/content_types/latex.yml`)
```yaml
fields:
  - name: content
    kind: latex
```

#### Blockquote with Markdown (`config/content_types/blockquote.yml`)
```yaml
fields:
  - name: content
    kind: markdown
```

#### Interactive 3D Quote (`config/content_types/three_js_quote.yml`)
```yaml
fields:
  - name: text
    kind: string
  - name: color
    kind: color
  - name: rotation_axis
    kind: dropdown
    options:
      - name: X Axis
        value: x
      - name: Y Axis
        value: y
      - name: Z Axis
        value: z
  - name: rotation_speed
    kind: dropdown
    options:
      - name: 0x (Paused)
        value: "0"
      - name: 0.5x
        value: "0.5"
      - name: 1x
        value: "1"
      - name: 2x
        value: "2"
  - name: font
    kind: dropdown
    options:
      - name: Helvetiker (Sans-serif)
        value: helvetiker
      - name: Optimer (Modern Sans)
        value: optimer
      - name: Gentilis (Humanist Sans)
        value: gentilis
      - name: Droid Serif (Serif)
        value: droid_serif
  - name: canvas_height
    kind: dropdown
    options:
      - name: Small (240px)
        value: sm
      - name: Medium (320px)
        value: md
      - name: Large (480px)
        value: lg
  - name: background_color
    kind: color
  - name: upload
    kind: file
  - name: background_mode
    kind: dropdown
    options:
      - name: Stretch
        value: stretch
      - name: Tile
        value: tile
  - name: scanlines_intensity
    kind: dropdown
    options:
      - name: Off
        value: off
      - name: Subtle
        value: subtle
      - name: Medium
        value: medium
      - name: Strong
        value: strong
```

#### Interactive 3D Image Effects (`config/content_types/three_js_image.yml`)
```yaml
featured_image: true
convertible_to:
  - image
fields:
  - name: upload
    kind: file
  - name: size
    kind: dropdown
    options:
      - name: Small (33%)
        value: sm
      - name: Medium (50%)
        value: md
      - name: Large (75%)
        value: lg
      - name: Full Width (100%)
        value: full
  - name: effect
    kind: dropdown
    options:
      - name: Water Ripple
        value: ripple
      - name: Underwater Wave
        value: wave
      - name: RGB Glitch
        value: glitch
  - name: animation_speed
    kind: dropdown
    options:
      - name: Slow
        value: slow
      - name: Normal
        value: normal
      - name: Fast
        value: fast
  - name: intensity
    kind: dropdown
    options:
      - name: Subtle
        value: subtle
      - name: Medium
        value: medium
      - name: Strong
        value: strong
  - name: canvas_height
    kind: dropdown
    options:
      - name: Small (240px)
        value: sm
      - name: Medium (320px)
        value: md
      - name: Large (480px)
        value: lg
      - name: Extra Large (640px)
        value: xl
  - name: fit_mode
    kind: dropdown
    options:
      - name: Cover (Fill & Crop)
        value: cover
      - name: Contain (Fit Inside)
        value: contain
```

---

### 4. Importing Content Types

Import all YAML content type definitions into the database (`Macron::Cms::Content`):

```bash
$ bin/rails macron:cms:import_content_types
```

Or using the shorter alias:

```bash
$ bin/rails macron:cms:content:import
```

The import task is idempotent and creates or updates existing records. Once imported, content types can be inspected at `/cms/content_types` and added as content blocks to articles in `/cms/articles/:id`.

---

### 5. Front-End Integration & ViewComponent Widgets

#### Host Application Controller (`app/controllers/articles_controller.rb`)

Include `Macron::Cms::SlugRedirectable` in your host controller to automatically issue canonical 301 permanent redirects if a visitor or search engine arrives via an outdated historical slug:

```ruby
class ArticlesController < ApplicationController
  include Macron::Cms::SlugRedirectable

  def show
    @article = Macron::Cms::Article.friendly.find(params[:id])
    redirect_to_canonical_slug_if_needed(@article)
  end
end
```

#### Editorial Stream & Featured Images (`app/views/pages/index.html.erb`)

When listing articles on a homepage or editorial index, eager-load `:featured_image_blob` to display automatically bubbled featured images with zero N+1 database queries:

```ruby
# app/controllers/pages_controller.rb
class PagesController < ApplicationController
  def index
    # Default scope orders chronologically by published_at DESC, created_at DESC
    @articles = Macron::Cms::Article.includes(:featured_image_blob)
  end
end
```

```erb
<%# app/views/pages/index.html.erb %>
<div class="space-y-6">
  <% @articles.each do |article| %>
    <div class="flex items-start gap-4">
      <% if article.featured_image.present? %>
        <%= link_to article_path(article), class: "shrink-0" do %>
          <%= image_tag article.featured_image, class: "w-24 h-24 object-cover rounded-lg border border-zinc-200" %>
        <% end %>
      <% end %>
      <div>
        <h2 class="text-xl font-bold"><%= link_to article.title, article_path(article) %></h2>
        <p class="text-sm text-zinc-600 line-clamp-2"><%= article.seo_description %></p>
      </div>
    </div>
  <% end %>
</div>
```

#### Host Application View (`app/views/articles/show.html.erb`)

Use `cms_seo_meta` for SEO metadata and `cms_article_background_style` to apply custom background colors, images, and text colors directly to the layout:

```erb
<% cms_seo_meta(@article) %>
<% if cms_article_background_style(@article).present? %>
  <% content_for :body_style, cms_article_background_style(@article) %>
<% end %>

<article class="max-w-4xl mx-auto px-4 py-12">
  <header class="pb-8 mb-8 border-b border-zinc-200">
    <h1 class="text-4xl font-bold" style="<%= "color: #{@article.text_color};" if @article.text_color.present? %>">
      <%= @article.title %>
    </h1>
  </header>

  <!-- Render all content blocks in order -->
  <div class="space-y-6">
    <%= cms_render_article_contents(@article) %>
  </div>
</article>
```

In your application layout (`app/views/layouts/application.html.erb`), apply the `:body_style` slot and include the KaTeX and 3D widget assets:

```erb
<head>
  <title><%= content_for(:title) || "Macron CMS" %></title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= turbo_include_tags %>

  <%# KaTeX Stylesheet & Scripts (LaTeX Math Rendering) %>
  <%= stylesheet_link_tag "macron/cms/katex.min", "data-turbo-track": "reload" %>
  <%= javascript_include_tag "macron/cms/katex.min", "data-turbo-track": "reload", defer: true %>
  <%= javascript_include_tag "widgets/latex", "data-turbo-track": "reload", defer: true %>

  <%# React & Three.js Vendor Bundles (3D Interactive Widgets) %>
  <%= javascript_include_tag "vendor/react_bundle", "data-turbo-track": "reload", defer: true %>
  <%= javascript_include_tag "vendor/three_text_bundle", "data-turbo-track": "reload", defer: true %>
  <%= javascript_include_tag "vendor/three_fonts_bundle", "data-turbo-track": "reload", defer: true %>
  <%= javascript_include_tag "widgets/three_js_quote", "data-turbo-track": "reload", defer: true %>
  <%= javascript_include_tag "widgets/three_js_image", "data-turbo-track": "reload", defer: true %>
  <%= javascript_include_tag "widgets/embed", "data-turbo-track": "reload", defer: true %>
</head>

<body class="min-h-screen text-zinc-900 <%= 'bg-zinc-50' unless content_for?(:body_style) %>"
      style="<%= yield :body_style if content_for?(:body_style) %>">
  <%= yield %>
</body>
```

#### Heading Widget Component Example

```ruby
# app/components/widgets/heading_component.rb
module Widgets
  class HeadingComponent < Macron::Cms::WidgetComponent
    def tag_name
      level.presence || "h2"
    end

    def resolved_color
      color.presence || article_text_color
    end
  end
end
```

```erb
<%# app/components/widgets/heading_component.html.erb %>
<%= content_tag(tag_name, title, class: "font-bold tracking-tight", style: ("color: #{resolved_color};" if resolved_color.present?)) %>
```

#### Markdown Widget Component Example

Render Markdown with Kramdown and inherit article-level text styling:

```ruby
# app/components/widgets/markdown_component.rb
module Widgets
  class MarkdownComponent < Macron::Cms::WidgetComponent
    def rendered_markdown
      raw = field_value(:content).to_s
      return "".html_safe if raw.blank?

      Kramdown::Document.new(raw, input: "GFM").to_html.html_safe
    end

    def text_style
      "color: #{article_text_color};" if article_text_color.present?
    end
  end
end
```

```erb
<%# app/components/widgets/markdown_component.html.erb %>
<div class="prose max-w-none text-inherit dark:prose-invert" style="<%= text_style %>">
  <%= rendered_markdown %>
</div>
```

#### Image Widget Component Example

Access Active Storage attachments using `file` or `upload`:

```ruby
# app/components/widgets/image_component.rb
module Widgets
  class ImageComponent < Macron::Cms::WidgetComponent
    def attached_file
      file
    end

    def width_class
      case width
      when "25%" then "max-w-xs"
      when "33%" then "max-w-sm"
      when "50%" then "max-w-md"
      when "66%" then "max-w-lg"
      when "75%" then "max-w-2xl"
      else "w-full"
      end
    end

    def align_class
      case align
      when "left" then "mr-auto"
      when "right" then "ml-auto"
      else "mx-auto"
      end
    end
  end
end
```

```erb
<%# app/components/widgets/image_component.html.erb %>
<% if attached_file.present? %>
  <figure class="<%= width_class %> <%= align_class %> my-6">
    <%= image_tag attached_file, class: "rounded-lg shadow-sm w-full h-auto" %>
    <% if caption.present? %>
      <figcaption class="mt-2 text-center text-sm text-zinc-500"><%= caption %></figcaption>
    <% end %>
  </figure>
<% end %>
```

#### Sandboxed Embed Widget Component Example

```ruby
# app/components/widgets/embed_component.rb
module Widgets
  class EmbedComponent < Macron::Cms::WidgetComponent
    HEIGHT_CLASSES = {
      "sm"  => "h-60 sm:h-72",
      "md"  => "h-72 sm:h-80",
      "lg"  => "h-96 sm:h-[480px]",
      "xl"  => "h-[540px] sm:h-[640px]",
      "2xl" => "h-[640px] sm:h-[800px]"
    }.freeze
    DEFAULT_HEIGHT = "lg"

    def embed_html
      field_value(:html).presence || (upload.present? ? upload.download.force_encoding("UTF-8") : nil)
    end

    def width_class
      case width
      when "25%" then "max-w-xs"
      when "33%" then "max-w-sm"
      when "50%" then "max-w-md"
      when "66%" then "max-w-lg"
      when "75%" then "max-w-2xl"
      else "w-full"
      end
    end

    def align_class
      case align
      when "left" then "mr-auto"
      when "right" then "ml-auto"
      else "mx-auto"
      end
    end

    def height_class
      h = field_value(:height).to_s.strip.downcase
      HEIGHT_CLASSES[h] || HEIGHT_CLASSES[DEFAULT_HEIGHT]
    end
  end
end
```

```erb
<%# app/components/widgets/embed_component.html.erb %>
<div class="relative group my-6 <%= width_class %> <%= align_class %> overflow-hidden rounded-xl border border-zinc-200 bg-white shadow-xs [&:fullscreen]:m-0 [&:fullscreen]:w-screen [&:fullscreen]:h-screen [&:fullscreen]:rounded-none" data-embed-card>
  <!-- Fullscreen Toggle Button -->
  <button
    type="button"
    class="absolute top-3 right-3 z-10 flex h-8 w-8 items-center justify-center rounded-lg bg-zinc-900/60 text-white backdrop-blur-xs transition hover:bg-zinc-900/90 focus:outline-none opacity-70 group-hover:opacity-100 cursor-pointer"
    data-embed-fullscreen-btn
    aria-label="Maximize"
    title="Maximize"
  >
    <svg class="h-4 w-4" data-icon-enter-fullscreen fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 3.75v4.5m0-4.5h4.5m-4.5 0L9 9M3.75 20.25v-4.5m0 4.5h4.5m-4.5 0L9 15M20.25 3.75h-4.5m4.5 0v4.5m0-4.5L15 9m5.25 11.25h-4.5m4.5 0v-4.5m0 4.5L15 15" />
    </svg>
    <svg class="h-4 w-4 hidden" data-icon-exit-fullscreen fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
      <path stroke-linecap="round" stroke-linejoin="round" d="M9 9V4.5M9 9H4.5M9 9 3.75 3.75M9 15v4.5M9 15H4.5M9 15l-5.25 5.25M15 9h4.5M15 9V4.5M15 9l5.25-5.25M15 15h4.5M15 15v4.5m0-4.5 5.25 5.25" />
    </svg>
  </button>

  <iframe
    srcdoc="<%= embed_html %>"
    class="w-full <%= height_class %> border-0 [&.is-fullscreen-iframe]:h-full"
    sandbox="allow-scripts allow-same-origin allow-popups allow-forms"
    allowfullscreen
    allow="fullscreen"
    loading="lazy"
    title="Embedded content">
  </iframe>
</div>
```

#### Blockquote Widget Component Example

Render quote blocks with Markdown and dynamically inherited article text color:

```ruby
# app/components/widgets/blockquote_component.rb
module Widgets
  class BlockquoteComponent < Macron::Cms::WidgetComponent
    def rendered_html
      return "".html_safe if content.blank?

      raw_html = Kramdown::Document.new(content.to_s, input: "GFM").to_html
      helpers.sanitize(raw_html)
    end

    def custom_style
      return unless article_text_color.present?

      "color: #{article_text_color}; border-color: #{article_text_color};"
    end

    def blockquote_classes
      base = "border-l-4 pl-4 py-1.5 my-6 max-w-none text-base leading-relaxed italic space-y-2"
      article_text_color.present? ? base : "#{base} border-zinc-300 text-zinc-800"
    end
  end
end
```

```erb
<%# app/components/widgets/blockquote_component.html.erb %>
<blockquote class="<%= blockquote_classes %>" style="<%= custom_style %>">
  <%= rendered_html %>
</blockquote>
```

#### LaTeX Mathematical Widget Component Example

Render mathematical notation and formulas with KaTeX:

```ruby
# app/components/widgets/latex_component.rb
module Widgets
  class LatexComponent < Macron::Cms::WidgetComponent
    def formula
      content.to_s
    end

    def custom_style
      "color: #{article_text_color};" if article_text_color.present?
    end

    def latex_classes
      "cms-latex-widget my-6 overflow-x-auto py-2 text-center"
    end
  end
end
```

```erb
<%# app/components/widgets/latex_component.html.erb %>
<% if formula.present? %>
  <%= content_tag(
    :div,
    content_tag(:span, formula, class: "font-mono text-xs opacity-75"),
    class: latex_classes,
    style: custom_style,
    data: { cms_latex: formula, cms_latex_display: "true" }
  ) %>
<% end %>
```

#### Interactive 3D Three.js Widget Component Example

Hydrate a 3D Three.js scene with React in a ViewComponent with Turbo lifecycle awareness:

```ruby
# app/components/widgets/three_js_quote_component.rb
module Widgets
  class ThreeJsQuoteComponent < Macron::Cms::WidgetComponent
    DEFAULT_COLOR = "#18181b"
    CANVAS_HEIGHT_CLASSES = {
      "sm" => "h-60",
      "md" => "h-64 sm:h-80",
      "lg" => "h-96 sm:h-[480px]",
      "xl" => "h-[540px] sm:h-[640px]"
    }.freeze

    def render?
      quote_text.present?
    end

    def quote_text
      field_value("text").to_s.strip.presence
    end

    def effective_color
      field_value("color").presence || article_text_color.presence || DEFAULT_COLOR
    end

    def rotation_axis
      field_value("rotation_axis").presence || "x"
    end

    def rotation_speed
      field_value("rotation_speed").presence || "1"
    end

    def canvas_height_class
      CANVAS_HEIGHT_CLASSES[field_value("canvas_height")] || "h-64 sm:h-80"
    end
  end
end
```

```erb
<%# app/components/widgets/three_js_quote_component.html.erb %>
<figure
  class="my-6 w-full overflow-hidden rounded-xl border border-zinc-200 bg-gradient-to-b from-white to-zinc-50 shadow-xs"
  data-three-js-quote-card
>
  <blockquote class="sr-only"><%= quote_text %></blockquote>
  <div
    class="relative w-full <%= canvas_height_class %>"
    data-three-js-quote-mount
    data-quote-text="<%= quote_text %>"
    data-quote-color="<%= effective_color %>"
    data-rotation-axis="<%= rotation_axis %>"
    data-rotation-speed="<%= rotation_speed %>"
    data-font="<%= field_value('font').presence || 'helvetiker' %>"
    data-font-size="<%= field_value('font_size').presence || 'md' %>"
    data-scanlines-intensity="<%= field_value('scanlines_intensity').presence || 'off' %>"
    role="img"
    aria-label="<%= quote_text %>"
  ></div>
</figure>
```

---

## REST API & AI Content Ingestion

MacronCMS provides a JSON REST API under `/cms/api/v1/` designed for programmatic ingestion, automated scripts, and autonomous AI agents migrating content from external platforms (such as Substack, WordPress, or Medium).

> [!TIP]
> For the complete endpoint reference, request/response payload schemas, parameter definitions, and status codes, see the dedicated [**REST API Documentation (`docs/api.md`)**](docs/api.md). If you are building an automated ingestion pipeline or AI migration agent, refer to the [**AI Article Importer Guide (`docs/ai_importer_guide.md`)**](docs/ai_importer_guide.md).

### Authentication

API endpoints are secured using a Bearer token or API key header:

```http
Authorization: Bearer <MACRON_CMS_API_KEY>
```
Or:
```http
X-API-Key: <MACRON_CMS_API_KEY>
```

Configure your key in an initializer (`config.api_key`) or via the `MACRON_CMS_API_KEY` environment variable. In `development` and `test` environments, authentication is optional if no key is configured.

---

### Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | [`/cms/api/v1/articles`](docs/api.md#2-create-or-upsert-article-post-cmsapiv1articles) | Create or upsert an article with nested content blocks |
| `GET` | [`/cms/api/v1/articles/:id`](docs/api.md#3-retrieve-article-get-cmsapiv1articlesid) | Retrieve article metadata and ordered content blocks (JSON) |
| `PATCH` | [`/cms/api/v1/articles/:id`](docs/api.md#4-update-article-patch-cmsapiv1articlesid) | Update article attributes and synchronize content blocks |
| `GET` | [`/cms/api/v1/content_types`](docs/api.md#1-list-content-types-get-cmsapiv1content_types) | Introspect available content types and schema field requirements |

---

### 1. Ingesting Articles with Nested Content Blocks

You can import an entire article—including its metadata, SEO tags, colors, and an ordered list of typed content blocks—in a single atomic transaction:

```bash
curl -X POST http://localhost:3000/cms/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-secret-key" \
  -d '{
    "upsert": true,
    "article": {
      "title": "The Myth of Your Limitations",
      "slug": "the-myth-of-your-limitations",
      "meta_title": "The Myth of Your Limitations | Mindset Guide",
      "meta_description": "How a simple mindset shift can prove you wrong.",
      "background_color": "#ffffff",
      "text_color": "#18181b"
    },
    "content_blocks": [
      {
        "content_type": "heading",
        "payload": {
          "title": "The Rule of Congruency",
          "level": "h3"
        }
      },
      {
        "content_type": "markdown",
        "payload": {
          "content": "There is a principle in geometry called the **congruency of triangles**..."
        }
      },
      {
        "content_type": "image",
        "payload": { "size": "lg" },
        "image_url": "https://substack-post-media.s3.amazonaws.com/public/images/7343afc4-325e-42a1-9145-dd916d0de54d_1024x1024.png"
      }
    ]
  }'
```

#### Automated Remote Asset Ingestion
When an `image_url` (or `upload_url`) is provided in a content block, MacronCMS automatically downloads the asset from the remote source (e.g. Substack CDN), verifies content size and type, and attaches it as an Active Storage blob on the content block. If the remote server is unreachable, it gracefully falls back to storing the direct URL in the block payload.

#### Idempotent Upserting
When `"upsert": true` is specified, the API searches for an existing article matching `slug` or `title`. If found, it updates the article attributes and atomically replaces its content blocks with the incoming sequence, making bulk migrations safe to re-run.

---

### 2. Schema Introspection (`GET /cms/api/v1/content_types`)

AI agents can query `/cms/api/v1/content_types` before generating payloads to dynamically discover which widget types exist and what fields they require:

```json
{
  "content_types": [
    {
      "id": 1,
      "name": "heading",
      "fields": [
        { "name": "title", "kind": "string" },
        { "name": "level", "kind": "dropdown", "options": ["h1", "h2", "h3", "h4", "h5", "h6"] },
        { "name": "color", "kind": "color" }
      ],
      "convertible_to": [],
      "featured_image": false
    },
    {
      "id": 2,
      "name": "image",
      "fields": [
        { "name": "upload", "kind": "file" },
        { "name": "size", "kind": "dropdown", "options": ["sm", "md", "lg", "full"] }
      ],
      "convertible_to": [
        "three_js_image"
      ],
      "featured_image": true
    }
  ]
}
```

For complete endpoint specifications, payload schemas, and response formats, see [`docs/api.md`](docs/api.md). For Substack HTML mapping rules and a ready-to-use prompt template for AI agents, see [`docs/ai_importer_guide.md`](docs/ai_importer_guide.md).

---

## Configuration

Customize CMS options in an initializer:

```ruby
# config/initializers/macron_cms.rb
Macron::Cms.configure do |config|
  config.user_class = "User"                   # Devise user model (default: "User")
  config.admin_flag = :admin                   # Method or boolean column for admin check (default: :admin)
  config.api_key    = ENV["MACRON_CMS_API_KEY"] # Bearer token for /cms/api/v1 (default: ENV["MACRON_CMS_API_KEY"])
  config.content_types_path = Rails.root.join("config", "content_types") # Custom schema directory
end
```

---

## Local Development & Dummy App

To run and test MacronCMS locally using the included dummy host application:

1. **Set up the database and seed records:**
   ```bash
   cd dummy
   bin/rails db:prepare
   bin/rails db:seed
   ```

2. **Start the local server with asset watchers:**
   ```bash
   bin/dev
   ```
   *`bin/dev` starts Puma on port 3000 alongside watchers for both host CSS and engine Tailwind CSS.*

3. **Access the CMS Dashboard:**
   Visit [`http://localhost:3000/cms`](http://localhost:3000/cms).

### Test User Credentials

The database seeds create two test users:

| Email | Password | Role / Access | Behavior at `/cms` |
|---|---|---|---|
| `admin@example.com` | `password` | **Admin** (`admin: true`) | Grants access to `/cms` (CMS Dashboard) |
| `user@example.com` | `password` | **Regular User** (`admin: false`) | Denied access; redirected to `/` with alert |

---

## Working with Engine Tailwind CSS

MacronCMS compiles standalone Tailwind CSS via `tailwindcss-ruby`.

- **Compile engine CSS:**
  ```bash
  bundle exec rake macron:cms:tailwind:build
  ```

- **Watch engine CSS for live changes:**
  ```bash
  bundle exec rake macron:cms:tailwind:watch
  ```

The source Tailwind configuration resides in [`app/assets/tailwind/macron/cms/application.css`](app/assets/tailwind/macron/cms/application.css) and compiles into [`app/assets/stylesheets/macron/cms/application.css`](app/assets/stylesheets/macron/cms/application.css).

---

## Testing & Quality

Run the test suite through the dummy application:

```bash
cd dummy
bin/rails test
```

Run code style and lint checks from the root:

```bash
bundle exec rubocop
```

---

## Contributing

Contributions, feedback, and discussions are welcome! Please open an issue or pull request on GitHub.

---

## License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).
