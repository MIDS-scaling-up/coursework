require "rubygems"
require "open-uri"
require "json"

# HOST = "0.0.0.0"
HOST = "127.0.0.1"

PORT = "8080"
NUM_COMPLETIONS = 3

unless ARGV[0]
  puts "Script takes one argument: start text."
  exit
end

start_text = ARGV[0].to_s

puts ""
puts "Starting torch-rnn-server..."
pid = spawn("th server.lua", :out=>"/dev/null")
Process.detach(pid)

sleep(5) # hacky :)

url = "http://#{HOST}:#{PORT}/generate?start_text=#{URI.encode(start_text)}&n=#{NUM_COMPLETIONS}"

raw = open(url).read
response = JSON.parse(raw)
puts ""
puts "From start text: #{start_text}..."

# puts response

#response["completions"].each do |completion|
response.each do |completion|
  puts "Generated: ..." + completion
end

# puts "(Took #{response["time"]} sec)"
puts ""

puts "Stopping server..."
Process.kill("HUP", pid)

puts "Done."
puts ""
