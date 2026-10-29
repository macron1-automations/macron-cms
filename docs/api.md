# MacronCMS REST API Reference

MacronCMS provides a JSON REST API under `/cms/api/v1/` designed for headless content management, programmatic ingestion, automated scripts, and autonomous AI agents.

---

## Table of Contents

- [Overview & Base URL](#overview--base-url)
- [Authentication](#authentication)
- [Dynamic Content Blocks & Ingestion Model](#dynamic-content-blocks--ingestion-model)
  - [Block Structure](#block-structure)
  - [Remote Asset Ingestion](#remote-asset-ingestion)
- [API Endpoints](#api-endpoints)
  - [1. List Content Types (`GET /cms/api/v1/content_types`)](#1-list-content-types-get-cmsapiv1content_types)
  - [2. Create or Upsert Article (`POST /cms/api/v1/articles`)](#2-create-or-upsert-article-post-cmsapiv1articles)
  - [3. Retrieve Article (`GET /cms/api/v1/articles/:id`)](#3-retrieve-article-get-cmsapiv1articlesid)
  - [4. Update Article (`PATCH /cms/api/v1/articles/:id`)](#4-update-article-patch-cmsapiv1articlesid)
- [Status Codes & Error Responses](#status-codes--error-responses)
- [Related Documentation](#related-documentation)

---

## Overview & Base URL

All API routes are served under the mounted engine path (by default `/cms`) prefixed with `/api/v1`:

```
http(s)://<your-domain>/cms/api/v1
```

All requests containing a payload must set the following HTTP request header:
```http
Content-Type: application/json
```

All responses return standard JSON.

---

## Authentication

API endpoints require API key authentication, unless running in `development` or `test` environments where no key has been configured.

### Headers

Provide the API key via either `Authorization` or `X-API-Key`:

```http
Authorization: Bearer <MACRON_CMS_API_KEY>
```

or:

```http
X-API-Key: <MACRON_CMS_API_KEY>
```

### Configuration

Set the API key in your host application initializer (`config/initializers/macron_cms.rb`):

```ruby
Macron::Cms.configure do |config|
  config.api_key = ENV["MACRON_CMS_API_KEY"]
end
```

### Unauthorized Response (`401 Unauthorized`)

If the API key is missing or invalid:

```json
{
  "error": "Unauthorized. Missing or invalid API key."
}
```

---

## Dynamic Content Blocks & Ingestion Model

Articles in MacronCMS are composed of metadata (title, slug, background styles, SEO tags) and an ordered collection of **content blocks**.

Because content types are schema-driven and extensible, the fields accepted by each block's `payload` are determined dynamically by your content type definitions.

### Dynamic Discovery

Before submitting article content blocks, agents or clients can query [`GET /cms/api/v1/content_types`](#1-list-content-types-get-cmsapiv1content_types) to inspect available widget types and their expected fields.

### Block Structure

When submitting `content_blocks` in `POST` or `PATCH` requests, each block accepts:

| Field | Type | Description |
|---|---|---|
| `content_type` | `string` | **Required.** Name of the registered content type (e.g. `heading`, `markdown`, `image`). |
| `sort_order` | `integer` | *Optional.* Sequence order. Defaults to array position (1-indexed). |
| `payload` | `object` | *Optional.* Key-value attributes defined for that content type schema. Any attributes not part of the schema are automatically filtered out. |
| `image_url` / `file_url` / `upload_url` | `string` | *Optional.* Remote asset URL to download and attach to Active Storage on the block. |

### Remote Asset Ingestion

When `image_url`, `file_url`, or `upload_url` (or `payload.upload` containing an `http://` or `https://` URL) is provided:
1. MacronCMS initiates an HTTP download (`Macron::Cms::RemoteAssetAttacher`).
2. Maximum file size allowed is 25 MB with connection timeouts.
3. On successful download, the file is attached to the block's Active Storage `files` association.
4. If downloading fails (e.g., source host unreachable), the system gracefully stores the remote URL string directly into `payload["upload"]` as a fallback.

---

## API Endpoints

### 1. List Content Types (`GET /cms/api/v1/content_types`)

Retrieves all registered content types along with their field definitions, type converters, and featured image capabilities.

#### Request

```http
GET /cms/api/v1/content_types HTTP/1.1
Host: localhost:3000
Authorization: Bearer test-secret-key
```

#### Response (`200 OK`)

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
    },
    {
      "id": 3,
      "name": "markdown",
      "fields": [
        { "name": "content", "kind": "markdown" }
      ],
      "convertible_to": [],
      "featured_image": false
    }
  ]
}
```

#### `curl` Example

```bash
curl -X GET http://localhost:3000/cms/api/v1/content_types \
  -H "Authorization: Bearer test-secret-key"
```

---

### 2. Create or Upsert Article (`POST /cms/api/v1/articles`)

Creates a new article or updates an existing article, atomically synchronizing its metadata and ordered content blocks in a single database transaction.

#### Query / Root Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `upsert` | `boolean` | `false` | When `true`, searches for an existing article by `name`, `slug`, or `title`. If matched, updates the article and replaces its content blocks instead of creating a duplicate. |

#### Request Payload Schema

```json
{
  "upsert": false,
  "article": {
    "title": "My Article Title",
    "name": "my-article-title",
    "slug": "custom-slug",
    "meta_title": "SEO Meta Title",
    "meta_description": "SEO Meta Description",
    "background_color": "#ffffff",
    "text_color": "#18181b",
    "background_options": {
      "repeat": "no-repeat",
      "size": "cover",
      "position": "center",
      "attachment": "scroll"
    }
  },
  "content_blocks": [
    {
      "content_type": "heading",
      "sort_order": 1,
      "payload": {
        "title": "Welcome to MacronCMS",
        "level": "h2"
      }
    },
    {
      "content_type": "markdown",
      "sort_order": 2,
      "payload": {
        "content": "This is a **rich markdown** block."
      }
    },
    {
      "content_type": "image",
      "sort_order": 3,
      "payload": {
        "size": "lg"
      },
      "image_url": "https://example.com/assets/sample-photo.png"
    }
  ]
}
```

##### Field Specifications: `article`

- `title` (*String, Required*): The display title of the article.
- `name` (*String, Optional*): Unique identifier / candidate slug. If omitted, parameterized from `title` automatically.
- `slug` (*String, Optional*): URL slug managed by FriendlyId.
- `meta_title` (*String, Optional*): HTML `<title>` and Open Graph title tag.
- `meta_description` (*String, Optional*): SEO `<meta name="description">` tag.
- `background_color` (*String, Optional*): CSS color / hex string for the host view background.
- `text_color` (*String, Optional*): CSS color / hex string applied to host view typography.
- `background_options` (*Object, Optional*):
  - `repeat`: `"no-repeat" | "repeat" | "repeat-x" | "repeat-y"` (default: `"no-repeat"`)
  - `size`: `"cover" | "contain" | "auto"` (default: `"cover"`)
  - `position`: `"center" | "top" | "bottom" | "left" | "right"` (default: `"center"`)
  - `attachment`: `"scroll" | "fixed"` (default: `"scroll"`)

##### Field Specifications: `content_blocks`

An array of content block objects. When `content_blocks` is passed:
- In `POST` without `upsert`, all blocks are created in order.
- In `POST` with `upsert: true` on an existing article, existing content blocks are replaced with the incoming sequence.

#### Response (`201 Created` or `200 OK`)

- Returns `201 Created` when creating a new record.
- Returns `200 OK` when updating an existing record via `upsert: true`.

```json
{
  "article": {
    "id": 14,
    "title": "My Article Title",
    "name": "my-article-title",
    "slug": "my-article-title",
    "meta_title": "SEO Meta Title",
    "meta_description": "SEO Meta Description",
    "background_color": "#ffffff",
    "text_color": "#18181b",
    "background_options": {
      "repeat": "no-repeat",
      "size": "cover",
      "position": "center",
      "attachment": "scroll"
    },
    "featured_image": {
      "filename": "sample-photo.png",
      "content_type": "image/png",
      "byte_size": 104230,
      "url": "/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09.../sample-photo.png"
    },
    "created_at": "2026-10-29T19:30:00Z",
    "updated_at": "2026-10-29T19:30:00Z"
  },
  "content_blocks": [
    {
      "id": 31,
      "content_type": "heading",
      "sort_order": 1,
      "payload": {
        "title": "Welcome to MacronCMS",
        "level": "h2"
      }
    },
    {
      "id": 32,
      "content_type": "markdown",
      "sort_order": 2,
      "payload": {
        "content": "This is a **rich markdown** block."
      }
    },
    {
      "id": 33,
      "content_type": "image",
      "sort_order": 3,
      "payload": {
        "size": "lg"
      },
      "attached_file": {
        "filename": "sample-photo.png",
        "content_type": "image/png",
        "byte_size": 104230,
        "url": "/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBCZz09.../sample-photo.png"
      }
    }
  ]
}
```

#### Error Response (`422 Unprocessable Entity`)

Returned if validation fails or an unknown `content_type` is specified:

```json
{
  "errors": [
    "Unknown content type: 'non_existent_type'. Available types: heading, image, markdown"
  ]
}
```

Or on validation errors:

```json
{
  "errors": [
    "Title can't be blank"
  ]
}
```

#### `curl` Example

```bash
curl -X POST http://localhost:3000/cms/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-secret-key" \
  -d '{
    "upsert": true,
    "article": {
      "title": "Exploring Generative AI",
      "meta_title": "Exploring Generative AI | Guide",
      "meta_description": "An introduction to AI content generation architectures."
    },
    "content_blocks": [
      {
        "content_type": "heading",
        "payload": { "title": "Introduction", "level": "h2" }
      },
      {
        "content_type": "markdown",
        "payload": { "content": "Generative architectures are evolving rapidly..." }
      }
    ]
  }'
```

---

### 3. Retrieve Article (`GET /cms/api/v1/articles/:id`)

Fetches article metadata, featured image information, and ordered content blocks with active file attachments.

#### Path Parameters

| Parameter | Type | Description |
|---|---|---|
| `:id` | `string` or `integer` | Database numeric ID or FriendlyId slug / `name` (e.g. `14` or `my-article-title`). |

#### Request

```http
GET /cms/api/v1/articles/my-article-title HTTP/1.1
Host: localhost:3000
Authorization: Bearer test-secret-key
```

#### Response (`200 OK`)

```json
{
  "article": {
    "id": 14,
    "title": "My Article Title",
    "name": "my-article-title",
    "slug": "my-article-title",
    "meta_title": "SEO Meta Title",
    "meta_description": "SEO Meta Description",
    "background_color": "#ffffff",
    "text_color": "#18181b",
    "background_options": {
      "repeat": "no-repeat",
      "size": "cover",
      "position": "center",
      "attachment": "scroll"
    },
    "featured_image": null,
    "created_at": "2026-10-29T19:30:00Z",
    "updated_at": "2026-10-29T19:30:00Z"
  },
  "content_blocks": [
    {
      "id": 31,
      "content_type": "heading",
      "sort_order": 1,
      "payload": {
        "title": "Welcome to MacronCMS",
        "level": "h2"
      }
    }
  ]
}
```

#### Error Response (`404 Not Found`)

If no matching article exists:

```json
{
  "error": "Article not found"
}
```

#### `curl` Example

```bash
curl -X GET http://localhost:3000/cms/api/v1/articles/my-article-title \
  -H "Authorization: Bearer test-secret-key"
```

---

### 4. Update Article (`PATCH /cms/api/v1/articles/:id`)

Updates an existing article's metadata and optionally replaces its content blocks in an atomic transaction.

#### Path Parameters

| Parameter | Type | Description |
|---|---|---|
| `:id` | `string` or `integer` | Database numeric ID or FriendlyId slug / `name`. |

#### Request Payload Schema

```json
{
  "article": {
    "title": "Updated Article Title",
    "meta_description": "New updated description"
  },
  "content_blocks": [
    {
      "content_type": "markdown",
      "sort_order": 1,
      "payload": {
        "content": "Updated article markdown content replacing old blocks."
      }
    }
  ]
}
```

> [!NOTE]
> If `content_blocks` is omitted from the request body, existing content blocks remain unchanged. If `content_blocks` is supplied as an array, existing blocks are replaced with the provided array.

#### Response (`200 OK`)

Returns the serialized article with updated metadata and refreshed `content_blocks` (same structure as `GET /cms/api/v1/articles/:id`).

#### Error Responses

- `404 Not Found`: If the article cannot be found.
  ```json
  { "error": "Article not found" }
  ```
- `422 Unprocessable Entity`: If validations fail or an unknown content type is provided in `content_blocks`.
  ```json
  { "errors": ["Unknown content type: 'invalid_type'..."] }
  ```

#### `curl` Example

```bash
curl -X PATCH http://localhost:3000/cms/api/v1/articles/my-article-title \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-secret-key" \
  -d '{
    "article": {
      "meta_title": "Updated Meta Title"
    }
  }'
```

---

## Status Codes & Error Responses

| Status Code | Reason | Cause |
|---|---|---|
| `200 OK` | Success | Article retrieved, updated via `PATCH`, or updated via `POST` with `upsert: true`. Also returned for `GET /content_types`. |
| `201 Created` | Created | New article successfully created via `POST /cms/api/v1/articles`. |
| `401 Unauthorized` | Auth Failure | Missing or invalid API key. |
| `404 Not Found` | Resource Missing | Article not found by ID or slug in `GET` or `PATCH`. |
| `422 Unprocessable Entity` | Validation / Input Error | Missing required fields (such as `title`), validation errors, or referencing an unrecognized `content_type`. |

---

## Related Documentation

- [AI Article Importer & Substack Migration Guide](ai_importer_guide.md): Specialized guide for AI agents and automated scripts converting external HTML / Substack posts into MacronCMS payloads.
- [Main README](../README.md): Full MacronCMS installation, ViewComponent widget scaffolding, styling, and configuration guide.
