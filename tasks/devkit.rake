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
  invoke('destroy', task, env.name) if env.local_backend?
  raise
end

def invoke(task_name, task_context, env, safe_invoke: false)
  task_in_context = task_in_current_namespace(task_name, task_context)
  should_invoke = !safe_invoke || Rake::Task.task_defined?(task_in_context)
  Rake::Task[task_in_context].invoke(env) if should_invoke
end

def task_in_current_namespace(task_name, current_task)
  namespace = current_task.scope.path.to_s
  namespace.empty? ? task_name : "#{namespace}:#{task_name}"
end

def remote_state
  aws_config = TDK::Aws::AwsConfig.new(TDK::Configuration.get('aws'))
  dynamo_db = TDK::Aws::DynamoDB.new(
    aws_config.credentials,
    aws_config.region
  )
  s3 = TDK::Aws::S3.new(
    aws_config.credentials,
    aws_config.region
  )
  TDK::Aws::TerraformRemoteState.new(dynamo_db, s3)
end

desc 'Prepares the environment to create the infrastructure'
task :prepare, [:env] do |_, args|
  env = TDK::Environment.new(args.env)

  puts "== Configuring environment #{env.name}"

  config_file = CONFIG_FILE % env.config
  puts "== Loading configuration from #{config_file}"
  TDK::Configuration.init(config_file)

  invoke('custom_prepare', task, env.name, safe_invoke: true)

  TDK::TerraformInstaller.install_local(
    TDK::Configuration.get('terraform-version'),
    directory: BIN_PATH
  )

  project_config = TDK::ProjectConfig.new(
    TDK::Configuration.get('project-name'),
    TDK::Configuration.get('project-acronym')
  )
  TDK::TerraformConfigManager.setup(env, project_config)

  unless env.local_backend?
    puts '== Initializing remote state'
    remote_state.init(env, project_config)
  end

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
  cmd = "terraform plan -out=#{PLAN_FILE}"
  TDK::Command.run(cmd, directory: env.working_dir)
end

desc 'Creates the infrastructure'
task :apply, [:env] => :prepare do |task, args|
  env = TDK::Environment.new(args.env)

  invoke('plan', task, env.name)

  unless env.local_backend? || allow_remote_apply?
    puts Rainbow("Are you sure you want to apply the above plan?\n" \
                 "Only 'yes' will be accepted.").green
    response = STDIN.gets.strip
    unless response == 'yes'
      raise "Apply cancelled because response was not 'yes'.\n" \
            "Response was: #{response}"
    end
  end

  invoke('pre_apply', task, env.name, safe_invoke: true)

  destroy_if_fails(env, task) do
    cmd = "terraform apply \"#{PLAN_FILE}\""
    TDK::Command.run(cmd, directory: env.working_dir)
  end

  invoke('post_apply', task, env.name, safe_invoke: true)
end

def allow_remote_apply?
  aws = TDK::Configuration.get('aws')
  aws.key?('remote_apply') && aws['remote_apply']
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

  invoke('pre_destroy', task, env.name, safe_invoke: true)

  TDK::Command.run('terraform destroy -force', directory: env.working_dir)

  unless env.local_backend?
    project_config = TDK::ProjectConfig.new(
      TDK::Configuration.get('project-name'),
      TDK::Configuration.get('project-acronym')
    )
    remote_state.destroy(env, project_config)
  end

  invoke('post_destroy', task, env.name, safe_invoke: true)
end

desc 'Cleans an environment (infrastructure is destroyed too)'
task :clean, [:env] => :destroy do |_, args|
  env = TDK::Environment.new(args.env)
  puts "Deleting environment #{env.name} in #{env.working_dir}"
  TDK::ExtendedFileUtils.rm_rf(env.working_dir, secure: true)
end
