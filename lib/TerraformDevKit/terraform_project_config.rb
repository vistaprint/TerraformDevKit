module TerraformDevKit
  class TerraformProjectConfig
    attr_reader :name, :acronym

    def initialize(project_name, project_acronym = nil)
      @name = project_name.tr(' ', '-').downcase
      @acronym = project_acronym || project_name.scan(/\b[a-z]/i).join.upcase
    end
  end
end
