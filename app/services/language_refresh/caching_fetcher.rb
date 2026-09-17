module LanguageRefresh
  # One Run reads each file once. Two stages need Glottolog's table, so the second is answered from
  # what the first downloaded, which also guarantees they read the same bytes. A Run gets its own
  # one of these, so the next Run downloads afresh.
  class CachingFetcher
    def initialize(fetcher)
      @fetcher = fetcher
      @responses = {}
    end

    def get(url)
      @responses[url] ||= @fetcher.get(url)
    end
  end
end
