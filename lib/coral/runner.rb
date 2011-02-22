require 'thor'
require 'fileutils'

module Coral
  class Runner < Thor
    class_options [:noop, '-n'] => :boolean, [:verbose, '-v'] => :boolean
    
    local_reef_pretty = LocalReef.to_s.sub(ENV['HOME'], '~')
    
    desc "list [<pattern>]", "list projects organized by Coral"
    def list(pattern = nil)
      Coral.list(pattern) do |name, versions|
        versions.unshift shell.set_color(versions.shift, :blue, true)
        say "#{name} (#{versions.join(', ')})"
      end
    end
    
    desc "clone <repository>", "clone a repo into a local coral reef (#{local_reef_pretty})"
    def clone(name)
      repo = Repository.parse(name)
      if repo.version.nil?
        repo.guess_version_from_github
        error %(don't know how to clone "#{repo.name}") if repo.version.nil?
      end
      FileUtils.mkdir_p(LocalReef, fileutils_options)
      
      if cmd %(git clone #{repo.clone_url} "#{repo.path}")
        index_add(repo)
      end
    end
    
    desc "update <name> [<name2> ...]", "update a repo by pulling from upstream"
    def update(*names)
      for name in names
        if repo = Coral.find(name)
          chdir repo.path do
            cmd %(git pull)
          end
        else
          error %(couldn't find "#{name}")
        end
      end
    end
    
    desc "checkout <name> <workdir-name>", "checkout a new working copy for a repository"
    # inspired by "contrib/workdir/git-new-workdir" from git source
    def checkout(name, new_version)
      repo = Coral.find(name)
      if existing = Coral.find(repo.name, new_version)
        error %("#{existing}" already exists)
      end
      new_repo = Repository.new(repo.name, new_version)
      
      for link in %w(config refs logs/refs packed-refs objects info hooks)
        source_path = repo.git_path + link
        target_path = new_repo.git_path + link
        target_dir = target_path.dirname
        FileUtils.mkdir_p(target_dir, fileutils_options) unless target_dir.exist?
        FileUtils.ln_s(source_path.relative_path_from(target_dir), target_path, fileutils_options)
      end

      for copy in %w(HEAD description)
        source_path = repo.git_path + copy
        FileUtils.cp(source_path, new_repo.git_path + copy, fileutils_options) if source_path.exist?
      end
      
      say new_repo.path
      index_add(new_repo)
      
      chdir new_repo.path do
        if cmd %(git rev-parse #{new_repo.version} 2>&1)
          # checkout tag or branch
          cmd %(git checkout -q #{new_repo.version})
        elsif cmd %(git rev-parse origin/#{new_repo.version} 2>&1)
          # checkout a new branch to track a remote branch
          cmd %(git checkout --track origin/#{new_repo.version})
        elsif `git remote`.split("\n").include? new_repo.version
          # checkout a new branch to track a fork
          cmd %(git checkout --track -b #{new_repo.version} #{new_repo.version}/master)
        else
          cmd %(git checkout HEAD)
        end
      end
    end
    
    desc "remove <name>", "delete a working copy from filesystem"
    def remove(name)
      repo = Coral.find(name)
      error %(couldn't find "#{name}" in Coral) unless repo
      error %(cannot remove "#{repo}", it's the main version) if repo.main?
      if FileUtils.rm_rf(repo.path, fileutils_options)
        index_remove(repo)
      end
    end
    
    desc "path <name>", "echo the absolute path of a library"
    def path(name)
      repo = Coral.find(name)
      error "couldn't find #{name} in Coral" unless repo
      say repo.path
    end
    
    desc "import <dir>", "move an existing repo to a local coral reef (#{local_reef_pretty})"
    def import(dir)
      source = Pathname.new(dir).expand_path
      source_config = source + '.git/config'
      unless source_config.exist?
        error "directory #{source.to_s.inspect} doesn't seem like a git repository"
      end
      
      # get the URL of the remote named "origin"
      url = `git config --file "#{source_config}" remote.origin.url`.chomp
      repo = Repository.parse(url)
      error "target #{repo.path.to_s.inspect} already exists" if repo.path.exist?
      
      # move the repo to the new location
      FileUtils.mkdir_p(repo.path.dirname, fileutils_options)
      FileUtils.mv(source, repo.path, fileutils_options)
      
      index_add(repo)
      say "Repo #{source.to_s.inspect} joined the coral colony at #{repo.path.to_s.inspect}"
    end
    
    class << self
      protected
      
      def banner(task)
        "coral " + task.formatted_usage(self, false)
      end
    end
    
    private
    
      def cmd(command)
        if options.noop?
          say command
        elsif options.verbose?
          system command
        else
          `#{command}`
          $?.success?
        end
      end
      
      def index_add(repo)
        Coral.index.add!(repo) unless options.noop?
      end
      
      def index_remove(repo)
        Coral.index.remove!(repo) unless options.noop?
      end
      
      def fileutils_options
        @fileutils_options ||= { :noop => options.noop?, :verbose => options.verbose? }
      end
      
      def chdir(dir, &block)
        say "(in #{dir})" if options.verbose?
        if options.noop?
          yield if block_given?
        else
          Dir.chdir(dir, &block)
        end
      end
      
      def error(msg)
        raise Thor::Error, "Error: #{msg}"
      end
    
  end
end
