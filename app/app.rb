# encoding: utf-8

require 'sinatra/base'

class SinatraExample < Sinatra::Base

  get "/" do
    "Hello World"
  end
  
end