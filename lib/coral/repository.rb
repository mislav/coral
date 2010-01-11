module Coral
  class Repository
    FORMAT = %r{
      ^( git(?:://|@)github\.com [/:] )? # github url
      (?: ([^/]+) /)? # username
      (.+?) # repository name
      (?:\.git)?$ # git suffix
    }x
    
    def self.parse(string)
      string = string.strip
      if string =~ FORMAT
        repo = new($3, $2)
        repo.clone_url = string if $1
        repo
      end
    end
    
    attr_reader :name, :version
    attr_writer :clone_url
    
    def initialize(name, version = nil)
      @name, @version = name, version
    end
    
    def path
      "#{@name}-#{@version}"
    end
    
    def clone_url
      @clone_url || "git://github.com/#{@version}/#{@name}.git"
    end
  end
end

if $0 == __FILE__
  require 'spec/autorun'
  
  describe Coral::Repository do
    context "just name" do
      subject { described_class.parse('will_paginate') }
      its(:path) { should == 'will_paginate-' }
      it "should search github to find out the username"
      it "should get clone url from github search"
    end
    
    context "name and username" do
      subject { described_class.parse('mislav/will_paginate') }
      its(:path) { should == 'will_paginate-mislav' }
      its(:version) { should == 'mislav' }
      its(:clone_url) { should == 'git://github.com/mislav/will_paginate.git' }
    end
    
    context "public github url" do
      subject { described_class.parse('git://github.com/mislav/will_paginate.git') }
      its(:path) { should == 'will_paginate-mislav' }
      its(:version) { should == 'mislav' }
      its(:clone_url) { should == 'git://github.com/mislav/will_paginate.git' }
    end
    
    context "private github url" do
      subject { described_class.parse('git@github.com:mislav/will_paginate.git') }
      its(:path) { should == 'will_paginate-mislav' }
      its(:version) { should == 'mislav' }
      its(:clone_url) { should == 'git@github.com:mislav/will_paginate.git' }
    end
  end
end
