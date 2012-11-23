require "./undefined"
require "./empty"

class Object
    def list?
        if Cons === self
            last.cdr.null?
        else
            null?
        end
    end

    def null?
        Empty === self
    end

    def pair?
        Cons === self
    end
end

def List(array, tail = Empty)
    return Empty if array.empty?
    array.reverse.reduce(tail) do |cons, node|
        node = List(node) if Array === node
        Cons.new(node, cons)
    end
end

class Cons
    attr_accessor :car, :cdr

    def initialize(car, cdr = Empty)
        @car, @cdr = car, cdr
    end

    def each
        curr, prev, index = self, nil, 0
        while curr.pair?
            yield curr.car, prev, index if block_given?
            prev, curr, index = curr, curr.cdr, index += 1
        end
        prev
    end

    def reduce(expr = Undefined)
        each do |car, *args|
            expr = expr == Undefined ? car : yield(expr, car, *args)
        end
        expr
    end

    def last
        each
    end

    def length
        reduce(0) do |res, _|
            res += 1
        end
    end

    def reverse
        reduce(last.cdr) do |res, cur|
            res = Cons.new(cur, res)
        end
    end

    def map(&block)
        reverse.reduce(Empty) do |res, cur|
            res = Cons.new(block[cur], res)
        end
    end

    def array
        reduce([]) do |res, cur|
            res << cur
        end
    end

    def append(object)
        cons = List(array, last.cdr)
        cons.last.cdr = object
        cons
    end

    def to_s
        nodes = []
        x = each{|node| nodes << node.to_s }
        s = nodes.join(" ")
        s+= " . " + x.cdr.to_s unless x.cdr.null?
        return "(#{s})"
    end
end
