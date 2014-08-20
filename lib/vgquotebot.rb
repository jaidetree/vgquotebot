# require 'chatterbot/dsl'
require 'yaml' # Used to parse the hosted yml
require 'open-uri' # Open URLs and read their contents.

# Open our quotes.yml
open("https://raw.githubusercontent.com/MrFwibbles/VGQuotes/master/quotes.yml") do |f|
  text = f.read
  puts text
  thing = YAML.load(text)
  puts thing.inspect
end

# Our main bot app logic: Quotosai the Quote Slayer
class VGQuoteBot
end

# Responsible for dealing with files and such nonsense.
class FileCabinet
end

# Responsible for handling our scheduling
class Scheduler
end

# Our tweet mechanism
# Uses chatterbot
class Tweet
end
