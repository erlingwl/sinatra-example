set :application, "demo"
set :repository,  "git://github.com/erlingwl/sinatra-example.git"
set :deploy_to, "/var/www/#{application}"

set :scm, :git
set :deploy_via, :remote_cache

ssh_options[:forward_agent] = true
default_run_options[:pty] = true

set :branch, "origin/chef"
set :user, 'ubuntu'

role :web, ENV["WEBSERVER"]
role :app, ENV["WEBSERVER"]                          

namespace :deploy do
  desc "Deploy it"
  task :default do
    update
    bundle
    restart
  end

  desc "Setup a GitHub-style deployment."
  task :setup, :except => { :no_release => true } do
    run "rm -rf #{current_path}"
    run "git clone #{repository} #{current_path}"
    run "cd #{current_path}; git checkout -b chef #{branch}"
    run "mkdir -p #{current_path}/log"
    run "mkdir -p #{shared_path}/tmp/pids"
    run "mkdir -p #{shared_path}/tmp/sockets"
    run "chmod +w #{current_path}/log"
  end
  
  desc "Log dir"
  task :log_dir, :except => { :no_release => true } do
    run "mkdir -p #{current_path}/log"
  end
  
  desc "Bundle install"
  task :bundle, :except => { :no_release => true } do
    run "cd #{current_path}; bundle install --without development test"
  end

  desc "Update the deployed code."
  task :update_code, :except => { :no_release => true } do
    run "cd #{current_path}; git pull; git reset --hard #{branch}"
  end
  
  desc "Symlink"
  task :symlink, :except => { :no_release => true } do
    sudo "ln -sf #{current_path}/config/default /etc/nginx/sites-enabled/default"
  end
  
end

set :unicorn_pid, "#{shared_path}/tmp/pids/unicorn.pid"

namespace :unicorn do
  desc "start unicorn"
  task :start, :roles => :app, :except => { :no_release => true } do 
    run "cd #{current_path} && RACK_ENV=production bundle exec unicorn -c #{current_path}/config/unicorn.rb -E production -D"
  end
  desc "stop unicorn"
  task :stop, :roles => :app, :except => { :no_release => true } do 
    run "kill `cat #{unicorn_pid}`"
  end
  desc "graceful stop unicorn"
  task :graceful_stop, :roles => :app, :except => { :no_release => true } do
    run "kill -s QUIT `cat #{unicorn_pid}`"
  end
  desc "reload unicorn"
  task :reload, :roles => :app, :except => { :no_release => true } do
    run "kill -s USR2 `cat #{unicorn_pid}`"
  end
  desc "restart:unicorn"
  task :restart, :roles => :app, :except => {:no_release => true} do
    run "kill -s QUIT `cat #{unicorn_pid}`"
    run "cd #{current_path} && RACK_ENV=production bundle exec unicorn -c #{current_path}/config/unicorn.rb -E production -D"
  end
  desc "tail the error log"
  task :tail_error, :roles => :app, :except => { :no_release => true } do
    run "tail -100f #{current_path}/log/unicorn.stderr.log"
  end
  desc "tail the error log"
  task :tail_standard, :roles => :app, :except => { :no_release => true } do
    run "tail -100f #{current_path}/log/unicorn.stdout.log"
  end

  after "deploy:restart", "unicorn:restart"
end

namespace :nginx do
  desc "restart nginx"
  task :restart, :roles => :app, :except => { :no_release => true } do
    sudo "/etc/init.d/nginx restart"
  end
  
  desc "stop nginx"
  task :stop, :roles => :app, :except => { :no_release => true } do
    sudo "/etc/init.d/nginx stop"
  end
  
  desc "start nginx"
  task :start, :roles => :app, :except => { :no_release => true } do
    sudo "/etc/init.d/nginx start"
  end
  
  desc "nginx status"
  task :status, :roles => :app, :except => { :no_release => true } do
    sudo "/etc/init.d/nginx status"
  end
  
  desc "tail logs"
  task :tail, :roles => :app do
    run "tail -100f /var/log/nginx/access.log"
  end
  desc "tail error logs"
  task :tail_error, :roles => :app do
    run "tail -100f /var/log/nginx/error.log"
  end
end