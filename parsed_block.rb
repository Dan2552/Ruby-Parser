class ParsedBlock < ParsedBase
  include DefinitionArgumentList

  children :calls, :arguments

  def expect_pipe?
    states.select {|s| s == "|" }.count == 1
  end

  def expect_arguments?
    expect_pipe?
  end

  def handlers
    optional :pipe, -> { states << token }

    definition_argument_list

    required :pipe, -> { states << token },
      if: :expect_pipe?

    call_list

    optional :close_curley, ->{ close_scope }
    required :end, ->{ close_scope }
  end

  def call_list
    optional :break
    optional :word, ->{ new_scope(ParsedCall, calls).handle(token) }
  end

end
