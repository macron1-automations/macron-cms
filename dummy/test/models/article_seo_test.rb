require "test_helper"

class ArticleSeoTest < ActiveSupport::TestCase
  test "seo_title returns meta_title when present" do
    article = Macron::Cms::Article.new(title: "Default Title", meta_title: "Custom SEO Title")
    assert_equal "Custom SEO Title", article.seo_title
  end

  test "seo_title falls back to title when meta_title is blank or nil" do
    article = Macron::Cms::Article.new(title: "Default Title", meta_title: "")
    assert_equal "Default Title", article.seo_title

    article.meta_title = nil
    assert_equal "Default Title", article.seo_title
  end

  test "seo_description returns meta_description when present" do
    article = Macron::Cms::Article.new(meta_description: "A compelling summary of the article.")
    assert_equal "A compelling summary of the article.", article.seo_description
  end

  test "seo_description returns nil when meta_description is blank or nil" do
    article = Macron::Cms::Article.new(meta_description: "")
    assert_nil article.seo_description

    article.meta_description = nil
    assert_nil article.seo_description
  end
end
