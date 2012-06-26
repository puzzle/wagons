class Object
  # Requires the specified argument but silently ignores any LoadErrors.
  def require_optional(*args)
    require *args
  rescue LoadError
    # that's fine, it's an optional require
  end
  alias optional_require require_optional
end