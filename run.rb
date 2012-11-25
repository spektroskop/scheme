require "./scheme"

parse = ARGV.include?("p")

Scheme.setup

begin
    Scheme.readline do |line|
        if parse
            result = Scheme.parse(line)
        else
            result = Scheme.run(line)
        end
        puts Paint["=> #{result}", :cyan, :bold]
    end
rescue Scheme::Error => e
    puts Paint[e.message, :red, :bold]
    retry
end
