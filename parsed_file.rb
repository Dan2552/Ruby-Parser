class ParsedFile < ParsedBase
  children :modules, :classes, :calls

  def token_handler(token)
    super + [
      {
        _optional: true,
        class: ->{ new_scope(ParsedClass, classes) },
        module: ->{ new_scope(ParsedModule, modules) },
        word: ->{ new_scope(ParsedCall, calls).handle(token) }
      }
    ]
  end

end
