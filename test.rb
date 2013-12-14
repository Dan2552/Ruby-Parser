#Run in irb with
#require File.expand_path(Dir.pwd) + "/test.rb"

Dir[File.expand_path(Dir.pwd) + "**/*.rb"].each { |file| require file }

@print_level = 1

def describe name, &blk
  puts "#{"  " * @print_level}#{name} -->"
  @print_level = @print_level + 1
  blk.call
  @print_level = @print_level - 1
end

def test name
  puts "#{"  " * @print_level}#{name}"
end

def assert_equal expect, value
  unless expect == value
    raise "FailedAssertion: #{expect} expected, got #{value}"
  end
end

def file
  @file
end

string = <<-eof
  class MyClass
    attr_accessor :banana

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
    end

  end
eof


@file = ParsedFile.new(string)
assert_equal(file.modules, [])
assert_equal(file.classes.count, 1)

describe "class" do
  test "name"
  myClass = file.classes.first
  assert_equal(myClass.name, "MyClass")

  test "calls"
  assert_equal(myClass.calls.count, 1)
  assert_equal(myClass.calls.first.name, "attr_accessor")
  assert_equal(myClass.calls.first.arguments.count, 1)

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
    assert_equal(block_method_with_params.arguments.count, 0)
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
  end
end

puts "Success!"
exit
