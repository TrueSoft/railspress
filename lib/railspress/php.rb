module Railspress::PHP

  def self.is_array(var)
    var.is_a? Array or var.is_a? Hash
  end

  def self.is_scalar(var)
    var.is_a?(Numeric) || var.is_a?(String) || var.is_a?(FalseClass) || var.is_a?(TrueClass)
  end

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
          output << "#{@indent}    [#{key}] => #{value.inspect}\n"
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
          output << "#{@indent}    [#{index}] => #{value.inspect}\n"
        end
      }
      output << "#{@indent})\n"
    end
    #   Pop last indent off
    8.times {@indent.chop!}
    output
  end

  def self.rawurlencode(string)
    if string.blank?
      ''
    else
      URI::escape(string)
    end
  end

  def self.strlen(string)
    if string.nil?
      0
    else
      string.to_s.length
    end
  end

  def stream_get_wrappers
    %w(https ftps compress.zlib php file glob data http ftp phar)
  end

  def self.parse_str(string)
    require 'addressable/uri'
    Addressable::URI.parse(string).query_values()
  end

end