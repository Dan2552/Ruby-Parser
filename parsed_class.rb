class ParsedClass < ParsedBase
  children :calls, :defined_methods

  def token_handler(token)
    #TODO subclass
    super + [
      {
        once: true,
        word: ->{ self.name = token }
      }, {
        _optional: true,
        break: ->{},
        def: ->{ new_scope(ParsedMethod, defined_methods) },
        word: ->{ new_scope(ParsedCall, calls).handle(token) }
      }, {
        end: ->{ close_scope }
      }
    ]
  end

end
