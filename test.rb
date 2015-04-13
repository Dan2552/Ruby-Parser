#Run in irb with
#require File.expand_path(Dir.pwd) + "/test.rb"

time = Time.now
Dir[File.expand_path(Dir.pwd) + "**/*.rb"].each { |file| require file }

@print_level = 1

def log *arg
  #puts *arg
end

def describe name, &blk
  log "#{"  " * @print_level}#{name} -->"
  @print_level = @print_level + 1
  blk.call
  @print_level = @print_level - 1
end

def test name
  log "#{"  " * @print_level}#{name}"
end

def assert_equal value, expect
  unless expect == value
    raise "FailedAssertion: #{expect} expected, got #{value}"
  end
end

def file
  @file
end

#TODO:
#if
#else
#elsif
#subclasses
#array[0]
#and, or, &&, ||
#multiline operators e.g 1+\n2
#one.two.three\n.four
#1+\n2
#Namespacing::Syntax
#simple strings
#string interpolation, don't forget instance vars don't need {}
#heredoc
#a, b = 1, 2
#hash literals
#symbols (one: 1) in arguments
#prioritised expressions: 3 + (1 + 2)
#case when syntax
#ranges a..b
#line continuation with `\` character
#ternary operator(?:)
#method calls on string literals
#method calls on array literals
#method calls on number literals

string = <<-eof
  chain(arg1).chained(arg2)
  assignment = assignee
  1+2
  2/3
  5-4
  6%7
  array << shovel
  1 + 2

  class MyClass
    # comment
    attr_reader :oranges
    attr_accessor :bananas, #comment after line
                  :apples
    multiline_bracket(
      :apples,
      :bananas,
      :oranges
    )

    def basic_method
      my_method(arg1, arg2)
    end

    def blocks
      block_method(arg1) { block_contents }
      block_method_with_params { |p1, p2| block_contents }
      block_method_multiline { |p1, p2|
        block_contents
      }
      block_method_do do |variable|
        block_contents1
        block_contents2
      end
      block_ception { inside_block(inside_arg1) { double_inside_block } }
    end
  end

  module MyModule
    class ModuleClass; end
    module ChildModule; end
    module_call(arg1)
  end
eof


@file = ParsedFile.new(string)

describe "calls" do
  test "chaining"
  assert_equal(file.calls[0].name, "chain")
  assert_equal(file.calls[0].chain.name, "chained")

  describe "special chains" do
    test "assignment"
    assert_equal(file.calls[1].name, "assignment")
    assert_equal(file.calls[1].chain.name, "=")
    assert_equal(file.calls[1].chain.arguments.first.name, "assignee")

    test "addition"
    assert_equal(file.calls[2].name, "1")
    assert_equal(file.calls[2].chain.name, "+")
    assert_equal(file.calls[2].chain.arguments.first.name, "2")

    test "division"
    assert_equal(file.calls[3].name, "2")
    assert_equal(file.calls[3].chain.name, "/")
    assert_equal(file.calls[3].chain.arguments.first.name, "3")

    test "subtraction"
    assert_equal(file.calls[4].name, "5")
    assert_equal(file.calls[4].chain.name, "-")
    assert_equal(file.calls[4].chain.arguments.first.name, "4")

    test "modular"
    assert_equal(file.calls[5].name, "6")
    assert_equal(file.calls[5].chain.name, "%")
    assert_equal(file.calls[5].chain.arguments.first.name, "7")

    test "shovel"
    assert_equal(file.calls[6].name, "array")
    assert_equal(file.calls[6].chain.name, "<<")
    assert_equal(file.calls[6].chain.arguments.first.name, "shovel")

    test "spacing"
    assert_equal(file.calls[7].name, "1")
    assert_equal(file.calls[7].chain.name, "+")
    assert_equal(file.calls[7].chain.arguments.first.name, "2")
  end
end

describe "class" do
  assert_equal(file.classes.count, 1)
  myClass = file.classes.first

  test "name"
  assert_equal(myClass.name, "MyClass")

  describe "calls" do
    assert_equal(myClass.calls.count, 3)

    test "simple"
    assert_equal(myClass.calls[0].name, "attr_reader")
    assert_equal(myClass.calls[0].arguments.count, 1)
    assert_equal(myClass.calls[0].arguments[0].name, ":oranges")

    test "multiline"
    assert_equal(myClass.calls[1].name, "attr_accessor")
    assert_equal(myClass.calls[1].arguments.count, 2)
    assert_equal(myClass.calls[1].arguments[0].name, ":bananas")
    assert_equal(myClass.calls[1].arguments[1].name, ":apples")

    test "multiline brackets"
    assert_equal(myClass.calls[2].name, "multiline_bracket")
    assert_equal(myClass.calls[2].arguments.count, 3)
    assert_equal(myClass.calls[2].arguments[0].name, ":apples")
    assert_equal(myClass.calls[2].arguments[1].name, ":bananas")
    assert_equal(myClass.calls[2].arguments[2].name, ":oranges")

  end


  test "methods"
  assert_equal(myClass.defined_methods.count, 2)

  describe "basic_method" do
    basic_method = myClass.defined_methods.first
    assert_equal(basic_method.name, "basic_method")
    assert_equal(basic_method.calls.count, 1)

    test "calls"
    my_method = basic_method.calls.first
    assert_equal(my_method.name, "my_method")
    assert_equal(my_method.arguments.count, 2)
    assert_equal(my_method.arguments.first.name, "arg1")
    assert_equal(my_method.arguments.last.name, "arg2")
  end

  describe "blocks" do
    blocks = myClass.defined_methods[1]

    test "simple"
    block_method = blocks.calls[0]
    assert_equal(block_method.name, "block_method")
    assert_equal(block_method.arguments.count, 1)
    assert_equal(block_method.block.calls.count, 1)
    assert_equal(block_method.block.calls.first.name, "block_contents")

    test "with params"
    block_method_with_params = blocks.calls[1]
    assert_equal(block_method_with_params.name, "block_method_with_params")
    assert_equal(block_method_with_params.arguments, [])
    assert_equal(block_method_with_params.block.calls.count, 1)
    assert_equal(block_method_with_params.block.calls.first.name, "block_contents")
    assert_equal(block_method_with_params.block.arguments, ["p1", "p2"])

    test "multiline"
    block_method_multiline = blocks.calls[2]
    assert_equal(block_method_multiline.name, "block_method_multiline")
    assert_equal(block_method_multiline.block.arguments, ["p1", "p2"])
    assert_equal(block_method_multiline.arguments.count, 0)
    assert_equal(block_method_multiline.block.calls.count, 1)
    assert_equal(block_method_multiline.block.calls.first.name, "block_contents")

    test "do"
    block_method_do = blocks.calls[3]
    assert_equal(block_method_do.name, "block_method_do")
    assert_equal(block_method_do.block.arguments, ["variable"])
    assert_equal(block_method_do.arguments.count, 0)
    assert_equal(block_method_do.block.calls.count, 2)
    assert_equal(block_method_do.block.calls.first.name, "block_contents1")
    assert_equal(block_method_do.block.calls.last.name, "block_contents2")

    test "blockception"
    block_ception = blocks.calls[4]
    assert_equal(block_ception.name, "block_ception")
    assert_equal(block_ception.block.calls.first.name, "inside_block")
    assert_equal(block_ception.block.calls.first.block.calls.first.name, "double_inside_block")
  end
end

describe "module" do
  assert_equal(file.modules.count, 1)
  myModule = file.modules.first

  test "name"
  assert_equal(myModule.name, "MyModule")

  test "child module"
  assert_equal(myModule.modules.count, 1)
  assert_equal(myModule.modules[0].name, "ChildModule")

  test "child class"
  assert_equal(myModule.classes.count, 1)
  assert_equal(myModule.classes[0].name, "ModuleClass")

  test "calls"
  assert_equal(myModule.calls.count, 1)
  assert_equal(myModule.calls[0].name, "module_call")
  assert_equal(myModule.calls[0].arguments[0].name, "arg1")
end

puts "Success! 👍"
puts (Time.now - time)
exit
