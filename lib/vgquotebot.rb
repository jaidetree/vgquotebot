require 'net/http'
require 'uri'
require 'twitter' # You know...for tweeting
require 'yaml' # Used to parse the hosted yml
# require 'open-uri' # Open URLs and read their contents.

# Open our quotes.yml

# This app is written this way so that everything exists as small pieces that
# only do one thing, and one thing well. But they are incapsulated in simple 
# objects so that the interface will always be the same no matter what their 
# guts do.

# Our main bot app logic: Quotosai the Quote Slayer
class VGQuoteBot

  def initialize(config)
    @app_config = {}
    @app_config = @app_config.merge(config)
    @filer = Filer.new @app_config[:url]
    @processor = QuotesProcessor.new
  end

  def main
    clock = set_clock

    loop do
      clock.tick
      sleep 60
    end

  end

  def set_clock
    return Scheduler.new @app_config[:schedule] do |time|
      quote = get_quote
      tweet quote
    end
  end

  def test_loop
    (1..3).each do 
       quote = get_quote
       tweet quote
       sleep 60
     end
  end

  def get_quote
    # @filer.get_contents
    @processor.process @filer.get_contents
    quotes = @processor.get('quotes')
    quote = QuoteSelector.new(quotes).quote
    return quote
  end

  def tweet(quote)
    Tweet.new quote
  end

  # Just run once and forego the scheduler.
  # This might get separated out into a separate test file or something later
  def test()
    quote = get_quote()
    tweet quote
  end
end

# Responsible for dealing with files and such nonsense.
class Filer
  def initialize(url)
    @url = url
  end

  # Read the URL and return the contents
  def get_contents
    r = Net::HTTP.get_response( URI.parse( @url ) )
    return r.body
  end
end

# Responsible for parsing the textfile into a Hash or hash like object.
class QuotesProcessor
  def initialize(content=nil)
    if content
      process(content)
    end
  end

  def process(content)
    @processor = YAML.load(content)
  end

  def get(key)
    return @processor[key]
  end
end

# Responsible for selecting a quote and passing it forward

class QuoteSelector
  def initialize(quotes)
    selectFrom(quotes)
  end

  def selectFrom(quotes)
    idx = Random.rand quotes.length
    @selected_quote = quotes[idx]
  end

  def quote
    return @selected_quote
  end
end


# Responsible for handling our scheduling
class Scheduler
  def initialize(times, &block)
    @schedule = times
    @event = block
  end

  def tick
    current_time = Time.now.gmtime.strftime "%I:%M%P"
    check(current_time)
  end

  def check(current_time)
    @schedule.each do |event_time|
      if current_time == event_time
        @event.call current_time
      end
    end
  end
end

# Our tweet mechanism
# Uses chatterbot
class Tweet
  @@client = nil
  # message should come in as a TweetMessage
  def initialize(quote)
    if @@client.nil?
      create_client
      puts "Created client \n"
    end
    tweet TweetMessage.new quote
  end

  def tweet(message)
    message = message.to_s
    puts 'Tweeting: ' + message
    @@client.update message 
  end

  def create_client
    config_file = File.basename(__FILE__).sub('.rb', '.yml')
    settings = YAML.load_file(config_file)
    @@client = Twitter::REST::Client.new do |config|
      config.consumer_key        = settings[:consumer_secret]
      config.consumer_secret     = settings[:consumer_key]
      config.access_token        = settings[:access_token]
      config.access_token_secret = settings[:access_token_secret]
    end
  end
end

# Represents the formatter to take our data and translate it into a tweet
class TweetMessage
  @@format = '"%s" - %s'

  def initialize(quote)
    @text = quote['text']
    @source = quote['source']
  end

  def to_s
    return sprintf @@format, @text, @source
  end
end

# Let's run this thing!

bot = VGQuoteBot.new({
  url: 'https://raw.githubusercontent.com/MrFwibbles/VGQuotes/master/quotes.yml',
  schedule: [
    '10:52pm', # debug
    '10:53pm', # debug
    '10:00am',
    '04:00pm',
    '10:00pm',
  ]
})

ARGV.each_index do |i| 
  if ARGV[i] == "--test"
    if ARGV[i + 1] == 'loop'
      bot.test_loop
      exit
    else
      bot.test
      exit
    end
  end
end 

bot.main
