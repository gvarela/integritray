require 'integrity'

module Integrity
  module Integritray
    module Helpers

      def xml_opts_for_project(project)
        opts = {}
        opts['name']     = project.name
        opts['category'] = project.branch
        opts['activity'] = activity(project.last_build.status) if project.last_build
        opts['webUrl']   = project_url(project)
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
          when :pending then
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

    end

    class App < Sinatra::Base

      set     :raise_errors, true
      enable  :methodoverride, :static, :sessions

      helpers Sinatra::UrlForHelper, Integrity::Helpers, Integritray::Helpers

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
