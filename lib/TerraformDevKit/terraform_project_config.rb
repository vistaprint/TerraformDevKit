module TerraformDevKit
  class TerraformProjectConfig
    attr_reader :name, :acronym
    
    def initialize(project_name)
      @name = project_name.gsub(' ', '-').downcase
      @acronym = project_name.scan(/\b[a-z]/i).join.upcase
    end
  end
end