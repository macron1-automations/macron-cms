require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get index and list articles" do
    article = Macron::Cms::Article.create!(title: "Test Article")

    get root_url
    assert_response :success
    assert_select "h1", "Articles"
    assert_select "li", text: /Test Article/
    assert_select "a[href=?]", article_path(article)
  end

  test "paginates articles using configured ARTICLES_PER_PAGE" do
    Macron::Cms::Article.delete_all
    7.times do |i|
      Macron::Cms::Article.create!(title: "Article #{i + 1}")
    end

    # Page 1
    get root_url
    assert_response :success
    assert_select "li.group", count: PagesController::ARTICLES_PER_PAGE
    assert_select "header span", text: /7 articles/
    assert_select "nav[aria-label='Pagination']"
    assert_select "nav[aria-label='Pagination'] a", text: /Next/

    # Page 2
    get root_url, params: { page: 2 }
    assert_response :success
    assert_select "li.group", count: 2
    assert_select "nav[aria-label='Pagination'] a", text: /Previous/
  end

  test "renders thumbnail when article has featured image" do
    image_type = Macron::Cms::Content.find_or_create_by!(name: "image") do |c|
      c.fields = [ { "name" => "upload", "kind" => "file" } ]
    end
    image_type.update!(featured_image: true)

    article_with_img = Macron::Cms::Article.create!(title: "With Image")
    block = article_with_img.article_contents.create!(content: image_type, sort_order: 1)
    file = Rack::Test::UploadedFile.new(StringIO.new("img-data"), "image/png", original_filename: "thumb.png")
    block.files.attach(file)

    article_without_img = Macron::Cms::Article.create!(title: "Without Image")

    get root_url
    assert_response :success
    assert_select "li.group a img[alt='With Image']", count: 1
    assert_select "li.group a img[alt='Without Image']", count: 0
  end
end
