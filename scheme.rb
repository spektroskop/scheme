require "readline"

begin
    require "paint"
rescue LoadError
    Paint = lambda do |x, *r|
        x
    end
end

require "./parser"
require "./frame"
require "./scope"
require "./extensions"

module Scheme
    extend self

    def setup
        @parser = Parser.new
        @scope = Scope.new
        @scope.load("library/primitives.rb")
        @scope.load("library/syntax.rb")
        @scope.load("library/library.ss")
        @user = Scope.new(@scope)
    end

    def readline
        Readline.completion_proc = proc do |s|
            (@user.keys + @scope.keys).uniq.grep(/^#{Regexp.escape(s)}/)
        end

        begin
            loop do
                line = Readline.readline(Paint[">> ", :green, :bold])
                next if line.empty?
                Readline::HISTORY.push(line) unless line == Readline::HISTORY.to_a[-1]
                yield(line) if block_given?
                line
            end
        end
    end

    def evaluate(scope, expr)
        current = Frame.new(scope, expr)
        current = current.process while Frame === current
        current
    end

    def run(scope, input)
        @parser.run(input) do |expr|
            evaluate(scope || @user, expr)
        end
    end
end
