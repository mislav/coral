module Kernel
  alias coral_original_require require

  # Augment Ruby's require
  #
  def require(path)
    if defined? ::Gem
      gem_original_require(path)
    else
      coral_original_require(path)
    end
  rescue LoadError => load_error
    if load_error.message =~ /\A[Nn]o such file to load -- #{Regexp.escape path}\z/ and
        coral_dir = Coral.find(path)
      Coral.activate(coral_dir)
      # library added to load paths; now retry require
      if defined? ::Gem
        gem_original_require(path)
      else
        coral_original_require(path)
      end
    elsif defined? ::Gem
      # try load with RubyGems
      coral_original_require(path)
    else
      raise load_error
    end
  end
end
