class Object
    def procedure?
        Procedure === self
    end
end

class Procedure
    attr_accessor :name

    def initialize(scope, args, body)
        @scope = scope
        @args = args.array rescue []
        @required = @args.size
        @body = body
        if args.pair? and cdr = args.last.cdr
            @rest = cdr unless cdr.null?
        else
            @rest = args if args.symbol?
        end
    end

    def arity(args)
        num = args.length
        if num < @required or (num > @required and not @rest)
            arg = @rest.nil? ? @required : "at least #{@required}"
            error "`#{@name}': wrong number of arguments:" +
                  " #{num} given, #{arg} expected"
        end
    end

    def call(scope, args)
        arity(args)
        args = args.array.map{|node| Scheme.evaluate(scope, node) }
        apply(args)
    end

    def apply(args)
        scope = Scope.new(@scope)
        scope.define(@rest, List(args.drop(@required))) if @rest
        scope.define(@args, args)
        Frame.new(scope, @body)
    end

    def to_s
        s = "#<#{self.class.name.downcase}"
        s+= " `#{@name}'" if @name
        s+= ">"
    end
end

class Primitive < Procedure
    def initialize(&block)
        @rest = block.arity < 0
        @required = block.arity
        @required = @required.next.abs if @rest
        @block = block
    end

    def apply(args)
        @block.call(*args)
    end
end

class Syntax < Primitive
    def call(scope, args)
        @block.call(scope, args)
    end
end
