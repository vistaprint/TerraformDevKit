module TerraformDevKit
  WARNING_MESSAGE = <<-'EOF'.freeze
__        ___    ____  _   _ ___ _   _  ____   _ _ _
\ \      / / \  |  _ \| \ | |_ _| \ | |/ ___| | | | |
 \ \ /\ / / _ \ | |_) |  \| || ||  \| | |  _  | | | |
  \ V  V / ___ \|  _ <| |\  || || |\  | |_| | |_|_|_|
   \_/\_/_/   \_\_| \_\_| \_|___|_| \_|\____| (_|_|_)
EOF

  def self.warning(env)
    puts WARNING_MESSAGE
    puts "YOU ARE OPERATING ON ENVIRONMENT #{env}"
  end
end
