module Kernel
  alias coral_original_require require
  
  # augment ruby's require
  def require(path)
    coral_original_require(path)
  rescue LoadError
    if $!.message =~ /#{Regexp.escape path}\z/ and repo = Coral.find(path)
      Coral.activate(repo)
      # library added to load paths; now retry require
      coral_original_require(path)
    else
      raise
    end
  end
  
  private :require
  private :coral_original_require
end
