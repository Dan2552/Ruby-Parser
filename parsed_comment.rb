class ParsedComment < ParsedBase
 def handlers
    optional_all_except :break, ->{ self.name = ("#{name} #{token}").strip }
    required :break, ->{ close_scope.handle(token) }
  end
end
