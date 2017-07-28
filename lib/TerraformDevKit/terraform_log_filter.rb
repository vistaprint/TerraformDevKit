module TerraformDevKit
  class TerraformLogFilter
    PATTERN = %r{^\d+\/\d+\/\d+ \d+:\d+:\d+ \[[A-Z]+\]}

    def self.filter(lines)
      lines.select { |line| PATTERN.match(line).nil? }
    end
  end
end
