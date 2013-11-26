def sequence(seq)
    return seq if seq.null?
    return seq.car if seq.cdr.null?
    return Cons.new(:begin, seq) if seq.car.pair?
    seq
end

syntax("define") do |scope, nodes|
    if nodes.car.symbol?
        expr = Scheme.evaluate(scope, nodes.cadr)
        scope.define(nodes.car, expr)
        expr
    else
        Frame.new(scope,
            List([:define, nodes.caar,
                 [:lambda, nodes.cdar,
                 sequence(nodes.cdr)]]))
    end
end

syntax("lambda") do |scope, nodes|
    Procedure.new(scope, nodes.car, sequence(nodes.cdr))
end

syntax("begin") do |scope, nodes|
    Body.new(scope, nodes)
end

syntax("quote") do |scope, nodes|
    nodes.car
end
