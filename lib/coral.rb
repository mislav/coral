module Coral
  LocalReef = "#{ENV['HOME']}/.coral"
  
  autoload :Runner, 'coral/runner'
  autoload :RemoteUrl, 'coral/remote_url'
  
  def self.repos
    Dir.chdir(LocalReef) do
      Dir["*"].to_a
    end
  end
  
  def self.find(repo_name)
    repos.include?(repo_name) and Dir["#{LocalReef}/#{repo_name}/**/lib"].first
  end
  
  def self.activate(coral_dir)
    coral_dir += '/lib' unless coral_dir =~ %r{/lib$}
    $LOAD_PATH.unshift coral_dir
  end
end

unless 'coral' == File.basename($0)
  require 'coral/custom_require'
end
