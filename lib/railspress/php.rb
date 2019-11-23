module Railspress::PHP
  def self.print_r(inHash, *indent)
    output = ''
    @indent = indent.join
    if inHash.class.to_s == "Hash"
      output << "Hash\n#{@indent}(\n"
      inHash.each { |key, value|
        if (value.class.to_s =~ /Hash/) || (value.class.to_s =~ /Array/)
          output << "#{@indent}    [#{key}] => "
          output << self.print_r(value, "#{@indent}        ")
        else
          output << "#{@indent}    [#{key}] => #{value}\n"
        end
      }
      output << "#{@indent})\n"
    elsif inHash.class.to_s == "Array" then
      output << "Array\n#{@indent}(\n"
      inHash.each_with_index { |value,index|
        if (value.class.to_s == "Hash") || (value.class.to_s == "Array")
          output << "#{@indent}    [#{index}] => "
          output << self.print_r(value, "#{@indent}        ")
        else
          output << "#{@indent}    [#{index}] => #{value}\n"
        end
      }
      output << "#{@indent})\n"
    end
    #   Pop last indent off
    8.times {@indent.chop!}
    output
  end
end