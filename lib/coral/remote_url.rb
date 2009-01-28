require 'uri'

module Coral
  class RemoteUrl
    attr_reader :host, :path
    
    def initialize(domain, path)
      @host = domain
      @path = path
      @dir  = nil
    end
    
    def clean_path
      path.sub(/^\//, "").sub(/\.git$/, "")
    end
    
    def coral_path
      case host
      when 'github.com'
        clean_path.split('/').reverse.join('/')
      else
        raise "I don't know how to organize repos from #{host}"
      end
    end
    
    def coral_dir
      @dir ||= "#{LocalReef}/#{coral_path}"
    end
    
    def self.parse(string)
      unless string.index("://")
        string = "ssh://" + string.sub(":", "/")
      end
      uri = URI.parse string
      
      new uri.host, uri.path
    end
  end
end