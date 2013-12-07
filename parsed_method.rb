class ParsedMethod < ParsedBase
  children :calls

  def token_handler(token)
    super + [
      {
        once: true,
        word: ->{ self.name = token }
      }, {
        once: true,
        break: ->{}
      }, {
        optional: true,
        break: ->{}
      }, {
        optional: true,
        word: ->{ new_scope(ParsedCall, calls).handle(token) }
      }, {
        end: ->{ close_scope }
      }
    ]
  end

end
