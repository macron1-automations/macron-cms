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

## Upcoming Features

### 🔄 `wp_loop`-Inspired Data Architecture
A clean, intuitive query and iteration loop designed to iterate over your content and present it however you want. No overly complex schema gymnastics—just a straightforward, familiar looping pattern that puts full control of the layout and rendering pipeline back in your hands.

### ⚡ Rails Content Modeling with Hotwire & React Hydration
Design your content types cleanly in Rails, and choose the presentation layer that suits your requirements:
- Render seamlessly via **Hotwire** (Turbo & Stimulus) for lightning-fast server-rendered content with minimal JavaScript overhead.
- Drop in **React plugins** where heavy client-side interactivity is needed. This makes hydrating complex client components—such as interactive 3D [Three.js](https://threejs.org/) scenes, interactive canvases, and custom calculators—effortless and isolated.

### 🎨 Tailwind CSS by Default
Frame and style your content effortlessly with Tailwind CSS. MacronCMS provides clean semantic markup hooks and utility styling out of the box, allowing you to tailor every container, block, and interactive element directly in your theme.

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
> gem "macron-cms", git: "https://github.com/macron-cms/macron-cms.git", branch: "main"
> ```

---

## Local Development & Dummy App

To test MacronCMS locally using the included dummy host application:

1. **Set up the database and seed records:**
   ```bash
   cd dummy
   bin/rails db:prepare
   bin/rails db:seed
   ```

2. **Start the local server:**
   ```bash
   bin/rails dev # or bin/rails server
   ```

3. **Access the CMS:**
   Visit [`http://localhost:3000/cms`](http://localhost:3000/cms). If you are not signed in, Devise will automatically redirect you to the sign-in page (`/users/sign_in`).

### Test User Credentials

The database seeds create two test users:

| Email | Password | Role / Access | Behavior at `/cms` |
|---|---|---|---|
| `admin@example.com` | `password` | **Admin** (`admin: true`) | Grants access to `/cms` (CMS Dashboard) |
| `user@example.com` | `password` | **Regular User** (`admin: false`) | Denied access; redirected to `/` with alert |

---

## Contributing

Contributions, feedback, and discussions are welcome! Since the project is in early rapid development, please open an issue first to discuss architectural changes or ideas before submitting a pull request.

---

## License

The gem is available as open source under the terms of the [MIT License](MIT-LICENSE).
