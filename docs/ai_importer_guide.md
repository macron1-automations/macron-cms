# Macron CMS: AI Article Import API & Agent Guide

This guide describes how to programmatically import articles and rich content blocks into **Macron CMS** using the API (`/cms/api/v1/articles`).

> [!NOTE]
> For the comprehensive REST API endpoint schemas, request/response structures, and status codes, see the [REST API Reference](api.md).

---

## 1. API Endpoints & Authentication

### Base URL
When Macron CMS is mounted at `/cms`:
- Articles API: `/cms/api/v1/articles`
- Content Types Introspection: `/cms/api/v1/content_types`

### Authentication
Include the Bearer token or API key header in all requests:
```http
Authorization: Bearer <YOUR_MACRON_CMS_API_KEY>
```
Or via header:
```http
X-API-Key: <YOUR_MACRON_CMS_API_KEY>
```
*(In development/test environments, authentication is optional if `MACRON_CMS_API_KEY` is not set).*

---

## 2. API Request Specification

### Endpoint: `POST /cms/api/v1/articles`
Creates a new article or upserts an existing article with its ordered content blocks in a single atomic transaction.

#### Headers
```http
Content-Type: application/json
Authorization: Bearer <API_KEY>
```

#### Request Payload Schema
```json
{
  "upsert": true,
  "article": {
    "title": "String (Required) - Main title of the article",
    "name": "String (Optional) - Unique identifier/slug. Auto-generated from title if blank",
    "slug": "String (Optional) - URL slug (managed by FriendlyId)",
    "meta_title": "String (Optional) - SEO title tag",
    "meta_description": "String (Optional) - SEO meta description",
    "background_color": "String (Optional) - Hex code or CSS color",
    "text_color": "String (Optional) - Hex code or CSS color",
    "background_options": {
      "repeat": "no-repeat | repeat | repeat-x | repeat-y",
      "size": "cover | contain | auto",
      "position": "center | top | bottom | left | right",
      "attachment": "scroll | fixed"
    }
  },
  "content_blocks": [
    {
      "content_type": "heading | markdown | paragraph | image | three_js_quote | embed",
      "sort_order": 1,
      "payload": {
        "...": "Fields specific to the content type"
      },
      "image_url": "https://... (Optional - server downloads and attaches into ActiveStorage)"
    }
  ]
}
```

#### Content Block Types & Payloads
| Content Type | Payload Fields | Description |
|---|---|---|
| `markdown` | `{"content": "Markdown string"}` | Rich text, lists, bold/italics, quotes, code, links. |
| `heading` | `{"title": "Heading Text", "level": "h1"|"h2"|"h3"|"h4"|"h5"|"h6", "color": "#hex"}` | Section headings. |
| `image` | `{"size": "sm"|"md"|"lg"|"full"}` + top-level `"image_url": "https://..."` | Article images. Server downloads and attaches remote URL to ActiveStorage. |
| `three_js_quote` | `{"text": "Quote string", "color": "#hex"}` | Interactive 3D quote display. |
| `paragraph` | `{"content": "Plain text string"}` | Plain text paragraph. |

#### Idempotency & Upserting
When `"upsert": true` is specified:
1. The API checks for existing articles matching `name`, `slug`, or `title`.
2. If found, it updates the article attributes and atomically synchronizes the `content_blocks` (replacing existing blocks in sequential order).
3. If not found, it creates a new article (returning `201 Created`).

---

## 3. Substack HTML Mapping Guide

When parsing a Substack post (e.g. `*.html`):

1. **Title & SEO Metadata**:
   - Extract title from the Substack file / `posts.csv` metadata.
   - Extract subtitle as `meta_description`.
2. **Headings**:
   - Map `<h3>`, `<h2>`, `<h1>` to `heading` blocks:
     `{ "content_type": "heading", "payload": { "title": "Heading Text", "level": "h3" } }`
3. **Paragraphs, Lists, and Rich Text**:
   - Convert `<p>`, `<ul>`, `<ol>`, `<strong>`, `<em>`, `<a>` into clean Markdown.
   - Group consecutive text paragraphs into `markdown` blocks:
     `{ "content_type": "markdown", "payload": { "content": "..." } }`
4. **Images**:
   - Extract the highest-resolution image source from `<div class="captioned-image-container">` or `<figure><img src="...">`.
   - Map to an `image` block:
     `{ "content_type": "image", "payload": { "size": "lg" }, "image_url": "https://..." }`
5. **Pullquotes**:
   - Map `<div class="pullquote">` to a `three_js_quote` or `markdown` blockquote:
     `{ "content_type": "three_js_quote", "payload": { "text": "\"Quote text\" — Author" } }`

---

## 4. Prompt Template for AI Importer Agents

Pass the prompt below to an AI agent along with the Substack HTML file:

```markdown
You are an expert content migration agent. Your task is to import the provided Substack HTML article into Macron CMS using its REST API.

### Instructions:
1. Parse the attached Substack HTML document:
   - Identify the Article Title and Subtitle.
   - Deconstruct the body into a logical sequence of content blocks:
     - Headings (h1-h6) -> `heading` with `title` and `level`.
     - Text paragraphs, lists, bold, italics, links -> `markdown` with `content`.
     - Images -> `image` with `size` ("lg" or "full") and `image_url` containing the image URL.
     - Pullquotes -> `three_js_quote` with `text`.
2. Generate the JSON import payload:
   ```json
   {
     "upsert": true,
     "article": {
       "title": "<Extracted Title>",
       "name": "<parameterized-slug>",
       "meta_title": "<Extracted Title>",
       "meta_description": "<Extracted Subtitle>"
     },
     "content_blocks": [
       { "content_type": "markdown", "payload": { "content": "..." } },
       { "content_type": "heading", "payload": { "title": "...", "level": "h3" } },
       { "content_type": "image", "payload": { "size": "lg" }, "image_url": "https://..." }
     ]
   }
   ```
3. Execute the import by sending a POST request to:
   `POST http://<HOST>:<PORT>/cms/api/v1/articles`
   Headers:
   `Content-Type: application/json`
   `Authorization: Bearer <MACRON_CMS_API_KEY>`

4. Verify that the response returns HTTP 200 or 201 with the created article and attached assets.
```

---

## 5. Example cURL Call

```bash
curl -X POST http://localhost:3000/cms/api/v1/articles \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer test-secret-key" \
  -d '{
    "upsert": true,
    "article": {
      "title": "The Myth of Your Limitations: Why You’re More Capable Than You Think",
      "name": "the-myth-of-your-limitations-why",
      "meta_title": "The Myth of Your Limitations",
      "meta_description": "How a simple mindset shift can prove you wrong—in the best way possible"
    },
    "content_blocks": [
      {
        "content_type": "markdown",
        "payload": {
          "content": "We all have stories we tell ourselves—things we believe about our abilities, our potential, and our limits. “I’m not good at math.” “I can’t sing.” “I could never run a marathon.” Or one of the most common ones: “I can’t draw.”"
        }
      },
      {
        "content_type": "heading",
        "payload": {
          "title": "The Rule of Congruency: If It’s True Once, It’s Always True",
          "level": "h3"
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
