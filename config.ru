require './lib/petit'
Petit.configure
if File.exist? './config/petit.rb'
  require './config/petit.rb'
else
  Petit.configure
end

run Petit::App
