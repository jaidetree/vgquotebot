require 'chatterbot/dsl'
require 'yaml' # Used to parse the hosted yml
require 'open-uri' # Open URLs and read their contents.

# Open our quotes.yml

# This app is written this way so that everything exists as small pieces that
# only do one thing, and one thing well. But they are incapsulated in simple 
# objects so that the interface will always be the same no matter what their 
# guts do.

# Our main bot app logic: Quotosai the Quote Slayer
class VGQuoteBot
    @config = {}

    def initialize(config)
        @config = @config.merge(config)
    end

    def main
        clock = Scheduler.new @config[:schedule], { |time| tweet }

        loop do
            clock.tick
            sleep 60
        end
    end

    def get_quote
        filer = Filer.new @config[:url]
        processor = QuotesProcessor.new(filer.get_contents())
        quotes = processor.get('quotes')
        quote = new QuoteSelector.new(quotes).quote()
        return quote
    end

    def tweet(quote)
        Tweet.new TweetMessage.new(quote)
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
    @url = ""

    def initialize(url)
        @url = url
    end

    # Read the URL and return the contents
    def get_contents
        text = ""

        open(@url) do |f|
            text = f.read
        end

        return text
    end
end

# Responsible for parsing the textfile into a Hash or hash like object.
class QuotesProcessor
    @processor = nil
    @result = nil

    def initialize(content)
        process(content)
    end

    def process(content)
        @processor = YAML.load(contnet)
    end

    def get(key)
        return @processor[key]
    end
end

# Responsible for selecting a quote and passing it forward

class QuoteSelector
    @selected_quote = nil

    def initialize(quotes)
        selectFrom(quotes)
    end

    def selectFrom(quotes)
        idx = Random.new quotes.length
        @selected_quote = quotes[idx]
    end

    def quote
        return @selected_quote
    end
end


# Responsible for handling our scheduling
class Scheduler
    @schedule = []
    @event = nil

    def initialize(times, &block)
        @schedule = times
        @event = block
    end

    def tick:
        current_time = Time.now.gmtime.strftime "%I:%M%P"
        check(current_time, @event)
    end

    def check(current_time, &block)
        @schedule.each do |event_time|
            if time.strftime "%I:%M%P" == event_time
                block.call time
            end
        end
    end
end

# Our tweet mechanism
# Uses chatterbot
class Tweet
    # message should come in as a TweetMessage
    def initialize(message)
        tweet message.to_s
    end
end

# Represents the formatter to take our data and translate it into a tweet
class TweetMessage
    @@format = '"%s" - %s'
    @text = ""
    @source = ""

    def initialize(quote)
        @text = quote['text']
        @source = quote['source']
    end

    def to_s
        return sprintf @@format, @source, @source
    end
end

# Lets run this thing!

bot = VGQuoteBot.new {
    :url => "https://raw.githubusercontent.com/MrFwibbles/VGQuotes/master/quotes.yml",
    :schedule => [
        '10:00am',
        '04:00pm',
        '10:00pm',
    ]
}

# bot.main # Run this mutha!
bot.test
