require 'bundler/capistrano'
require 'capistrano-rbenv'
set :rbenv_ruby_version, '2.0.0-p195'

def validate_env(*env_keys)
  raise RuntimeError.new("Necessary ENVs are not defined") unless ENV.values_at(*env_keys).all?
end

validate_env(*%w(
  DEPLOY_USER
  DEPLOY_SERVER
  DEPLOY_TO_DIR
  SHIITA_USER
  SHIITA_GROUP
  DATABASE_URI
  GOOGLE_KEY
  GOOGLE_SECRET
  REMOTE_SHIITA_DOMAIN
))


set :application, "shiita"
set :use_sudo, true
set :user, ENV["DEPLOY_USER"]
set :deploy_to, ENV["DEPLOY_TO_DIR"]
set :rails_env, "production"
set :rake, "rake RAILS_ENV=#{rails_env}"
server ENV["DEPLOY_SERVER"], :web, :app, :db, primary: true
set :default_environment, {
  "SHIITA_USER" => ENV["SHIITA_USER"],
  "SHIITA_GROUP" => ENV["SHIITA_GROUP"],
  "DATABASE_URI" => ENV["DATABASE_URI"],
  "GOOGLE_KEY" => ENV["GOOGLE_KEY"],
  "GOOGLE_SECRET" => ENV["GOOGLE_SECRET"],
  "SHIITA_DOMAIN" => ENV["REMOTE_SHIITA_DOMAIN"],
  "RBENV_ROOT" => "#{rbenv_path}",
  "PATH" => "#{rbenv_path}/shims:#{rbenv_path}/bin:$PATH"
}


set :scm, :git
set :branch, (ENV["SHIITA_BRANCH"] || "master")
set :repository, (ENV["SHIITA_REPOSITORY"] || "https://github.com/taiki45/shiita.git")
set :deploy_via, :remote_cache
set :bundle_without, [:development, :test]
set :keep_releases, 5

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"


namespace :setup do
  task :fix_permissions do
    try_sudo "chown -R #{user}.#{user} #{deploy_to}"
  end
end
after "deploy:setup", "setup:fix_permissions"

namespace :deploy do

  desc "Start unicorn server"
  task :start, :roles => :app do
    run "cd #{current_path} && bundle exec unicorn_rails -c config/unicorn.conf -E #{rails_env} -D"
  end

  desc "Restart unicorn server"
  task :restart, :roles => :app do
    if File.exist? "tmp/pids/unicorn.pid"
      run "cd #{current_path} && kill -s USR2 `cat tmp/pids/unicorn.pid`"
    end
  end

  desc "Stop unicorn server"
  task :stop, :roles => :app do
    run "cd #{current_path} && kill -s QUIT `cat tmp/pids/unicorn.pid`"
  end

  desc "Ensure indexes for MongoDB"
  task :create_indexes, :roles => :db do
    run "cd #{current_path} && #{rake} db:mongoid:create_indexes"
  end
  before "deploy:restart", "deploy:create_indexes"

end