class ParsedClass < ParsedBase
  children :calls, :defined_methods

  def token_handler(token)
    #TODO subclass
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
      },{
        optional: true,
        def: ->{ new_scope(ParsedMethod, defined_methods) }
      }, {
        optional: true,
        word: ->{ new_scope(ParsedCall, calls).handle(token) }
      }, {
        end: ->{ close_scope }
      }
    ]
  end

end
