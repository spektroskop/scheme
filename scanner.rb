require "stringio"

class Scanner
    def setup(input)
        if String === input
            @input = StringIO.new(input)
        else
            @input = input
        end
    end

    def more?
        not @input.eof?
    end

    def match(x, y)
        case x
        when Regexp then x.match(y)
        when String then x == y
        end
    end

    def args(chars)
        chars.flat_map do |char|
            char.split("") rescue char
        end
    end

    def unread(string)
        string.reverse.each_char do |char|
            @input.ungetc(char)
        end
    end

    def consume(*chars)
        return @input.getc if chars.empty?
        args(chars).reduce("") do |buffer, matcher|
            if char = @input.getc and match(matcher, char)
                buffer += char
            else
                unread(buffer + char.to_s) and return
            end
        end
    end

    def peek(*chars)
        consume(*chars).tap do |string|
            unread(string) unless string.nil?
        end
    end
end

