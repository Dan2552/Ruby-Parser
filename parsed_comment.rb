class ParsedComment < ParsedBase

  def token_handler(token)
  [
    {
      optional: true,
      except: :break,
      all: ->{ self.name = ("#{name} #{token}").strip }
    }, {
      break: ->{ close_scope.handle(token) }
    }
  ]
  end

end
