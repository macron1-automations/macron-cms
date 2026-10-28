module Macron
  module Cms
    class Content < ApplicationRecord
      validates :name, presence: true, uniqueness: true

      has_many :article_contents, class_name: "Macron::Cms::ArticleContent", dependent: :destroy
      has_many :articles, through: :article_contents
    end
  end
end
