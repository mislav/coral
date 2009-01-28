require 'rubygems'
require 'thor'
require 'fileutils'

module Coral
  class Runner < Thor
    
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
    
    private
    
      def fileutils_options
        { :noop => options.noop?, :verbose => options.verbose? }
      end
    
  end
end
