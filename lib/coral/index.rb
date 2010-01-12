require 'yaml'

module Coral
  class Index < ::Hash
    attr_reader :reef, :file
    
    def initialize(local_reef)
      @reef = local_reef
      @file = @reef + 'index.yml'
      if File.exists?(file)
        self.replace YAML::load(File.open(file))
      end
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
    
    def each_repo
      if @repositories
        @repositories.each { |repo| yield repo }
      else
        @repositories, repo = [], nil
        each do |name, versions|
          versions.each { |version|
            @repositories << (repo = Repository.new(name, version))
            yield repo
          }
        end
      end
    end
    
    # TODO: support paths given with extension
    def find_path(path)
      slashdex = path.index('/')
      path_fragment = nil
      
      each_repo do |repo|
        if slashdex
          path_fragment ||= path[0, slashdex]
          return repo if top_level_paths.include?("#{repo.path}/lib/#{path_fragment}") and
            File.file?(reef + "#{repo.path}/lib/#{path}.rb")
        else
          return repo if top_level_paths.include?("#{repo.path}/lib/#{path}.rb")
        end
      end
      
      return nil
    end
    
    def add!(repo)
      (self[repo.name] ||= []) << repo.version
      dump!
    end
    
    def remove!(repo)
      self[repo.name].delete(repo.version)
      dump!
    end
    
    def to_hash
      {}.update(self)
    end
    
    def dump!
      File.open(file, 'w') do |index_file|
        index_file << YAML::dump(self.to_hash)
      end
    end
    
    private
    
    def top_level_paths
      @top_level_paths ||= Dir["#{reef}/*/lib/*{,.rb,.rbw}"].map { |p| p.sub("#{reef}/", '') }.uniq
    end
  end
end