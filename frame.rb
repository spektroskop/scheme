class Frame
    def initialize(expr, scope)
        @expr, @scope = expr, scope
    end

    def process
        case @expr
            when Symbol then @scope.lookup(@expr)
            when Cons
                error("expected proper list") unless @expr.list?
                object = Scheme.evaluate(@expr.car, @scope)
                error("expected procedure, got `#{object}'") unless object.procedure?
                object.call(@expr.cdr, @scope)
            else @expr
        end
    end

    def to_s
        "#<#{self.class.name.downcase}>"
    end
end
