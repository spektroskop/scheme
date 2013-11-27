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
        cur, pre, idx = self, nil, 0
        while cur.pair?
            yield(cur.car, pre, idx) if block_given?
            pre, cur = cur, cur.cdr, idx += 1
        end
        pre
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

    def method_missing(sym, *args)
        if sym =~ /^c([ad])[ad]*r/
            ad = Regexp.last_match[1]
            self.class.class_eval %<def #{sym}
                #{sym.to_s.sub(ad, "")}.c#{ad}r
            end>
            send(sym)
        else
            super
        end
    end
end
