module DefinitionArgumentList
  #e.g.
  # method definition: def my_method(***arg1, arg2, arg3***)
  # block definition: { |***arg1, arg2***| blah }

  def definition_argument_list(token)
    [
      {
        _unless: :expect_argument_delimiter?,
        _if: :expect_arguments?,
        word: -> { arguments << token }
      }, {
        _optional: true,
        _if: :expect_argument_delimiter?,
        delimiter: -> { states << token }
      }
    ]
  end

  def expect_argument_delimiter?
    arguments.count > argument_delimiter_count
  end

  def argument_delimiter_count
    states.select { |s| s == "," }.count
  end

end
