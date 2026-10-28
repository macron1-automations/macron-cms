require "test_helper"

class SeoHelperTest < ActionView::TestCase
  include Macron::Cms::SeoHelper
  test "cms_seo_meta sets title and head tags with fallbacks" do
    article = Macron::Cms::Article.new(title: "Default Article Title")

    cms_seo_meta(article)

    assert_equal "Default Article Title", content_for(:title)
    head_html = content_for(:head)
    assert_includes head_html, '<meta property="og:title" content="Default Article Title"'
    assert_includes head_html, '<link rel="canonical" href="http://test.host"'
    assert_includes head_html, '<meta property="og:url" content="http://test.host"'
    refute_includes head_html, 'name="description"'
    refute_includes head_html, 'property="og:description"'
  end

  test "cms_seo_meta sets custom meta title, description, and canonical url" do
    article = Macron::Cms::Article.new(
      title: "Default Title",
      meta_title: "Custom SEO Title",
      meta_description: "Custom SEO Description"
    )

    cms_seo_meta(article, canonical_url: "https://example.com/custom-canonical")

    assert_equal "Custom SEO Title", content_for(:title)
    head_html = content_for(:head)
    assert_includes head_html, '<meta name="description" content="Custom SEO Description"'
    assert_includes head_html, '<link rel="canonical" href="https://example.com/custom-canonical"'
    assert_includes head_html, '<meta property="og:title" content="Custom SEO Title"'
    assert_includes head_html, '<meta property="og:description" content="Custom SEO Description"'
    assert_includes head_html, '<meta property="og:url" content="https://example.com/custom-canonical"'
  end

  test "cms_seo_meta returns nil so it does not render inline text" do
    article = Macron::Cms::Article.new(title: "Article")
    result = cms_seo_meta(article)
    assert_nil result
  end

  test "cms_seo_meta handles nil record gracefully" do
    assert_nil cms_seo_meta(nil)
  end
end
