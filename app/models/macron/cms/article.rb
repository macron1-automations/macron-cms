module Macron
  module Cms
    class Article < ApplicationRecord
      validates :title, presence: true
    end
  end
end
