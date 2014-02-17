require 'awesome_print'
require 'em-synchrony'
require 'em-synchrony/em-http'
require 'em-synchrony/fiber_iterator'
require 'nokogiri'
require 'set'

class Crawler
  CONCURRENCY = 5
  HTTP_OK = 200
  MAX_REDIRECTS = 3
  MAX_RETRIES = 3
  VALID_SCHEMES = %w(http https)

  Node = Struct.new(:neighbors, :statics)

  attr_reader :map

  def initialize(root_url)
    @map = {}
    @urls_to_crawl = [root_url]
    @root_hostname = URI.parse(root_url).hostname
    @retries = Hash.new { |h, k| h[k] = 0 }
  end

  def crawl
    if @urls_to_crawl.empty?
      EventMachine.stop
      return
    end

    EM.synchrony do
      # Iterate over a copy while we change the main array
      urls = @urls_to_crawl.dup
      @urls_to_crawl.clear

      EM::Synchrony::FiberIterator.new(urls, CONCURRENCY).each do |url|
        next if @map.key?(url)

        http = http_request(url)

        next if http.nil?

        page = Nokogiri::HTML(http.response)
        neighbors = get_neighbors(page, url)
        @urls_to_crawl += neighbors

        statics = get_statics(page)

        @map[url] = Node.new(neighbors, statics)
      end

      crawl
    end
  end

  def print
    ap @map
  end

  protected

  def http_request(url)
    http = EventMachine::HttpRequest.new(url)
      .get redirects: MAX_REDIRECTS

    if http.response_header.status != HTTP_OK
      queue_for_retry(url)
      return nil
    end
    http
  rescue Addressable::URI::InvalidURIError
      nil
  end

  def queue_for_retry(url)
    return if @retries[url] == MAX_RETRIES
    @retries[url] += 1
    @urls_to_crawl.push(url)
  end

  def get_neighbors(page, parent_url)
    neighbors = Set.new
    links = page.css('a')

    links.each do |link|
      href = link['href']

      uri = uri_from_href(href)

      next unless valid_uri?(uri)

      uri = URI.join(parent_url, uri) if relative_uri?(uri)

      # Page fragments are ignored for site map
      uri.fragment = nil

      next if uri.to_s == parent_url

      neighbors.add(uri.to_s)
    end

    neighbors.to_a
  end

  def get_statics(page)
    statics = Set.new

    scripts = page.css('script')
    scripts.each do |script|
      statics.add(script['src'])
    end

    stylesheets = page.css('link[rel="stylesheet"]')
    stylesheets.each do |stylesheet|
      statics.add(stylesheet['href'])
    end

    images = page.css('img')
    images.each do |image|
      statics.add(image['src'])
    end

    statics.to_a
  end

  def uri_from_href(href)
    URI.parse(href)
  rescue URI::InvalidURIError
    nil
  end

  def valid_uri?(uri)
    return false if uri.nil?
    return false unless uri.scheme.nil? || VALID_SCHEMES.include?(uri.scheme)
    return false unless uri.hostname.nil? || uri.hostname == @root_hostname
    true
  end

  def relative_uri?(uri)
    uri.scheme.nil?
  end
end
