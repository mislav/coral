require 'yaml'

module Coral
  class Index < ::Hash
    attr_reader :file
    
    def initialize(local_reef)
      @file = local_reef + 'index.yml'
      if File.exists?(file)
        self.replace YAML::load(File.open(file))
      end
    end
    
    def to_hash
      {}.update(self)
    end
    
    def find_repo(name, version = nil)
      if versions = self[name]
        if version
          return nil unless versions.include? version
        else
          version = versions.first
        end
        Repository.new(name, version)
      end
    end
    
    def add!(repo)
      (self[repo.name] ||= []) << repo.version
      dump!
    end
    
    def remove!(repo)
      self[repo.name].delete(repo.version)
      dump!
    end
    
    def dump!
      File.open(file, 'w') do |index_file|
        index_file << YAML::dump(self.to_hash)
      end
    end
  end
end