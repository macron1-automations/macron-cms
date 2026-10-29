require "test_helper"

class RemoteAssetAttacherTest < ActiveSupport::TestCase
  setup do
    @article = Macron::Cms::Article.create!(title: "Service Test Article")
    @image_type = Macron::Cms::Content.find_or_create_by!(name: "image") do |c|
      c.fields = [
        { "name" => "upload", "kind" => "file" },
        { "name" => "size", "kind" => "dropdown" }
      ]
    end
    @article_content = @article.article_contents.create!(content: @image_type, payload: { "size" => "lg" })
  end

  test "gracefully falls back to payload URL on invalid host or network failure" do
    result = Macron::Cms::RemoteAssetAttacher.attach(
      article_content: @article_content,
      url: "https://invalid-non-existent-subdomain-123456.org/image.png"
    )

    assert_not result
    assert_not @article_content.files.attached?
    assert_equal "https://invalid-non-existent-subdomain-123456.org/image.png", @article_content.payload["upload"]
  end

  test "attaches image when URI.open returns valid IO" do
    fake_io = StringIO.new("fake-image-bytes")
    fake_io.define_singleton_method(:content_type) { "image/png" }

    URI.singleton_class.alias_method :original_open, :open
    URI.singleton_class.define_method(:open) { |*args, **kwargs| fake_io }
    begin
      result = Macron::Cms::RemoteAssetAttacher.attach(
        article_content: @article_content,
        url: "https://example.com/images/hero-art.png"
      )

      assert result
      assert @article_content.files.attached?
      assert_equal "hero-art.png", @article_content.files.first.filename.to_s
    ensure
      URI.singleton_class.alias_method :open, :original_open
    end
  end
end
