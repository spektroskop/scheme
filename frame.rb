class Frame
    def initialize(scope, expr)
        @scope, @expr = scope, expr
    end

    def process
        case @expr
            when Symbol then @scope.lookup(@expr)
            when Cons
                error("expected proper list") unless @expr.list?
                object = Scheme.evaluate(@scope, @expr.car)
                error("expected procedure, got `#{object}'") unless object.procedure?
                object.call(@scope, @expr.cdr)
            else @expr
        end
    end

    def to_s
        "#<#{self.class.name.downcase}>"
    end

class Body < Frame
    def process
        last = @expr.length - 1
        @expr.each do |expr, _, i|
            return Frame.new(@scope, expr) if i == last
            Scheme.evaluate(@scope, expr)
        end
    end
end
