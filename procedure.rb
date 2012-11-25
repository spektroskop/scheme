class Object
    def procedure?
        Procedure === self
    end
end

class Procedure
    attr_accessor :name

    def call(args, scope)
        args = args.array.map{|node| Scheme.evaluate(node, scope) }
        apply(args)
    end

    def to_s
        s = "#<#{self.class.name.downcase}"
        s+= " `#{@name}'" if @name
        s+= ">"
    end
end

class Primitive < Procedure
    def initialize(&block)
        @block = block
    end

    def apply(args)
        @block.call(*args)
    end
end
