require 'fileutils'
require 'TerraformDevKit'

TDK = TerraformDevKit

BIN_PATH = File.expand_path('bin')
CONFIG_FILE ||= File.expand_path(File.join('config', 'config-%s.yml'))

# Ensure terraform is in the PATH
ENV['PATH'] = TDK::OS.join_env_path(
  TDK::OS.convert_to_local_path(BIN_PATH),
  ENV['PATH']
)

def destroy_if_fails(env, task)
  yield
rescue Exception => e
  puts "ERROR: #{e.message}"
  puts e.backtrace.join("\n")
  invoke('destroy', task, env.name) if env.local_backend?
  raise
end

def invoke(task_name, task_context, env, safe_invoke: false)
  task_in_context = task_in_current_namespace(task_name, task_context)
  should_invoke = !safe_invoke || Rake::Task.task_defined?(task_name)
  Rake::Task[task_in_context].invoke(env) if should_invoke
end

def task_in_current_namespace(task_name, current_task)
  namespace = current_task.scope.path.to_s
  namespace.empty? ? task_name : "#{namespace}:#{task_name}"
end

def remote_state
  aws_config = TDK::AwsConfig.new(TDK::Configuration.get('aws'))
  TDK::TerraformRemoteState.new(
    TDK::DynamoDB.new(aws_config.credentials, aws_config.region),
    TDK::S3.new(aws_config.credentials, aws_config.region)
  )
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

  invoke('custom_prepare', task, env.name, safe_invoke: true)

  cmd  = 'terraform init'
  cmd += ' -upgrade=false' unless TDK::TerraformConfigManager.update_modules?
  TDK::Command.run(cmd, directory: env.working_dir)
end

desc 'Shows the plan to create the infrastructure'
task :plan, [:env] => :prepare do |_, args|
  env = TDK::Environment.new(args.env)
  TDK::Command.run('terraform plan', directory: env.working_dir)
end

desc 'Creates the infrastructure'
task :apply, [:env] => :prepare do |task, args|
  env = TDK::Environment.new(args.env)

  # TODO: pre_apply takes place before running terraform apply.
  # We must prevent that for prod and test unless there is user confirmation.
  # Commenting it out until a solution is decided.

  # invoke('pre_apply', task, env.name, safe_invoke: true)

  destroy_if_fails(env, task) do
    cmd  = 'terraform apply'
    cmd += ' -auto-approve' if env.local_backend?
    TDK::Command.run(cmd, directory: env.working_dir)
  end

  invoke('post_apply', task, env.name, safe_invoke: true)
end

desc 'Tests a local environment'
task :test, [:env] do |task, args|
  env = TDK::Environment.new(args.env)
  env.local_backend? || (raise 'Testing is only allowed for local environments')

  invoke('apply', task, env.name)

  destroy_if_fails(env, task) do
    invoke('custom_test', task, env.name, safe_invoke: true)
  end
end

desc 'Creates the infrastructure and runs the tests'
task :preflight, [:prefix, :teardown] do |task, args|
  args.with_defaults(teardown: 'true')
  args.with_defaults(prefix: TDK::Environment.temp_name)
  env = TDK::Environment.new(args.prefix)

  invoke('test', task, env.name)
  invoke('clean', task, env.name) if args.teardown == 'true'
end

desc 'Destroys the infrastructure'
task :destroy, [:env] => :prepare do |task, args|
  env = TDK::Environment.new(args.env)

  # TODO: pre_destroy takes place before running terraform destroy.
  # We must prevent that for prod and test unless there is user confirmation.
  # Commenting it out until a solution is decided.

  # invoke('pre_destroy', task, env.name, safe_invoke: true)

  TDK.warning(env.name) unless env.local_backend?

  cmd  = 'terraform destroy'
  cmd += ' -force' if env.local_backend?

  TDK::Command.run(cmd, directory: env.working_dir)

  unless env.local_backend?
    project_config = TDK::TerraformProjectConfig.new(
      TDK::Configuration.get('project-name')
    )
    remote_state.destroy(env, project_config)
  end

  invoke('post_destroy', task, env.name, safe_invoke: true)
end

desc 'Cleans an environment (infrastructure is destroyed too)'
task :clean, [:env] => :destroy do |_, args|
  env = TDK::Environment.new(args.env)
  puts "Deleting environment #{env.name}"
  FileUtils.rm_rf(env.working_dir, secure: true)
end
