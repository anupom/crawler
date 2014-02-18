# Crawler

Crawler is a simple web crawler written in Ruby. Given a URL it crawls the domain and recursively finds all links
associated with it. It also keeps track of all static contents related to each of these links.

It uses eventmachine and fiber (through em-synchrony) to issue concurrent non-blocking requests.
Crawler stores the site map using a variation of Adjacency list data structure. It can also
pretty-print the map once a URL is crawled.

## Installation

Add this line to your application's Gemfile:

    gem 'simple_crawler'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install simple_crawler

## Usage

### Using Crawler as library
```ruby
crawler = Crawler.new('http://google.com')
# Start crawling the URL
crawler.crawl
# Generated site map object
map = crawler.map
# Pretty print the site map
crawler.print
```

### Using Crawler as binary
```sh
# Crawl domain and print the sitemap
crawler http://google.com
```

## Contributing

1. Fork it ( http://github.com/anupom/crawler/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
