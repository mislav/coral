require 'yaml'

module Coral
  LocalReef = (ENV['CORAL_REEF'] || "#{ENV['HOME']}/.coral")
  
  autoload :Runner, 'coral/runner'
  autoload :Polyp,  'coral/polyp'
  autoload :Index,  'coral/index'
  
  def self.repos
    index.keys
  end
  
  def self.index
    @index ||= Index.new LocalReef
  end
  
  def self.find(repo_name)
    index.find_repo(repo_name)
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

ENV['CORAL'].split(',').each do |lib|
  repo = Coral.find(lib)
  raise LoadError, "can't find #{lib.inspect} with Coral" unless repo
  Coral.activate(repo)
end if ENV['CORAL']
