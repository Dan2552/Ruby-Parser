class ParsedMethod < ParsedBase
  children :calls

  def token_handler(token)
    super + [
      {
        _once: true,
        word: ->{ self.name = token }
      }, {
        _once: true,
        break: ->{}
      }, {
        _optional: true,
        break: ->{},
        word: ->{ new_scope(ParsedCall, calls).handle(token) }
      }, {
        end: ->{ close_scope }
      }
    ]
  end

end
