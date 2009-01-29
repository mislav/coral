require 'uri'

module Coral
  # While a coral head appears to be a single organism, it is actually a head
  # of many individual, yet genetically identical, polyps.
  class Polyp
    attr_reader :project, :fork
    
    def initialize(project, fork)
      @project = project
      @fork    = fork
    end
    
    def self.parse(string)
      if string.index("/")
        # "project/fork" -> "project", "fork"
        new *string.split("/", 2)
      elsif string.index("-")
        # "user-project" -> "project", "user"
        new *string.split("-", 2).reverse
      else
        raise "I don't know how to parse #{string.inspect}"
      end
    end
    
    def self.parse_uri(remote_uri)
      unless remote_uri.index("://")
        remote_uri = "ssh://" + remote_uri.sub(":", "/")
      end
      uri = URI.parse remote_uri
      
      case uri.host
      when 'github.com'
        # "github.com/user/project.git" -> "project", "user"
        clean_path = uri.path.sub(/^\//, "").sub(/\.git$/, "")
        project, user = clean_path.split('/').reverse
        new(project, user)
      else
        raise "I don't know how to organize repos from #{uri.host}"
      end
    end
  end
end
