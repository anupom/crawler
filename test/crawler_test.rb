require 'crawler'
require 'stringio'
require 'test/unit'
require 'webmock/test_unit'

class CrawlerTest < Test::Unit::TestCase
  # Called before every test method runs. Can be used
  # to set up fixture information.
  def setup
    # Do nothing
  end

  # Called after every test method runs. Can be used to tear
  # down fixture information.

  def teardown
    # Do nothing
  end

  def test_with_nil_url
    assert_raise URI::InvalidURIError do
      crawler = Crawler.new(nil)
      crawler.crawl
    end
  end

  def test_with_invalid_url
    crawler = Crawler.new('https:/xyz.invalidurl.com/')
    crawler.crawl
    map = crawler.map
    assert_equal({}, map)
  end

  def test_with_valid_url
    url1 = 'http://www.example.com'
    url2 = 'http://www.example.com/test.html'

    stub_response_link(url1, url2)
    stub_response_empty(url2)

    crawler = Crawler.new(url1)
    crawler.crawl
    map = crawler.map
    assert(map.key?(url1))
    assert_equal(map[url1].neighbors, [url2])
  end

  def test_with_relative_links
    url1 = 'http://www.example.com/test/test.html'
    url2 = 'http://www.example.com/test/test2.html'
    url3 = 'http://www.example.com/test3.html'

    stub_response_link(url1, 'test2.html')
    stub_response_link(url2, '/test3.html')
    stub_response_empty(url3)

    crawler = Crawler.new(url1)
    crawler.crawl
    map = crawler.map
    assert(map.key?(url1))
    assert_equal(map[url1].neighbors, [url2])
    assert(map.key?(url2))
    assert_equal(map[url2].neighbors, [url3])
    assert(map.key?(url3))
    assert_equal(map[url3].neighbors, [])
  end

  def test_with_unavailable_links
    url1 = 'http://www.example.com'
    url2 = 'http://www.example.com/test.html'
    url3 = 'http://www.example.com/unavailable'

    stub_response_link(url1, url2)
    stub_response_link(url2, url3)
    stub_response_not_found(url3)

    crawler = Crawler.new(url1)
    crawler.crawl
    map = crawler.map
    assert(!map.key?(url3))
  end

  def test_with_external_links
    url1 = 'http://www.example.com/test/test.html'
    url2 = 'http://www.google.com/test/test2.html'

    stub_response_link(url1, url2)

    crawler = Crawler.new(url1)
    crawler.crawl
    map = crawler.map
    assert(map.key?(url1))
    assert_equal(map[url1].neighbors, [])
  end

  def test_with_invalid_links
    url1 = 'http://www.example.com/test/test.html'
    url2 = ':// test/test2.html'

    stub_response_link(url1, url2)

    crawler = Crawler.new(url1)
    crawler.crawl
    map = crawler.map
    assert(map.key?(url1))
    assert_equal(map[url1].neighbors, [])
  end

  def test_with_multiple_links
    url1 = 'http://www.example.com/test/test.html'
    url2 = 'http://www.example.com/test/test2.html'
    url3 = 'http://www.example.com/test3.html'

    stub_response_two_links(url1, url2, url3)
    stub_response_empty(url2)
    stub_response_empty(url3)

    crawler = Crawler.new(url1)
    crawler.crawl
    map = crawler.map
    assert(map.key?(url1))
    assert_equal(map[url1].neighbors, [url2, url3])
    assert(map.key?(url2))
    assert_equal(map[url2].neighbors, [])
    assert(map.key?(url3))
    assert_equal(map[url3].neighbors, [])
  end

  def test_with_same_links
    url1 = 'http://www.example.com/test/test.html'
    url2 = 'http://www.example.com/test/test2.html'
    url3 = url1

    stub_response_two_links(url1, url2, url3)
    stub_response_empty(url2)

    crawler = Crawler.new(url1)
    crawler.crawl
    map = crawler.map
    assert(map.key?(url1))
    assert_equal(map[url1].neighbors, [url2])
    assert(map.key?(url2))
    assert_equal(map[url2].neighbors, [])
  end

  def test_with_same_links_with_different_fragments
    url1 = 'http://www.example.com/test/test.html'
    url2 = 'http://www.example.com/test/test2.html'
    url3 = url1 + '#fragment'

    stub_response_two_links(url1, url2, url3)
    stub_response_empty(url2)

    crawler = Crawler.new(url1)
    crawler.crawl
    map = crawler.map
    assert(map.key?(url1))
    assert_equal(map[url1].neighbors, [url2])
    assert(map.key?(url2))
    assert_equal(map[url2].neighbors, [])
  end

  def test_with_non_http_link
    url1 = 'http://www.example.com/test/test.html'
    url2 = 'http://www.example.com/test/test2.html'
    url3 = 'mailto:mail@example.com'

    stub_response_two_links(url1, url2, url3)
    stub_response_empty(url2)

    crawler = Crawler.new(url1)
    crawler.crawl
    map = crawler.map
    assert(map.key?(url1))
    assert_equal(map[url1].neighbors, [url2])
    assert(map.key?(url2))
    assert_equal(map[url2].neighbors, [])
  end

  def test_with_statics
    url1 = 'http://www.example.com'

    stub_request(:get, url1).to_return(
      body: '<link rel="stylesheet" href="test.css" />'\
        '<script src="test.js"></script>'\
        '<img src="test.png" />'
    )

    crawler = Crawler.new(url1)
    crawler.crawl
    map = crawler.map
    assert(map.key?(url1))
    assert_equal(map[url1].statics, %w(test.js test.css test.png))
  end

  def test_print
    url1 = 'http://www.example.com'
    url2 = 'http://www.example.com/test.html'

    stub_response_link(url1, url2)
    stub_response_empty(url2)

    crawler = Crawler.new(url1)
    crawler.crawl

    printed = capture_stdout do
      crawler.print
    end

    assert_match(/#{url1}/, printed)
    assert_match(/#{url2}/, printed)
  end

  private

  def stub_response_link(url, link)
    stub_request(:get, url).to_return(
      body: %(<body><a href="#{link}">test</a></body>")
    )
  end

  def stub_response_two_links(url, link1, link2)
    stub_request(:get, url).to_return(
      body: %(<body><a href="#{link1}">t1</a><a href="#{link2}">t2</a></body>)
    )
  end

  def stub_response_empty(url)
    stub_request(:get, url).to_return(
      body: '<body>stub body</body>'
    )
  end

  def stub_response_not_found(url)
    stub_request(:get, url).to_return(
      status: 404
    )
  end

  def capture_stdout(&blk)
    old = $stdout
    $stdout = fake = StringIO.new
    blk.call
    fake.string
  ensure
    $stdout = old
  end
end
