class Shortener::ShortenedUrlsController < ActionController::Base
  # find the real link for the shortened link key and redirect
  def show
    # only use the leading valid characters
    token = /^([#{Shortener.key_chars.join}]*).*/.match(params[:id])[1]

    # pull the link out of the db
    sl = ::Shortener::ShortenedUrl.find_by_unique_key(token)

    if sl
      # Perform a 301 redirect to the destination url, while persisting allowed URL parameters
      redirect_to add_params(
        sl.url,
        request.params.slice(*allowed_params)
      ), status: :moved_permanently
    else
      # If we don't find the shortened link, redirect to the root
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

  def allowed_params
    [:utm_source, :utm_medium, :utm_campaign, :utm_term, :utm_content]
  end
end
