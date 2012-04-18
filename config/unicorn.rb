# Unicorn configuration

APP_ROOT = File.expand_path '../', File.dirname(__FILE__)

worker_processes 10

preload_app true

working_directory APP_ROOT

pid "/var/www/demo/shared/tmp/pids/unicorn.pid"

timeout 30

listen '/var/www/demo/shared/tmp/sockets/unicorn.sock', :backlog => 2048

stderr_path "#{APP_ROOT}/log/unicorn.stderr.log"
stdout_path "#{APP_ROOT}/log/unicorn.stdout.log"

before_fork do |server, worker|
  old_pid = "/var/www/demo/shared/tmp/pids/unicorn.pid.oldbin"

  if File.exists?(old_pid) && server.pid != old_pid
    begin
      Process.kill("QUIT", File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
      # someone else did our job for us
    end
  end
end