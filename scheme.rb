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
        @user = Scope.new(@scope)
    end

    def readline
        loop do
            line = Readline.readline(Paint[">> ", :green, :bold])
            next if line.empty?
            Readline::HISTORY.push(line) unless line == Readline::HISTORY.to_a[-1]
            yield(line) if block_given?
            line
        end
    end

    def parse(input)
        @parser.parse(input)
    end

    def evaluate(scope, expr)
        current = Frame.new(scope, expr)
        current = current.process while Frame === current
        current
    end

    def run(scope, input)
        parse(input).map{|expr| evaluate(scope || @user, expr) }[-1]
    end
end
