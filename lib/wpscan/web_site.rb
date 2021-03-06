# encoding: UTF-8

class WebSite

  attr_reader :uri

  def initialize(site_url)
    self.url = site_url
  end

  def url=(url)
    @uri = URI.parse(add_trailing_slash(add_http_protocol(url)))
  end

  def url
    @uri.to_s
  end

  # Checks if the remote website is up.
  def online?
    Browser.get(@uri.to_s).code != 0
  end

  def has_basic_auth?
    Browser.get(@uri.to_s).code == 401
  end

  def has_xml_rpc?
    !xml_rpc_url.nil?
  end

  # See http://www.hixie.ch/specs/pingback/pingback-1.0#TOC2.3
  def xml_rpc_url
    unless @xmlrpc_url
      @xmlrpc_url = xml_rpc_url_from_headers() || xml_rpc_url_from_body()
    end
    @xmlrpc_url
  end

  def xml_rpc_url_from_headers
    headers    = Browser.get(@uri.to_s).headers_hash
    xmlrpc_url = nil

    unless headers.nil?
      pingback_url = headers['X-Pingback']
      unless pingback_url.nil? || pingback_url.empty?
        xmlrpc_url = pingback_url
      end
    end
    xmlrpc_url
  end

  def xml_rpc_url_from_body
    body = Browser.get(@uri.to_s).body

    body[%r{<link rel="pingback" href="([^"]+)" ?\/?>}, 1]
  end

  # See if the remote url returns 30x redirect
  # This method is recursive
  # Return a string with the redirection or nil
  def redirection(url = nil)
    redirection = nil
    url ||= @uri.to_s
    response = Browser.get(url)

    if response.code == 301 || response.code == 302
      redirection = response.headers_hash['location']

      # Let's check if there is a redirection in the redirection
      if other_redirection = redirection(redirection)
        redirection = other_redirection
      end
    end

    redirection
  end

  # Return the MD5 hash of the page given by url
  def self.page_hash(url)
    Digest::MD5.hexdigest(Browser.get(url).body)
  end

  def homepage_hash
    unless @homepage_hash
      @homepage_hash = WebSite.page_hash(@uri.to_s)
    end
    @homepage_hash
  end

  # Return the MD5 hash of a 404 page
  def error_404_hash
    unless @error_404_hash
      non_existant_page = Digest::MD5.hexdigest(rand(999_999_999).to_s) + '.html'
      @error_404_hash   = WebSite.page_hash(@uri.merge(non_existant_page).to_s)
    end
    @error_404_hash
  end

  # Will try to find the rss url in the homepage
  # Only the first one found iw returned
  def rss_url
    homepage_body = Browser.get(@uri.to_s).body
    homepage_body[%r{<link .* type="application/rss\+xml" .* href="([^"]+)" />}, 1]
  end

  # Checks if a robots.txt file exists
  def has_robots?
    Browser.get(robots_url).code == 200
  end

  # Gets a robots.txt URL
  def robots_url
    robots = @uri.clone
    robots.path = '/robots.txt'
    robots.to_s
  end
end
