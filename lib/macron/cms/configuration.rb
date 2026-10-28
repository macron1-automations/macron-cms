module Macron
  module Cms
    class Configuration
      attr_accessor :user_class, :admin_flag, :content_types_path

      def initialize
        @user_class = "User"
        @admin_flag = :admin
        @content_types_path = nil
      end

      def devise_scope
        user_class.to_s.underscore.to_sym
      end

      def authenticate_method
        :"authenticate_#{devise_scope}!"
      end

      def current_user_method
        :"current_#{devise_scope}"
      end
    end
  end
end
