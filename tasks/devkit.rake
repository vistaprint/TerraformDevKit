require 'fileutils'
require 'TerraformDevKit'

TDK = TerraformDevKit

raise 'ROOT_PATH is not defined' if defined?(ROOT_PATH).nil?
BIN_PATH = File.join(ROOT_PATH, 'bin')

# Ensure terraform and terragrunt are in the PATH
ENV['PATH'] = TDK::OS.join_env_path(
  TDK::OS.convert_to_local_path(BIN_PATH),
  ENV['PATH']
)

TF_CONFIG_EXTRA_VARS = {}.freeze unless defined?(TF_CONFIG_EXTRA_VARS)

def destroy_if_fails(env)
  yield
rescue StandardError => e
  puts "ERROR: #{e.message}"
  puts e.backtrace.join("\n")
  task('destroy').invoke(env.name) if env.local_backend?
  raise
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
  TDK::TerragruntInstaller.install_local(
    TDK::Configuration.get('terragrunt-version'),
    directory: BIN_PATH
  )

  TDK::TerraformConfigManager.setup(env, extra_vars: TF_CONFIG_EXTRA_VARS)

  task('custom_prepare').invoke(args.env) if Rake::Task.task_defined?('custom_prepare')

  TDK::Command.run(
    'terragrunt init',
    directory: env.working_dir,
    close_stdin: false
  )

  cmd = 'terragrunt get'
  cmd += ' -update=true' if TDK::TerraformConfigManager.update_modules?
  TDK::Command.run(cmd, directory: env.working_dir)
end

desc 'Shows the plan to create the infrastructure'
task :plan, [:env] => :prepare do |_, args|
  env = TDK::Environment.new(args.env)
  TDK::Command.run('terragrunt plan', directory: env.working_dir)
end

desc 'Creates the infrastructure'
task :apply, [:env] => :prepare do |_, args|
  env = TDK::Environment.new(args.env)
  destroy_if_fails(env) do
    TDK::Command.run('terragrunt apply', directory: env.working_dir)
  end
end

desc 'Tests a local environment'
task :test, [:env] do |_, args|
  env = TDK::Environment.new(args.env)
  raise 'Testing is only allowed for local environments' unless env.local_backend?

  task('apply').invoke(env.name)

  destroy_if_fails(env) do
    task('custom_test').invoke(args.env) if Rake::Task.task_defined?('custom_test')
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
  cmd = 'terragrunt destroy'
  cmd += ' -force' if env.local_backend?
  TDK::Command.run(cmd, directory: env.working_dir, close_stdin: false)
end

desc 'Cleans an environment (infrastructure is destroyed too)'
task :clean, [:env] => :destroy do |_, args|
  env = TDK::Environment.new(args.env)
  puts "Deleting environment #{env.name}"
  FileUtils.rm_rf(env.working_dir, secure: true)
end
