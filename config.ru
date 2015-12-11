require './lib/petit'
Petit.configure
if File.exists? ("./config/petit.rb")
  require './config/petit.rb'
else
  Petit.configure
end
run Petit::App