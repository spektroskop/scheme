require "./scheme"

Scheme.setup

begin
    Scheme.readline do |line|
        Scheme.run(nil, line).tap do |x|
            puts Paint["=> #{x}", :cyan, :bold]
        end
    end
rescue Scheme::Error => e
    puts Paint[e.message, :red, :bold]
    retry
end
