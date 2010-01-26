require 'yaml'
require 'net/http'
require 'cgi'

module Coral
  class Repository
    FORMAT = %r{
      ^( (?:git|http)(?:://|@)github\.com [/:] )? # github url
      (?: ([^/]+) /)? # username
      (.+?) # repository name
      (?:\.git|/)?$ # git suffix
    }x
    
    def self.parse(string)
      string = string.strip
      if string =~ FORMAT
        repo = new($3, $2)
        if $1 and (string.index('http:') != 0 or string =~ /\.git$/)
          repo.clone_url = string
        end
        repo
      end
    end
    
    attr_reader :name, :version
    attr_writer :clone_url
    
    def initialize(name, version = nil)
      @name, @version = name, version
    end
    
    def to_s
      "#{@name}@#{@version}"
    end
    
    def directory
      "#{@name}-#{@version}"
    end
    
    def path
      @path ||= LocalReef + directory
    end
    
    def git_path
      @git_path ||= path + '.git'
    end
    
    def clone_url
      @clone_url || "git://github.com/#{@version}/#{@name}.git"
    end
    
    def main?
      Coral.index[self.name].first == self.version
    end
    
    def guess_version_from_github
      results = self.class.search_github(name)
      unless results.empty?
        @name = results.first["name"]
        @version = results.first["username"]
      end
    end
    
    private
    
    def self.search_github(term)
      url = URI('http://github.com/api/v2/yaml/repos/search/' + CGI::escape(term))
      response = Net::HTTP.get_response(url)
      YAML.load(response.body)["repositories"]
    end
  end
end

if $0 == __FILE__
  require 'spec/autorun'
  require 'fakeweb'
  FakeWeb.allow_net_connect = false
  
  FakeWeb.register_uri(:get, 'http://github.com/api/v2/yaml/repos/search/will_paginate', :body => YAML.dump(
    "repositories" => [{"name" => "will_paginate", "username" => "mislav"}]
  ))
  
  describe Coral::Repository do
    context "just name" do
      subject {
        repo = described_class.parse('will_paginate')
        repo.guess_version_from_github
        repo
      }
      its(:directory) { should == 'will_paginate-mislav' }
      its(:version) { should == 'mislav' }
      its(:clone_url) { should == 'git://github.com/mislav/will_paginate.git' }
    end
    
    context "name and username" do
      subject { described_class.parse('mislav/will_paginate') }
      its(:directory) { should == 'will_paginate-mislav' }
      its(:version) { should == 'mislav' }
      its(:clone_url) { should == 'git://github.com/mislav/will_paginate.git' }
    end
    
    context "public github url" do
      subject { described_class.parse('git://github.com/mislav/will_paginate.git') }
      its(:directory) { should == 'will_paginate-mislav' }
      its(:version) { should == 'mislav' }
      its(:clone_url) { should == 'git://github.com/mislav/will_paginate.git' }
    end
    
    context "public github HTTP url" do
      subject { described_class.parse('http://github.com/mislav/will_paginate/') }
      its(:directory) { should == 'will_paginate-mislav' }
      its(:version) { should == 'mislav' }
      its(:clone_url) { should == 'git://github.com/mislav/will_paginate.git' }
    end
    
    context "public github HTTP clone url" do
      subject { described_class.parse('http://github.com/mislav/will_paginate.git') }
      its(:directory) { should == 'will_paginate-mislav' }
      its(:version) { should == 'mislav' }
      its(:clone_url) { should == 'http://github.com/mislav/will_paginate.git' }
    end
    
    context "private github url" do
      subject { described_class.parse('git@github.com:mislav/will_paginate.git') }
      its(:directory) { should == 'will_paginate-mislav' }
      its(:version) { should == 'mislav' }
      its(:clone_url) { should == 'git@github.com:mislav/will_paginate.git' }
    end
  end
end
