require 'integrity'
require "integrity/helpers/urls"
require "integrity/helpers/authorization"
require "integrity/helpers/rendering"

module Integrity
  module Integritray
    module Helpers
      include Integrity::Helpers

      def xml_opts_for_project(project)
        opts = {}
        opts['name']     = project.name
        opts['category'] = project.branch
        opts['activity'] = activity(project.last_build.status) if project.last_build
        opts['webUrl']   = project_url(project).to_s.gsub(request.script_name, '')
        if project.last_build
          opts['lastBuildStatus'] = build_status(project.last_build.status)
          opts['lastBuildLabel']  = project.last_build.commit.short_identifier
          opts['lastBuildTime']   = project.last_build.completed_at
        end
        opts
      end

      def activity(status)
        case status
          when :success, :failed then
            'Sleeping'
          when :pending, :building then
            'Building'
          else
            'Sleeping'
        end
      end

      def build_status(status)
        case status
          when :success, :pending then
            'Success'
          when :failed then
            'Failure'
          else
            'Unknown'
        end
      end

      def authorize(user, password)
        return true unless protect?
        Integrity.app.user == user && Integrity.app.pass == password
      end

      def protect?
       Integrity.app.respond_to?(:user) && Integrity.app.respond_to?(:pass)
      end

    end

    class App < Sinatra::Base

      set     :raise_errors, true
      enable  :methodoverride, :static, :sessions

      helpers Sinatra::UrlForHelper, Integritray::Helpers

      before do
        # The browser only sends http auth data for requests that are explicitly
        # required to do so. This way we get the real values of +#logged_in?+ and
        # +#current_user+
        login_required if session[:user]
      end

      get '/projects.xml' do
        login_required if params["private"]
        builder do |xml|
          @projects = authorized? ? Project.all : Project.all(:public => true)
          response["Content-Type"] = "application/xml; charset=utf-8"
          xml.Projects do
            @projects.each do |project|
              xml.Project xml_opts_for_project(project)
            end
          end
        end
      end

    end

  end # Integritray
end # Integrity
