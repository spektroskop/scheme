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

    def read(*chars)
        args(chars).reduce("") do |buffer, matcher|
            if char = @input.getc and match(matcher, char)
                buffer << char
            else
                unread(buffer + char.to_s) and return
            end
        end
    end

    def consume(*chars)
        unless chars.empty?
            read(*chars)
        else
            @input.getc
        end
    end

    def peek(*chars)
        unless chars.empty?
            read(*chars).tap do |chars|
                unread(chars) unless chars.nil?
            end
        else
            @input.getc.tap do |c|
                @input.ungetc(c)
            end
        end
    end
end

