require "test_helper"

module WillItRuby
  class Processor::BlockTest < ProcessorTest
    def test_happy_case
      process <<-RUBY
        def foo
          yield
        end

        foo do
          1
        end
      RUBY

      assert_no_issues
      assert_result :Integer, 1
    end

    def test_sad_case
      process <<-RUBY
        def foo
          yield
        end

        foo
      RUBY

      assert_issues "(unknown):3 no block given (yield)"
    end

    def test_argument_case
      process <<-RUBY
        def foo(a)
          4 + yield(a - 1)
        end

        foo(7) do |x|
          x * 42
        end
      RUBY

      assert_no_issues
      assert_result :Integer, 256
    end

    def test_block_arguments_are_permissive
      process <<-RUBY
        def foo
          yield 1, 2, 3
        end

        foo do
          1
        end
      RUBY

      assert_no_issues
      assert_result :Integer, 1

      process <<-RUBY
        foo do |a,b,c,d|
          a + b + c
        end
      RUBY

      assert_no_issues
      assert_result :Integer, 6

      process <<-RUBY
        foo do |a,b,c,d|
          d
        end
      RUBY

      assert_no_issues
      assert_result :NilClass
    end
  end
end