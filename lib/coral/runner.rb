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
    
    def clone(url, name = nil)
      polyp = name ? Polyp::parse(name) : Polyp::parse_uri(url)
      coral_path = Coral.index.coral_path(polyp)
      cmd %(git clone #{url} #{coral_path.inspect})
      
      add_remote(polyp) if command_was_success?
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
    
    def move(repo, name = nil)
      source = File.expand_path(repo)
      source_config = "#{source}/.git/config"
      
      unless File.exists? source_config
        abort "Failed:  directory #{source.inspect} doesn't seem like a git repository"
      end
      # get the URL of the remote named "origin"
      url = `git config --file #{source_config.inspect} remote.origin.url`.chomp
      polyp = name ? Polyp::parse(name) : Polyp::parse_uri(url)
      target = Coral.index.coral_path(polyp)
      
      if File.exists? target
        abort "Aborted:  target #{target.inspect} already exists"
      end
      # move the repo to the new location
      FileUtils.mkdir_p(File.dirname(target), fileutils_options)
      FileUtils.mv(source, target, fileutils_options)
      
      add_remote(polyp)
      puts "Repo #{source.inspect} joined the coral colony at #{target.inspect}"
    end
    
    def reindex
      Coral.index.reindex!
      puts "Coral index written to #{Coral.index.file.inspect}"
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
      
      def command_was_success?
        $?.success?
      end
      
      def add_remote(remote)
        Coral.index.add remote unless options.noop?
      end
      
      def verbose?
        options.verbose?
      end
    
      def fileutils_options
        { :noop => options.noop?, :verbose => verbose? }
      end
    
  end
end
