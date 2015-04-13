class ParsedModule < ParsedBase
  children :modules, :classes, :calls

  def token_handler(token)
    super + [
      {
        once: true,
        word: ->{ self.name = token }
      }, {
        _optional: true,
        class: ->{ new_scope(ParsedClass, classes) },
        module: ->{ new_scope(ParsedModule, modules) },
        word: ->{ new_scope(ParsedCall, calls).handle(token) },
        break: -> { }
      }, {
        end: ->{ close_scope }
      }
    ]
  end

end
