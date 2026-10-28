module Macron
  module Cms
    module ApplicationHelper
      def cms_current_user
        auth_user_method = Macron::Cms.configuration.current_user_method
        send(auth_user_method) if respond_to?(auth_user_method, true)
      end

      def cms_user_display_name(user)
        return "Admin" if user.nil?

        if user.respond_to?(:email) && user.email.present?
          user.email
        elsif user.respond_to?(:name) && user.name.present?
          user.name
        else
          "Admin User"
        end
      end

      def cms_nav_link_classes(is_active)
        base = "flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors"
        if is_active
          "#{base} bg-zinc-900 text-white shadow-sm"
        else
          "#{base} text-zinc-600 hover:text-zinc-900 hover:bg-zinc-100"
        end
      end

      def cms_breadcrumb(label, path = nil)
        @_cms_breadcrumbs ||= []
        @_cms_breadcrumbs << { label: label, path: path }
      end

      def cms_breadcrumbs
        @_cms_breadcrumbs ||= []
      end
    end
  end
end
