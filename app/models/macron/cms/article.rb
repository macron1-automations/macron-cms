module Macron
  module Cms
    class Article < ApplicationRecord
      extend FriendlyId
      friendly_id :name, use: :slugged

      validates :title, presence: true
      validates :name, presence: true, uniqueness: true
    end
  end
end
