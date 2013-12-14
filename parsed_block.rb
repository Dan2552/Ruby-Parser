class ParsedBlock < ParsedBase
  include DefinitionArgumentList

  children :calls, :arguments

  def expect_pipe?
    states.select {|s| s == "|" }.count == 1
  end

  def expect_arguments?
    expect_pipe?
  end

  def token_handler(token)
    super + [
      {
        optional: true,
        pipe: -> { states << token }
      }
    ] + definition_argument_list(token) + [
      {
        if: :expect_pipe?,
        pipe: -> { states << token }
      }
    ] + call_list(token) + [
      {
        optional: true,
        close_curley: ->{ close_scope }
      }, {
        end: -> { close_scope }
      }
    ]
  end

  def call_list(token)
    [
      {
        optional: true,
        break: ->{}
      }, {
        optional: true,
        word: ->{ new_scope(ParsedCall, calls).handle(token) }
      }
    ]
  end

end
