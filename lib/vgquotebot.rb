require 'net/http'
require 'uri'
require 'twitter' # You know...for tweeting
require 'yaml' # Used to parse the hosted yml

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
    @twitter = TwitterClient.new
    @last_quote = nil
  end

  def main
    clock = set_clock
    puts 'Starting app...'

    loop do
      clock.tick
      sleep 60
    end

  end

  def get_quote
    # @filer.get_contents
    quotes = QuotesProcessor.new(@filer.get_contents).to_a
    quote = QuoteSelector.new quotes, @last_quote
    return quote.to_h
  end

  def set_clock
    return Scheduler.new @app_config[:schedule] do |time|
      quote = get_quote
      tweet quote
    end
  end

  # Just run once and forego the scheduler.
  # This might get separated out into a separate test file or something later
  def test()
    quote = get_quote()
    tweet quote
  end

  def test_loop
    (1..3).each do 
       quote = get_quote
       tweet quote
       sleep 30
     end
  end

  def tweet(quote)
    @twitter.tweet Tweet.new quote
    @last_quote = quote
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

  def to_a
    return @processor['quotes']
  end
end

# Responsible for selecting a quote and passing it forward

class QuoteSelector
  def initialize(quotes, last_quote=nil)
    if not last_quote.nil?
      quotes = remove_last_quote quotes, last_quote
    end

    @quote = select_from(quotes, last_quote)
  end

  def select_from(quotes, last_quote=nil)
    idx = Random.rand quotes.length
    return quotes[idx]
  end

  def remove_last_quote(quotes, last_quote)
    quotes.each_index do |i|
      if quotes[i]['text'] == last_quote['text']
        quotes.delete_at i
        break
      end
    end
    return quotes
  end

  def to_h
    return @quote
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
class TwitterClient
  @@client = nil
  # message should come in as a TweetMessage
  def initialize()
    if @@client.nil?
      create_client
      puts "Created twitter client..."
    end
  end

  def tweet(message)
    message = message.to_s
    puts 'Tweeting: ' + message
    @@client.update message 
  end

  def create_client
    config_file = File.basename(__FILE__).sub('.rb', '.yml')
    if File.exists?('./lib/' + config_file)
      settings = YAML.load_file('./lib/' + config_file)
    else
      settings = {
        :consumer_secret => ENV['CONSUMER_SECRET'],
        :consumer_key => ENV['CONSUMER_KEY'],
        :access_token => ENV['ACCESS_TOKEN'],
        :access_token_secret => ENV['ACCESS_TOKEN_SECRET']
      }
    end
    puts settings.inspect
    @@client = Twitter::REST::Client.new do |config|
      config.consumer_key        = settings[:consumer_key]
      config.consumer_secret     = settings[:consumer_secret]
      config.access_token        = settings[:access_token]
      config.access_token_secret = settings[:access_token_secret]
    end
  end
end

# Represents the formatter to take our data and translate it into a tweet
class Tweet
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
    # '02:36am', # debug
    # '02:37am', # debug
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
