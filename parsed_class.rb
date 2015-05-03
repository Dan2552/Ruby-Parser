class ParsedClass < ParsedBase
  children :calls, :defined_methods

  def handlers
    required_once :word, ->{ self.name = token }
    optional :break
    optional :def, ->{ new_scope(ParsedMethod, defined_methods) }
    optional :word, ->{ new_scope(ParsedCall, calls).handle(token) }
    required :end, ->{ close_scope }
  end

end
