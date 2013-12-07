#Run in irb with
#require File.expand_path(Dir.pwd) + "/test.rb"

Dir[File.expand_path(Dir.pwd) + "**/*.rb"].each { |file| require file }

def assert condition
  unless condition
    raise "FailedAssertion"
  end
end

def file
  @file
end

string = <<-eof
  class MyClass
    attr_accessor :banana

    def apple
      my_method(arg1, arg2)
    end
  end
eof

@file = ParsedFile.new(string)
assert file.modules == []
assert file.classes.count == 1

myClass = file.classes.first
assert myClass.name == "MyClass"
assert myClass.calls.count == 1

assert myClass.calls.first.name = "attr_accessor"
assert myClass.calls.first.arguments.count == 1

assert myClass.defined_methods.count == 1

apple = myClass.defined_methods.first
apple.calls.count == 1
ac = apple.calls.first
assert ac.name == "my_method"
assert ac.arguments.count == 2

assert ac.arguments.first.name == "arg1"
assert ac.arguments.last.name == "arg2"

puts "Success!"
exit
