require 'thor'
require 'fileutils'

module Coral
  class Runner < Thor
    local_reef_pretty = LocalReef.to_s.sub(ENV['HOME'], '~')
    
    desc "list [<name>]", "list projects organized by Coral"
    def list(str = nil)
      keys = Coral::index.keys
      keys = keys.grep(/^#{str}/)
      
      for name in keys.sort
        versions = Coral::index[name]
        puts "#{name} (#{versions.join(', ')})"
      end
    end
    
    desc "clone <repo>", "clone a repo into a local coral reef (#{local_reef_pretty})"
    method_options :noop => :boolean, :verbose => :boolean
    def clone(name)
      repo = Repository::parse(name)
      if repo.version.nil?
        repo.guess_version_from_github
        abort %(Error: don't know how to clone "#{repo.name}") if repo.version.nil?
      end
      FileUtils.mkdir_p(LocalReef, fileutils_options)
      target_path = LocalReef + repo.path
      
      if cmd %(git clone #{repo.clone_url} "#{target_path}")
        index_add(repo)
      end
    end
    
    desc "update <repo-name> [<repo2-name> ...] [-v VERSION]", "update a repo by pulling from upstream"
    method_options [:version, '-v'] => :string, :noop => :boolean, :verbose => :boolean
    def update(*names)
      for name in names
        if repo = Coral.find(name, options.version)
          chdir(LocalReef + repo.path) do
            puts "(in #{Dir.pwd})" if options.verbose?
            cmd %(git pull)
          end
        else
          repo = name
          repo += "-#{options.version}" if options.version
          $stderr.puts %(Error: couldn't find "#{repo}")
        end
      end
    end
    
    desc "checkout <repo> <workdir-name>", "checkout a new working copy for a repository"
    method_options :noop => :boolean, :verbose => :boolean
    # inspired by "contrib/workdir/git-new-workdir" from git source
    def checkout(name, new_version)
      repo = Coral.find(name)
      abort %("#{repo.name}-#{new_version}" already exists) if Coral::index[repo.name].include? new_version
      new_repo = Repository.new(repo.name, new_version)
      links = %w(config refs logs/refs objects info hooks packed-refs remotes rr-cache svn)
      
      source_git = LocalReef + repo.path + '.git'
      target_git = LocalReef + new_repo.path + '.git'
      FileUtils.mkdir_p(target_git + 'logs', fileutils_options)
      
      for link in links
        source_path = source_git + link
        target_path = target_git + link
        FileUtils.ln_s(source_path.relative_path_from(target_path.dirname), target_path, fileutils_options)
      end
      
      FileUtils.cp(source_git + 'HEAD', target_git + 'HEAD', fileutils_options)
      puts target_git.dirname
      index_add(new_repo)
      
      chdir target_git.dirname do
        if cmd %(git rev-parse #{new_version} 2>&1)
          # checkout tag or branch
          cmd %(git checkout -q #{new_version})
        elsif cmd %(git rev-parse origin/#{new_version} 2>&1)
          # checkout a new branch to track a remote branch
          cmd %(git checkout --track origin/#{new_version})
        elsif `git remote`.split("\n").include? new_version
          # checkout a new branch to track a fork
          cmd %(git checkout --track -b #{new_version} #{new_version}/master)
        else
          cmd %(git checkout HEAD)
        end
      end
    end
    
    desc "remove <repo> <version>", "delete a working copy from filesystem"
    method_options :noop => :boolean, :verbose => :boolean
    def remove(name, version)
      unless repo = Coral.find(name, version)
        abort "Error: couldn't find #{name} in Coral"
      end
      if Coral::index[repo.name].first == repo.version
        abort %("Cannot remove: #{repo.name}-#{repo.version}" is the main version)
      end
      if FileUtils.rm_rf(LocalReef + repo.path, fileutils_options)
        index_remove(repo)
      end
    end
    
    desc "path <repo-name>", "echo the absolute path of a library"
    method_options [:version, '-v'] => :string
    def path(name)
      unless repo = Coral.find(name, options.version)
        abort "Error: couldn't find #{name} in Coral"
      end
      puts LocalReef + repo.path
    end
    
    desc "import <repo-dir>", "move an existing repo to a local coral reef (#{local_reef_pretty})"
    method_options :noop => :boolean, :verbose => :boolean
    def import(dir)
      source = Pathname.new(dir).expand_path
      source_config = source + '.git/config'
      unless source_config.exist?
        abort "Error: directory #{source.to_s.inspect} doesn't seem like a git repository"
      end
      
      # get the URL of the remote named "origin"
      url = `git config --file "#{source_config}" remote.origin.url`.chomp
      repo = Repository.parse(url)
      target = LocalReef + repo.path
      
      if target.exist?
        abort "Error: target #{target.to_s.inspect} already exists"
      end
      # move the repo to the new location
      FileUtils.mkdir_p(target.dirname, fileutils_options)
      FileUtils.mv(source, target, fileutils_options)
      
      index_add(repo)
      puts "Repo #{source.to_s.inspect} joined the coral colony at #{target.to_s.inspect}"
    end
    
    private
    
      def cmd(command)
        if options.noop?
          puts command
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
        puts "(in #{dir})" if options.verbose?
        if options.noop?
          yield if block_given?
        else
          Dir.chdir(dir, &block)
        end
      end
    
  end
end
