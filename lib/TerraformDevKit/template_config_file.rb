require 'mustache'

module TerraformDevKit
  class TemplateConfigFile
    def initialize(content, project, env, aws_config, extra_vars: {})
      @content = content
      @project = project
      @env = env
      @aws_config = aws_config
      @extra_vars = extra_vars
    end

    def render
      args = {
        Profile: @aws_config.fetch('profile', ''),
        Region:  @aws_config.fetch('region'),
        Environment: @env.name,
        LocalBackend: @env.local_backend?,
        ProjectName: @project.name,
        ProjectAcronym: @project.acronym
      }
      args.merge!(@extra_vars)
      Mustache.render(
        @content,
        args
      )
    end
  end
end
