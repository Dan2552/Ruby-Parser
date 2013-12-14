class ParsedModule < ParsedBase
  children :modules, :classes, :calls

  def token_handler(token)
    super + [
      {
        once: true,
        word: ->{ self.name = token }
      }, {
        optional: true,
        class: ->{ new_scope(ParsedClass, classes) }
      }, {
        optional: true,
        module: ->{ new_scope(ParsedModule, modules) }
      }, {
        optional: true,
        word: ->{ new_scope(ParsedCall, calls).handle(token) }
      }, {
        optional: true,
        break: -> { }
      }, {
        end: ->{ close_scope }
      }
    ]
  end

end
