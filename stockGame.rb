class Stock
	require 'net/http'

  def Stock::quote(symbols)
    return {} if symbols.empty?
    quotes = Net::HTTP.get(
      'download.finance.yahoo.com',
      '/d?f=nl1&s='+symbols.join(',')).split(/\n/)
    Hash[*quotes.collect { |quote|
      [symbols.shift, quote[quote.rindex(',')+1...-1].to_f]
    }.flatten]
  end
end

unless (File.exist?('game.data'))
  File.open('game.data', 'w') { |file|
    Marshal.dump({'cash' => 1000000, 'shares' => {}}, file)
  }
end

$data = File.open('game.data') { |file| Marshal.load(file) }
$data['shares'].default = 0

def dumpData
  File.open('game.data', 'w') { |file|
    Marshal.dump($data, file)
  }
end

def printInfo
  puts "You now have:"
  prices = Stock::quote($data['shares'].keys)
  total = $data['cash']
  $data['shares'].each {|symbol, shares|
    worth = shares * prices[symbol]
    puts "  #{shares} shares of #{symbol} at $#{prices[symbol]} each, worth $#{worth} total"
    total += worth
  }
  puts "$#{$data['cash']} in cash"
  puts "Total assets: $#{total}"
end

def printHelp
  puts <<-eos
  Commands:
    quote TSLA,FB,AAPL
      - Print current prices for provided symbols
    status
      - Tells you how you're currently doing
    buy TSLA
      - Buy shares of TSLA, prompts for amount
    sell TSLA
      - Sell shares of TSLA, prompts for amount
  eos
end

def takeCommand
  print 'cmd: '
  cmd,subject = *gets.strip.split(/\s+/)
  subject.upcase! unless subject.nil?
  if (cmd == 'help')
    printHelp
  elsif (cmd == 'quote')
    Stock::quote(subject.split(',')).each { |symbol, price|
      puts "#{symbol}: $#{price}"
    }
  elsif (cmd == 'buy')
    print "How many shares of #{subject}?: "
    shares = gets.strip.to_i
    price = Stock::quote([subject])[subject]
    if (price == 0)
      puts "Invalid stock symbol: #{subject}"
      return
    end
    cost = shares * price
    if (cost > $data['cash'])
      puts "Only have $#{$data['cash']} and this would cost $#{cost}"
      return
    end
    puts "You currently own #{$data['shares'][subject]} shares of #{subject}"
    puts "Buying #{shares} shares of #{subject} at $#{price} each for $#{cost}"
    $data['cash'] -= cost
    $data['shares'][subject] += shares
    dumpData
    printInfo
  elsif (cmd == 'sell')
    print "How many shares of #{subject}?: "
    shares = gets.strip.to_i
    price = Stock::quote([subject])[subject]
    if (price == 0)
      puts "Invalid stock symbol: #{subject}"
      return
    end
    if ($data['shares'][subject] < shares)
      puts "You don't have #{shares} shares of #{subject}"
      return
    end
    value = shares * price
    puts "Selling #{shares} of #{subject} at $#{price} each for $#{value}"
    $data['cash'] += value
    $data['shares'][subject] -= shares
    $data['shares'].delete(subject) if ($data['shares'][subject] == 0)
    dumpData
    printInfo
  elsif (cmd == 'status')
    printInfo
  else
    puts "I don't understand that command"
    printHelp
  end
end

puts 'Welcome to stockGame, type help to get started'
loop { takeCommand }