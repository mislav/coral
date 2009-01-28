require 'yaml'

module Coral
  LocalReef = "#{ENV['HOME']}/.coral"
  LocalIndex = "#{LocalReef}/index"
  
  autoload :Runner, 'coral/runner'
  autoload :RemoteUrl, 'coral/remote_url'
  
  def self.repos
    index.keys
  end
  
  def self.index
    @index ||= YAML::load File.open(LocalIndex)
  end
  
  def self.find(repo_name)
    repos.include?(repo_name) and "#{repo_name}/#{index[repo_name].first}"
  end
  
  def self.activate(coral_dir)
    coral_dir = "#{LocalReef}/#{coral_dir}" unless coral_dir.index('/') == 0
    coral_dir += '/lib' unless coral_dir =~ %r{/lib$}
    unless File.exists? coral_dir
      raise "Directory #{coral_dir.inspect} indexed by Coral is missing"
    end
    $LOAD_PATH.unshift coral_dir
  end
end

unless 'coral' == File.basename($0)
  require 'coral/custom_require'
end
