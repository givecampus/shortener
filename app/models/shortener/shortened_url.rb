class Shortener::ShortenedUrl < ActiveRecord::Base

  URL_PROTOCOL_HTTP = "http://"
  REGEX_LINK_HAS_PROTOCOL = Regexp.new('\Ahttp:\/\/|\Ahttps:\/\/', Regexp::IGNORECASE)

  validates :url, :presence => true

  # allows the shortened link to be associated with a user
  belongs_to :user, :polymorphic => true
  belongs_to :project

  # ensure the url starts with it protocol and is normalized
  def self.clean_url(url)
    return nil if url.blank?
    url = URL_PROTOCOL_HTTP + url.strip unless url =~ REGEX_LINK_HAS_PROTOCOL
    URI.parse(url).normalize.to_s
  end

  # generate a shortened link from a url
  # link to a user if one specified
  # throw an exception if anything goes wrong
  def self.generate!(orig_url, user=nil, project_id)
    # if we get a shortened_url object with a different owner, generate
    # new one for the new owner. Otherwise return same object
    if orig_url.is_a?(Shortener::ShortenedUrl)
      return orig_url.user == user ? orig_url : generate!(orig_url.url, user, project_id)
    end

    # don't want to generate the link if it has already been generated
    # so check the datastore
    cleaned_url = clean_url(orig_url)
    scope = user ? user.shortened_urls : self
    scope.where(:url => cleaned_url).where(:project_id => project_id).first_or_create
  end

  # return shortened url on success, nil on failure
  def self.generate(orig_url, user=nil, project_id)
    begin
      generate!(orig_url, user, project_id)
    rescue
      nil
    end
  end

  private

  # we'll rely on the DB to make sure the unique key is really unique.
  # if it isn't unique, the unique index will catch this and raise an error
  def _create_record
    count = 0
    begin
      self.unique_key = generate_unique_key
      super()
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::StatementInvalid => err
      logger.info("Shortener gem attempted to generate a unique key and raised the following err: #{err}")
      if (count +=1) < 10
        logger.info("retrying with different unique key")
        retry
      else
        logger.info("too many retries, giving up")
        raise
      end
    end
  end

  # generate a random string
  # future mod to allow specifying a more expansive charst, like utf-8 chinese
  def generate_unique_key
    # not doing uppercase as url is case insensitive
    charset = ::Shortener.key_chars
    (0...::Shortener.unique_key_length).map{ charset[rand(charset.size)] }.join
  end

end
