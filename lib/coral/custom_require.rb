module Kernel
  if defined? ::Gem
    alias coral_original_require gem_original_require
  else                          
    alias coral_original_require require
  end

  ## Augment ruby's require
  def require(path)
    coral_original_require(path)
  rescue LoadError => load_error
    if load_error.message =~ /\A[Nn]o such file to load -- #{Regexp.escape path}\z/ and
        coral_dir = Coral.find(path)
      Coral.activate(coral_dir)
      # library added to load paths; now retry require
      coral_original_require(path)
    else
      raise load_error
    end
  end
end
