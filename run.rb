require "./scheme"

Scheme.setup

begin
    Scheme.readline do |line|
        result = Scheme.run(line)
        puts Paint["=> #{result}", :cyan, :bold]
    end
rescue Scheme::Error => e
    puts Paint[e.message, :red, :bold]
    retry
end
