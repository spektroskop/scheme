require "readline"
require "paint"

require "./parser"
require "./frame"
require "./scope"

module Scheme
    extend self

    def setup
        @parser = Parser.new
        @scope = Scope.new
        @scope.load("library/primitives.rb")
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

    def evaluate(expr, scope=@scope)
        current = Frame.new(expr, scope)
        current = current.process while Frame === current
        current
    end

    def run(input, scope=@scope)
        result = parse(input).map{|expr| evaluate(expr, scope) }[-1]
    end
end
