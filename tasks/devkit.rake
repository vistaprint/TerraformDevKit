require 'fileutils'
require 'rainbow'
require 'TerraformDevKit'

TDK = TerraformDevKit

raise 'ROOT_PATH is not defined' if defined?(ROOT_PATH).nil?
BIN_PATH = File.join(ROOT_PATH, 'bin')
CONFIG_FILE ||= File.join(ROOT_PATH, 'config', 'config-%s.yml')

# Ensure terraform is in the PATH
ENV['PATH'] = TDK::OS.join_env_path(
  TDK::OS.convert_to_local_path(BIN_PATH),
  ENV['PATH']
)

PLAN_FILE = 'plan.tfplan'.freeze

def destroy_if_fails(env, task)
  yield
rescue Exception => e
  puts "ERROR: #{e.message}"
  puts e.backtrace.join("\n")
  Rake::Task[task_in_current_namespace('destroy', task)].invoke(env.name) if env.local_backend?
  raise
end

def invoke_if_defined(task_name, env)
  Rake::Task[task_name].invoke(env) if Rake::Task.task_defined?(task_name)
end

def remote_state
  aws_config = TDK::AwsConfig.new(TDK::Configuration.get('aws'))
  dynamo_db = TDK::DynamoDB.new(
    aws_config.credentials,
    aws_config.region
  )
  s3 = TDK::S3.new(
    aws_config.credentials,
    aws_config.region
  )
  TDK::TerraformRemoteState.new(dynamo_db, s3)
end

desc 'Prepares the environment to create the infrastructure'
task :prepare, [:env] do |_, args|
  puts "== Configuring environment #{args.env}"
  env = TDK::Environment.new(args.env)

  config_file = CONFIG_FILE % env.config
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
    puts '== Initializing remote state'
    remote_state.init(env, project_config)
  end

  invoke_if_defined(task_in_current_namespace('custom_prepare', task), args.env)

  if File.exist?(File.join(env.working_dir, '.terraform'))
    get_cmd  = 'terraform get'
    get_cmd += ' -update=true' if TDK::TerraformConfigManager.update_modules?
    TDK::Command.run(get_cmd, directory: env.working_dir)
  else
    init_cmd  = 'terraform init'
    init_cmd += ' -upgrade=false' unless TDK::TerraformConfigManager.update_modules?

    TDK::Command.run(init_cmd, directory: env.working_dir)
  end
end

desc 'Shows the plan to create the infrastructure'
task :plan, [:env] => :prepare do |_, args|
  env = TDK::Environment.new(args.env)
  TDK::Command.run("terraform plan -out=#{PLAN_FILE}", directory: env.working_dir)
end

desc 'Creates the infrastructure'
task :apply, [:env] => :prepare do |task, args|
  invoke_if_defined(task_in_current_namespace('pre_apply', task), args.env)

  env = TDK::Environment.new(args.env)

  Rake::Task[task_in_current_namespace('plan', task)].invoke(env.name)

  unless env.local_backend?
    puts Rainbow("Are you sure you want to apply the above plan?\n" \
                 "Only 'yes' will be accepted.").green
    response = STDIN.gets.strip
    unless response == 'yes'
      raise "Apply cancelled because response was not 'yes'.\n" \
            "Response was: #{response}"
    end
  end

  destroy_if_fails(env, task) do
    TDK::Command.run("terraform apply \"#{PLAN_FILE}\"", directory: env.working_dir)
  end

  invoke_if_defined(task_in_current_namespace('post_apply', task), args.env)
end

desc 'Tests a local environment'
task :test, [:env] do |task, args|
  env = TDK::Environment.new(args.env)
  env.local_backend? || (raise 'Testing is only allowed for local environments')

  Rake::Task[task_in_current_namespace('apply', task)].invoke(env.name, true)

  destroy_if_fails(env, task) do
    invoke_if_defined(task_in_current_namespace('custom_test', task), args.env)
  end
end

desc 'Creates the infrastructure and runs the tests'
task :preflight, [:prefix, :teardown] do |task, args|
  args.with_defaults(teardown: 'true')
  args.with_defaults(prefix: TDK::Environment.temp_name)
  env = TDK::Environment.new(args.prefix)

  Rake::Task[task_in_current_namespace('test', task)].invoke(env.name)
  Rake::Task[task_in_current_namespace('clean', task)].invoke(env.name) if args.teardown == 'true'
end

def task_in_current_namespace(task_name, current_task)
  if current_task.scope.path.to_s.empty?
    return task_name
  end

  return "#{current_task.scope.path}:#{task_name}"
end

desc 'Destroys the infrastructure'
task :destroy, [:env] => :prepare do |_, args|
  invoke_if_defined('pre_destroy', args.env)

  env = TDK::Environment.new(args.env)
  cmd = 'terraform destroy'

  unless env.local_backend?
    puts Rainbow("\n\n!!!! WARNING !!!!\n\n" \
                 "You are about to destroy #{env.name} and its remote state.\n" \
                 "Are you sure you want to proceed?\n" \
                 "Only 'yes' will be accepted.").red.bright
    response = STDIN.gets.strip

    unless response == 'yes'
      raise "Destroy cancelled because response was not 'yes'.\n" \
           "Response was: #{response}"
    end
  end
  
  cmd += ' -force'

  TDK::Command.run(cmd, directory: env.working_dir)
  invoke_if_defined('pre_destroy', args.env)

  unless env.local_backend?
    project_config = TDK::TerraformProjectConfig.new(
      TDK::Configuration.get('project-name')
    )
    remote_state.destroy(env, project_config)
  end

  invoke_if_defined('post_destroy', args.env)
end

desc 'Cleans an environment (infrastructure is destroyed too)'
task :clean, [:env] => :destroy do |_, args|
  env = TDK::Environment.new(args.env)
  puts "Deleting environment #{env.name}"
  FileUtils.rm_rf(env.working_dir, secure: true)
end
