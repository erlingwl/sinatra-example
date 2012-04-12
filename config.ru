require File.expand_path(File.dirname(__FILE__) + '/app/app')

run Rack::URLMap.new \
  "/"      => SinatraExample.new