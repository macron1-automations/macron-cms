require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ] do |driver_options|
    driver_options.add_argument("--enable-webgl")
    driver_options.add_argument("--ignore-gpu-blocklist")
  end
end
