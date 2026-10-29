# MacronCMS

[![Gem Version](https://img.shields.io/badge/version-1.0.0-emerald.svg)](#version)
[![Rails 8+](https://img.shields.io/badge/rails-8%2B-red.svg)](https://rubyonrails.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](MIT-LICENSE)

A simple, flexible CMS engine for Ruby on Rails, designed for building highly interactive content with dynamic content blocks, declarative schemas, and ViewComponent widgets.

---

## Overview

**MacronCMS** brings simplicity and developer joy back to content management, without sacrificing the power needed to create dynamic digital experiences. Built natively for Ruby on Rails, it gives developers total freedom to define content structures with Rails models while effortlessly powering modern front-end presentations.

---

## Features

### 🛠️ Dedicated Admin Dashboard (`/cms`)
- **Modern Zinc Aesthetic**: Clean, responsive monochrome layout with sticky sidebar navigation, top breadcrumbs, metric cards, quick-action buttons, and flash notification banners.
- **Article CRUD & Friendly URLs**: Manage articles (`Macron::Cms::Article`) out-of-the-box with dedicated create, edit, show, and delete interfaces. Automatic slug generation via `friendly_id` produces clean SEO URLs.
- **Deletion Safeguards**: Browser confirmation dialogs on delete actions with article titles to prevent accidental deletion.
- **Host App Integration**: Quick links between the CMS admin console and public-facing host views.

### 🧱 Dynamic Article Content Blocks & Payload Storage
- **Multiple Blocks Per Article**: Associate an arbitrary series of content blocks with an article (`Macron::Cms::ArticleContent`). Add multiple blocks of the same content type (e.g. multiple headings or paragraphs) with distinct values.
- **Dynamic Field Populating**: When adding or editing a block, input controls are automatically generated based on the content type's defined fields. Values are validated against the schema and saved into the block's `payload` JSONB column.
- **Extensible Field Kinds**: Out-of-the-box support for `string` (text input), `text` (multiline textarea), and `dropdown` (select menu with configured options), with a partial-based architecture (`app/views/macron/cms/fields/_<kind>.html.erb`) making it effortless to add new field types.
- **Inline Editing & Deletion**: Edit block payloads inline directly on the Article show page, or remove blocks with confirmation.

### ↕️ Drag-and-Drop & Button Reordering
- **HTML5 Drag-and-Drop**: Easily re-arrange article content blocks on the Article show page with immediate position updates and asynchronous persistence.
- **Accessible Move Up / Down Buttons**: Keyboard- and mobile-friendly reordering buttons on each block card as a built-in fallback.

### 🧩 Declarative Content Types & Generators
- **YAML-Defined Schemas**: Define structured content types with typed fields (`name:kind`) stored directly in source control (`config/content_types/*.yml`).
- **Full Scaffolding Generator**: Rapidly scaffold content types via `bin/rails generate macron:cms:content_type NAME [field:kind ...]`, which generates both the YAML schema and the host ViewComponent widget files.
- **Rake Import Pipeline**: Idempotently sync YAML definitions into database records (`Macron::Cms::Content`) with automatic schema introspection and admin dashboard views.

### ⚡ Front-End ViewComponent Widgets
- **`Macron::Cms::WidgetComponent`**: Base component class providing automatic method accessors for all defined schema fields and payload values.
- **Seamless Rendering Helpers**: Render all article content blocks ordered by `sort_order` with `<%= cms_render_article_contents(@article) %>`, or render individual blocks via `<%= cms_render_widget(article_content) %>`.
- **Informative Error Handling**: Raises `Macron::Cms::MissingWidgetError` if a content type does not have a corresponding `Widgets::<Name>Component` in the host application.

### 🔒 Devise Authentication & Authorization
- **Configurable Access Guard**: Protect the `/cms` engine namespace behind host application authentication.
- **Role Customization**: Configure custom user models (`user_class`) and admin flags (`admin_flag`) via initializers.

### 🎨 Self-Contained Tailwind CSS v4
- **Zero Host Setup Required**: MacronCMS packages its own standalone, precompiled Tailwind CSS v4 bundle (`app/assets/stylesheets/macron/cms/application.css`). Host applications do not need Tailwind installed to display the CMS admin interface.
- **Isolated Styling**: The admin layout operates within its own styling boundary to avoid conflicts with host application design systems.

### 🔍 Built-in SEO Metadata Helpers
- **`cms_seo_meta(@article)`**: Helper to inject `<title>`, canonical `<link>`, and Open Graph meta tags into the view `<head>` using an article's title, meta title, and meta description overrides.

---

## Coming Soon

### 🌊 React & Three.js Hydration Plugins
Drop in React plugins where heavy client-side interactivity is needed, making hydrating complex client components—such as interactive 3D [Three.js](https://threejs.org/) scenes, interactive canvases, and custom calculators—effortless and isolated.

### 🤖 AI-Friendly API for Content Migration
An AI-friendly ingest and transformation API for migrating existing content quickly and programmatically across legacy datasets, CMS exports, and unstructured assets.

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

### Engine Mounting & Migrations

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
$ bin/rails generate macron:cms:content_type heading title:string level:string
$ bin/rails generate macron:cms:content_type paragraph content:text
$ bin/rails generate macron:cms:content_type image url:string caption:text
```

This generates:
1. `config/content_types/<name>.yml` (the schema definition)
2. `app/components/widgets/<name>_component.rb` (the ViewComponent class)
3. `app/components/widgets/<name>_component.html.erb` (the ViewComponent template)

### 2. Importing Content Types

Import all YAML content type definitions into the database (`Macron::Cms::Content`):

```bash
$ bin/rails macron:cms:import_content_types
```

Or using the shorter alias:

```bash
$ bin/rails macron:cms:content:import
```

The import task is idempotent and creates or updates existing records. Once imported, content types can be inspected at `/cms/content_types` and added as content blocks to articles in `/cms/articles/:id`.

### 3. Rendering Content Blocks on the Front End

In your front-end article view (e.g. `app/views/articles/show.html.erb`), render all blocks ordered by `sort_order`:

```erb
<% cms_seo_meta(@article) %>

<article class="max-w-3xl mx-auto py-12">
  <h1 class="text-4xl font-bold"><%= @article.title %></h1>

  <div class="mt-8 space-y-6">
    <%= cms_render_article_contents(@article) %>
  </div>
</article>
```

Each widget inherits from `Macron::Cms::WidgetComponent`, allowing you to access fields directly by name or via `field_value(name)`:

```ruby
# app/components/widgets/heading_component.rb
module Widgets
  class HeadingComponent < Macron::Cms::WidgetComponent
    def tag_name
      level.presence || "h2"
    end
  end
end
```

```erb
<%# app/components/widgets/heading_component.html.erb %>
<%= content_tag(tag_name, title, class: "font-bold text-zinc-900") %>
```

---

## Configuration

Customize CMS options in an initializer:

```ruby
# config/initializers/macron_cms.rb
Macron::Cms.configure do |config|
  config.user_class = "User"                   # Devise user model (default: "User")
  config.admin_flag = :admin                   # Method or boolean column for admin check (default: :admin)
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
