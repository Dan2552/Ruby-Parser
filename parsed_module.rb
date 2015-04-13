class ParsedModule < ParsedBase
  children :modules, :classes, :calls

  def handlers
    required_once :word, ->{ self.name = token }
    optional :class, ->{ new_scope(ParsedClass, classes) }
    optional :module, ->{ new_scope(ParsedModule, modules) }
    optional :word, ->{ new_scope(ParsedCall, calls).handle(token) }
    optional :break
    required :end, ->{ close_scope }
  end
end
