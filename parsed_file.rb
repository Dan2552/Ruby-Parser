class ParsedFile < ParsedBase
  children :modules, :classes, :calls

  def handlers
    optional :class, ->{ new_scope(ParsedClass, classes) }
    optional :module, ->{ new_scope(ParsedModule, modules) }
    optional :word, ->{ new_scope(ParsedCall, calls).handle(token) }
  end
end
