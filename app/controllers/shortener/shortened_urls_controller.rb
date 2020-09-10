class Shortener::ShortenedUrlsController < ActionController::Base
  # find the real link for the shortened link key and redirect
  def show
    # only use the leading valid characters
    token = /^([#{Shortener.key_chars.join}]*).*/.match(params[:id])[1]

    # pull the link out of the db
    sl = ::Shortener::ShortenedUrl.find_by_unique_key(token)

    if sl
      # don't want to wait for the increment to happen, make it snappy!
      # this is the place to enhance the metrics captured
      # for the system. You could log the request origin
      # browser type, ip address etc.
      # Thread.new do
      #  sl.increment!(:use_count)
      #  ActiveRecord::Base.connection.close
      # end
      # do a 301 redirect to the destination url
      redirect_to add_params(
        sl.url,
        request.params.except(:id, :a, :plea, :action, :controller)
      ), status: :moved_permanently
    else
      # if we don't find the shortened link, redirect to the root
      # make this configurable in future versions
      redirect_to "/"
    end
  end

  private

  # Persist the URL params appended to the shortened URL upon redirect
  def add_params(url, url_params = {})
    uri = URI(url)
    url_params = Hash[URI.decode_www_form(uri.query || "")].merge(url_params)
    uri.query = URI.encode_www_form(url_params)

    uri.to_s
  end
end
