require "readline"
require "paint"

require "./undefined"
require "./empty"
require "./error"
require "./parser"
require "./extensions"

module Scheme
    extend self

    def setup
        @parser = Parser.new
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

    def evaluate(expr, scope=nil)
        expr
    end

    def run(input, scope=nil)
        result = parse(input).map{|expr| evaluate(expr) }[-1]
    end
end
