require 'rubygems'
gem 'mislav-thor', '~> 0.9.10'
require 'thor'
require 'fileutils'

module Coral
  class Runner < Thor
    
    desc "list", "list projects organized by Coral"
    
    def list
      puts Coral.repos.sort.join(", ")
    end
    
    desc "clone <repo-url>", "clone a repo into a local coral reef (#{LocalReef})"
    method_options :noop => :boolean, :verbose => true
    
    def clone(url)
      remote = RemoteUrl::parse(url)
      cmd %(git clone #{url} #{remote.coral_dir.inspect})
    end
    
    desc "update <repo-name>", "update a repo by pulling from upstream"
    method_options :noop => :boolean, :verbose => true
    
    def update(repo)
      unless dir = Coral.find(repo)
        abort "Failed:  couldn't find #{repo.inspect} in Coral"
      end
      
      Dir.chdir "#{LocalReef}/#{dir}" do
        cmd %(git pull)
      end
    end
    
    desc "move <repo-dir>", "move an existing repo to a local coral reef (#{LocalReef})"
    method_options :noop => :boolean, :verbose => :boolean
    
    def move(repo)
      source = File.expand_path(repo)
      source_config = "#{source}/.git/config"
      
      unless File.exists? source_config
        abort "Failed:  directory #{source.inspect} doesn't seem like a git repository"
      end
      # get the URL of the remote named "origin"
      url = `git config --file #{source_config.inspect} remote.origin.url`.chomp
      remote = RemoteUrl::parse(url)
      target = remote.coral_dir
      
      if File.exists? target
        abort "Aborted:  target #{target.inspect} already exists"
      end
      # move the repo to the new location
      FileUtils.mkdir_p(File.dirname(target), fileutils_options)
      FileUtils.mv(source, target, fileutils_options)
    end
    
    def reindex
      Dir.chdir LocalReef do
        index = Dir["*/*"].inject({}) do |all, dir|
          repo, branch = dir.split("/", 2)
          (all[repo] ||= []) << branch
          all
        end
        File.open(LocalIndex, 'w') do |file|
          file << YAML::dump(index)
        end
        puts "Coral index written to #{LocalIndex.inspect}"
      end
    end
    
    private
    
      def cmd(command)
        if options.noop?
          puts command
        elsif options.verbose?
          system command
        else
          `#{command}`
        end
      end
    
      def fileutils_options
        { :noop => options.noop?, :verbose => options.verbose? }
      end
    
  end
end
