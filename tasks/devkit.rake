require 'fileutils'
require 'TerraformDevKit'

TDK = TerraformDevKit

raise 'ROOT_PATH is not defined' if defined?(ROOT_PATH).nil?
BIN_PATH = File.join(ROOT_PATH, 'bin')

# Ensure terraform is in the PATH
ENV['PATH'] = TDK::OS.join_env_path(
  TDK::OS.convert_to_local_path(BIN_PATH),
  ENV['PATH']
)

def destroy_if_fails(env)
  yield
rescue StandardError => e
  puts "ERROR: #{e.message}"
  puts e.backtrace.join("\n")
  task('destroy').invoke(env.name) if env.local_backend?
  raise
end

def get_lock_table(env, project_config)
    aws_config = TDK::AwsConfig.new(TDK::Configuration.get('aws'))
    dynamo_db = TDK::DynamoDB.new(
      aws_config.credentials,
      aws_config.region
    )
    s3 = TDK::S3.new(
      aws_config.credentials,
      aws_config.region
    )
    TDK::TerraformLockTable.new(dynamo_db, s3)
end

desc 'Prepares the environment to create the infrastructure'
task :prepare, [:env] do |_, args|
  puts "== Configuring environment #{args.env}"
  env = TDK::Environment.new(args.env)

  config_file = "config/config-#{env.config}.yml"
  puts "== Loading configuration from #{config_file}"
  TDK::Configuration.init(config_file)
  
  TDK::TerraformInstaller.install_local(
    TDK::Configuration.get('terraform-version'),
    directory: BIN_PATH
  )
  
  project_config = TDK::TerraformProjectConfig.new(
      TDK::Configuration.get('project-name')
    )
  TDK::TerraformConfigManager.setup(env, project_config)

  unless env.local_backend?
    puts "== Initializing remote state"    
    terraform_lock_table = get_lock_table(env, project_config)
    terraform_lock_table.create_lock_table_if_not_exists(env, project_config) 
  end

  if Rake::Task.task_defined?('custom_prepare')
    task('custom_prepare').invoke(args.env)
  end

  TDK::Command.run(
    'terraform init -upgrade=false',
    directory: env.working_dir,
    close_stdin: false
  )

  cmd  = 'terraform get'
  cmd += ' -update=true' if TDK::TerraformConfigManager.update_modules?
  TDK::Command.run(cmd, directory: env.working_dir)
end

desc 'Shows the plan to create the infrastructure'
task :plan, [:env] => :prepare do |_, args|
  env = TDK::Environment.new(args.env)
  TDK::Command.run('terraform plan', directory: env.working_dir)
end

desc 'Creates the infrastructure'
task :apply, [:env, :force] => :prepare do |_, args|
  args.with_defaults(force: 'false')
  env = TDK::Environment.new(args.env)

  cmd = 'terraform apply'
  cmd += ' -auto-approve' if env.local_backend? or args.force

  destroy_if_fails(env) do
    TDK::Command.run(cmd, directory: env.working_dir)
  end
end

desc 'Tests a local environment'
task :test, [:env] do |_, args|
  env = TDK::Environment.new(args.env)
  env.local_backend? || (raise 'Testing is only allowed for local environments')

  task('apply').invoke(env.name, true)

  destroy_if_fails(env) do
    if Rake::Task.task_defined?('custom_test')
      task('custom_test').invoke(args.env)
    end
  end
end

desc 'Creates the infrastructure and run the tests' 
task :preflight, [:teardown] do |_, args|
  args.with_defaults(teardown: 'true')
  env = TDK::Environment.new(TDK::Environment.temp_name)
  task('test').invoke(env.name)
  task('clean').invoke(env.name) if args.teardown == 'true'
end

desc 'Destroys the infrastructure'
task :destroy, [:env] => :prepare do |_, args|
  env = TDK::Environment.new(args.env)
  cmd = 'terraform destroy'
  cmd += ' -force' if env.local_backend?
  TDK::Command.run(cmd, directory: env.working_dir, close_stdin: false)
  if Rake::Task.task_defined?('custom_destroy')
    task('custom_destroy').invoke(args.env)
  end

  unless env.local_backend?
    puts '!!!! WARNING !!!!'
    puts 'You are about to destroy a remote state. Are you sure you want to proceed? (yes/NO). Only yes will be accepted'
    response = STDIN.gets.strip
    if response == 'yes'
      project_config = TDK::TerraformProjectConfig.new(
        TDK::Configuration.get('project-name')
      )
      terraform_lock_table = get_lock_table(env, project_config)
      terraform_lock_table.destroy_lock_table(env, project_config) 
    end
  end
end

desc 'Cleans an environment (infrastructure is destroyed too)'
task :clean, [:env] => :destroy do |_, args|
  env = TDK::Environment.new(args.env)
  puts "Deleting environment #{env.name}"
  FileUtils.rm_rf(env.working_dir, secure: true)
end
