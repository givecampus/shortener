module Shortener::ShortenerHelper

  # generate a url from a url string
  def short_url(url, user=nil, project_id)
    short_url = Shortener::ShortenedUrl.generate(url, user, project_id)
    short_url ? url_for(:controller => :"shortener/shortened_urls", :action => :show, :id => short_url.unique_key, :only_path => false) : url
  end

end
