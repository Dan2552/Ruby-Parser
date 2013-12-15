class ParsedFile < ParsedBase
  attr_accessor :current_token

  children :modules, :classes, :calls

  def initialize str
    parse_string str
  end

  def parse_string str
    @current_token = ""
    str.each_char do |c|
      if named_tokens.keys.include? c
        send_token_to_scope
        send_token_to_scope(c)
      else
        self.current_token = current_token + c
      end
    end
  end

  def send_token_to_scope(token=current_token)
    return if token.length == 0
    current_scope.handle(token)
    self.current_token = ""
  end

  def token_handler(token)
    super + [
      {
        optional: true,
        class: ->{ new_scope(ParsedClass, classes) },
        module: ->{ new_scope(ParsedModule, modules) },
        word: ->{ new_scope(ParsedCall, calls).handle(token) }
      }
    ]
  end

end
