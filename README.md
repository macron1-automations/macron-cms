# MacronCMS

[![Status: In Rapid Development](https://img.shields.io/badge/status-rapid--development-orange.svg)](#status)
[![Rails 8+](https://img.shields.io/badge/rails-8%2B-red.svg)](https://rubyonrails.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](MIT-LICENSE)

A simple, flexible CMS for building highly interactive content.

> [!WARNING]
> **Active Pre-Release Development**  
> MacronCMS is currently under rapid development. APIs, data architectures, and conventions are evolving quickly and subject to breaking changes prior to an official `v1.0` release.

---

## Overview

**MacronCMS** brings simplicity and developer joy back to content management, without sacrificing the power needed to create dynamic, highly interactive digital experiences. Built natively for Ruby on Rails, it gives developers total freedom to define content structures with Rails models while effortlessly powering modern frontend presentations.

---

## Features

### 🛠️ Dedicated Admin Dashboard (`/cms`)
- **Modern Zinc Aesthetic**: Clean, responsive monochrome layout with sidebar navigation, metric cards, quick-action buttons, and flash notification banners.
- **Lightweight Content CRUD**: Manage articles (`Macron::Cms::Article`) out-of-the-box with dedicated create, edit, show, and delete interfaces.
- **Friendly URLs**: Automatic slug generation via `friendly_id` for clean SEO-friendly URLs.
- **Host App Integration**: Quick links between the CMS admin console and public-facing host views.

### 🎨 Self-Contained Tailwind CSS
- **Zero Host Setup Required**: MacronCMS packages its own standalone, precompiled Tailwind CSS v4 bundle (`app/assets/stylesheets/macron/cms/application.css`). Host applications do not need to install or configure Tailwind to display the CMS admin interface.
- **Isolated Styling**: The admin layout operates within its own styling boundary to avoid conflicts with host application design systems.

### 🔒 Devise Authentication & Authorization
- **Configurable Access Guard**: Protect the `/cms` engine namespace behind host application authentication.
- **Role Customization**: Configure custom user models (`user_class`) and admin flags (`admin_flag`) via initializers.

---

## Upcoming Features

### 🔄 `wp_loop`-Inspired Data Architecture
A clean, intuitive query and iteration loop designed to iterate over your content and present it however you want. No overly complex schema gymnastics—just a straightforward, familiar looping pattern that puts full control of the layout and rendering pipeline back in your hands.

### ⚡ Rails Content Modeling with Hotwire & React Hydration
Design your content types cleanly in Rails, and choose the presentation layer that suits your requirements:
- Render seamlessly via **Hotwire** (Turbo & Stimulus) for lightning-fast server-rendered content with minimal JavaScript overhead.
- Drop in **React plugins** where heavy client-side interactivity is needed. This makes hydrating complex client components—such as interactive 3D [Three.js](https://threejs.org/) scenes, interactive canvases, and custom calculators—effortless and isolated.

### 🤖 AI-Friendly API for Quick Content Migration
Migrate existing content quickly and programmatically with an AI-friendly ingest and transformation API. Whether extracting legacy CMS payloads, translating markdown collections, or structuring unstructured assets, MacronCMS provides streamlined endpoints designed for agentic workflows and automated pipelines.

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

> [!NOTE]
> During active development, you may also track the repository directly via Git in your `Gemfile`:
> ```ruby
> gem "macron-cms", git: "https://github.com/macron1-automations/macron-cms.git", branch: "main"
> ```

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

## Local Development & Dummy App

To test MacronCMS locally using the included dummy host application:

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
   *`bin/dev` starts Puma on port 3000 alongside watchers for both the host app's CSS and the engine's Tailwind CSS.*

3. **Access the CMS Dashboard:**
   Visit [`http://localhost:3000/cms`](http://localhost:3000/cms). If you are not signed in, Devise will automatically redirect you to the sign-in page (`/users/sign_in`).

### Test User Credentials

The database seeds create two test users:

| Email | Password | Role / Access | Behavior at `/cms` |
|---|---|---|---|
| `admin@example.com` | `password` | **Admin** (`admin: true`) | Grants access to `/cms` (CMS Dashboard) |
| `user@example.com` | `password` | **Regular User** (`admin: false`) | Denied access; redirected to `/` with alert |

---

## Working with Engine Tailwind CSS

MacronCMS compiles standalone Tailwind CSS via `tailwindcss-ruby`.

### Build Tasks

- **Compile engine CSS (one-off):**
  From the engine root:
  ```bash
  bundle exec rake macron:cms:tailwind:build
  ```
  Or from the `dummy/` directory:
  ```bash
  bin/rails macron:cms:tailwind:build
  ```

- **Watch engine CSS for live changes:**
  From the engine root:
  ```bash
  bundle exec rake macron:cms:tailwind:watch
  ```
  Or from the `dummy/` directory:
  ```bash
  bin/rails macron:cms:tailwind:watch
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

Contributions, feedback, and discussions are welcome! Since the project is in early rapid development, please open an issue first to discuss architectural changes or ideas before submitting a pull request.

---

## License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).
