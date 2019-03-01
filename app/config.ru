require 'rack'
require 'rack/contrib'
require './lib/petit'

set :root, File.dirname(__FILE__)

Petit.configure
if File.exist? './config/petit.rb'
  require './config/petit.rb'
else
  Petit.configure
end

run Petit::App