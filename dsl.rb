module DSL
  def comment_handler
    optional :hash, -> { new_scope(ParsedComment) }
  end

  def space_handler
    optional :space, -> {}
  end

  def required(token, handler = ->{}, options={})
    handlers_array << {
      token => handler
    }.merge(format_options(options))
  end

  def required_once(token, handler = ->{}, options={})
    handlers_array << {
      _once: true,
      token => handler
    }.merge(format_options(options))
  end

  def optional(token, handler = ->{}, options={})
    handlers_array << {
      _optional: true,
      token => handler
    }.merge(format_options(options))
  end

  def optional_once(token, handler = ->{}, options={})
    handlers_array << {
      _optional: true,
      _once: true,
      token => handler
    }.merge(format_options(options))
  end

  def optional_all_except(token, handler = ->{}, options={})
    handlers_array << {
      _optional: true,
      _except: token,
      all: handler
    }.merge(format_options(options))
  end

  def token
    @current_token
  end

  def token_handler(token)
    @current_token = token
    clear_token_handlers
    comment_handler
    space_handler
    handlers
  end

  def handlers
    raise "Must implement handlers method"
  end

  def clear_token_handlers
    @sugar_handlers = []
  end

  private

  def format_options(options)
    new_options = {}
    options.each do |key, value|
      new_options[:"_#{key}"] = value
    end
    new_options
  end

  def handlers_array
    #return @sugar_handlers if @sugar_handlers
    @sugar_handlers ||= []
    #handlers
  end

end
