module Coral
  class Index < ::Hash
    attr_reader :reef, :file
    
    def initialize(local_reef)
      @reef = local_reef
      @file = "#{reef}/index.yml"
      
      if File.exists?(file)
        self.replace YAML::load(File.open(file))
      end
    end
    
    def to_hash
      {}.update(self)
    end
    
    def find_repo(repo_name)
      key?(repo_name) and "#{repo_name}/#{self[repo_name].first}"
    end
    
    def add(remote)
      (self[remote.project] ||= []) << remote.fork
      dump!
    end
    
    def dump!
      File.open(file, 'w') do |index_file|
        index_file << YAML::dump(self.to_hash)
      end
    end
    
    def reindex
      Dir.chdir reef do
        index = Dir["*/*"].inject({}) do |all, dir|
          repo, branch = dir.split("/", 2)
          (all[repo] ||= []) << branch
          all
        end
        self.replace index
      end
    end
    
    def reindex!
      reindex
      dump!
    end
    
    def coral_path(polyp)
      "#{reef}/#{polyp.project}/#{polyp.fork}"
    end
  end
end