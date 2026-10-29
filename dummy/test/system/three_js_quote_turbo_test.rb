require "application_system_test_case"

class ThreeJsQuoteTurboTest < ApplicationSystemTestCase
  setup do
    @article = Macron::Cms::Article.create!(
      title: "3D Rotating Quotes with Turbo",
      name: "3d-rotating-quotes-with-turbo"
    )
    @quote_type = Macron::Cms::Content.find_or_create_by!(name: "three_js_quote") do |c|
      c.fields = [
        { "name" => "text", "kind" => "string" },
        { "name" => "color", "kind" => "color" }
      ]
    end
    Macron::Cms::ArticleContent.create!(
      article: @article,
      content: @quote_type,
      sort_order: 1,
      payload: {
        "text" => "Stay hungry, stay foolish.",
        "color" => "#2563eb"
      }
    )
  end

  test "mounts React Three.js quote on Turbo Drive navigation and cleans up across history restores" do
    visit root_path
    assert_text "Articles"

    # Set an in-memory marker on window to prove navigation happens via Turbo Drive without a full reload
    page.execute_script("window.__turboSessionMarker = 'alive';")

    click_link "3D Rotating Quotes with Turbo"
    assert_current_path article_path(@article)
    assert_text "3D Rotating Quotes with Turbo"
    assert_equal "alive", page.evaluate_script("window.__turboSessionMarker")

    assert_selector "figure[data-three-js-quote-card] div[data-three-js-quote-mount]"
    assert_selector "[data-three-js-scene-host], [data-three-js-fallback]"
    assert_equal 1, page.evaluate_script("window.MacronThreeJsQuote.getMountedCount()")

    if page.has_selector?("canvas[data-three-js-canvas='true']", wait: 3)
      initial_rot = page.evaluate_script("document.querySelector('[data-three-js-scene-host]')._threeQuoteDebug.getRotationX()")
      sleep 0.25
      later_rot = page.evaluate_script("document.querySelector('[data-three-js-scene-host]')._threeQuoteDebug.getRotationX()")
      assert_operator later_rot, :>, initial_rot, "Expected 3D quote mesh to rotate continuously around its X-axis"
    end

    # Navigate back via Turbo link and verify unmount cleanup ran
    click_link "Back to articles"
    assert_current_path root_path
    assert_text "Articles"
    assert_equal "alive", page.evaluate_script("window.__turboSessionMarker")
    assert_equal 0, page.evaluate_script("window.MacronThreeJsQuote.getMountedCount()")

    # Use browser Back button (Turbo restoration visit from snapshot cache) and verify clean re-mount
    page.go_back
    assert_current_path article_path(@article)
    assert_selector "canvas[data-three-js-canvas='true'], [data-three-js-fallback]", wait: 3
    assert_equal 1, page.evaluate_script("window.MacronThreeJsQuote.getMountedCount()")
    assert_equal "alive", page.evaluate_script("window.__turboSessionMarker")
  end

  test "mounts Three.js quote with Y-axis rotation and background configuration" do
    article = Macron::Cms::Article.create!(
      title: "Y Axis Quote",
      name: "y-axis-quote"
    )
    Macron::Cms::ArticleContent.create!(
      article: article,
      content: @quote_type,
      sort_order: 1,
      payload: {
        "text" => "Creativity is intelligence having fun.",
        "color" => "#10b981",
        "rotation_axis" => "y",
        "background_color" => "#0f172a",
        "background_mode" => "tile"
      }
    )

    visit article_path(article)
    assert_text "Y Axis Quote"

    assert_selector "figure[data-three-js-quote-card] div[data-three-js-quote-mount][data-rotation-axis='y'][data-background-color='#0f172a'][data-background-mode='tile']"

    if page.has_selector?("canvas[data-three-js-canvas='true']", wait: 3)
      axis = page.evaluate_script("document.querySelector('[data-three-js-scene-host]')._threeQuoteDebug.getRotationAxis()")
      assert_equal "y", axis
      mode = page.evaluate_script("document.querySelector('[data-three-js-scene-host]')._threeQuoteDebug.getBackgroundMode()")
      assert_equal "tile", mode

      initial_rot = page.evaluate_script("document.querySelector('[data-three-js-scene-host]')._threeQuoteDebug.getRotationY()")
      sleep 0.25
      later_rot = page.evaluate_script("document.querySelector('[data-three-js-scene-host]')._threeQuoteDebug.getRotationY()")
      assert_operator later_rot, :>, initial_rot, "Expected 3D quote mesh to rotate continuously around its Y-axis"
    end
  end
end
