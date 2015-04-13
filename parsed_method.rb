class ParsedMethod < ParsedBase
  children :calls

  def handlers
    required_once :word, ->{ self.name = token }
    required_once :break
    optional :break
    optional :word, ->{ new_scope(ParsedCall, calls).handle(token) }
    required :end, ->{ close_scope }
  end
end
