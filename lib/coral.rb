module Coral
  LocalReef = "#{ENV['HOME']}/.coral"
  
  autoload :Runner, 'coral/runner'
  autoload :RemoteUrl, 'coral/remote_url'
end
