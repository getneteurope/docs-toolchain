SimpleCov.start do |config|
  add_filter 'test/'
  add_filter 'lib/stages/'
  add_filter 'lib/notify/slack.rb' # not feasible to test
end