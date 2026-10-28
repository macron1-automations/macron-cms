module Macron
  module Cms
    class ApplicationController < ActionController::Base
      before_action :authenticate_cms_admin!

      private

      def authenticate_cms_admin!
        auth_method = Macron::Cms.configuration.authenticate_method
        unless respond_to?(auth_method, true)
          raise NotImplementedError, "Macron CMS requires Devise authentication helper `#{auth_method}`. Ensure Devise is configured for #{Macron::Cms.configuration.user_class}."
        end

        send(auth_method)
        return if performed?

        current_resource = send(Macron::Cms.configuration.current_user_method)
        admin_flag = Macron::Cms.configuration.admin_flag

        is_admin = if current_resource.nil?
          false
        elsif current_resource.respond_to?("#{admin_flag}?")
          current_resource.public_send("#{admin_flag}?")
        elsif current_resource.respond_to?(admin_flag)
          current_resource.public_send(admin_flag)
        else
          false
        end

        unless is_admin
          redirect_to main_app.root_path, alert: "You are not authorized to access this area."
        end
      end
    end
  end
end
