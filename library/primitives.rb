primitive("+") do |*ops|
    ops.reduce(0, :+)
end

primitive("*") do |*ops|
    ops.reduce(1, :*)
end

primitive("-") do |a, *ops|
    [a, *ops].size < 2 ? 0-a : [a, *ops].reduce(:-)
end

primitive("/") do |a, *ops|
    integer = [a, *ops].all? do |op|
        Integer === op
    end

    [a, *ops].reduce(1) do |a, b|
        integer ? Rational(a, b) : Float(a) / b
    end
end

primitive("=") do |a, *ops|
    ops.all? do |op|
        a == op
    end
end

%w<number? complex? real? rational? integer?>.each do |op|
    primitive(op) do |obj|
        obj.send(op.to_sym)
    end
end

primitive("car") do |pair|
    pair.car
end

primitive("cdr") do |pair|
    pair.cdr
end
