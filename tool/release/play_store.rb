require 'json'
require 'fastlane'
require 'supply'
require 'supply/client'

# Supply sets five transport retries by default. An ambiguous mutation must
# be inspected before another attempt; authentication credentials stay private.
module NoBlindPlayRetries
  def initialize(**args)
    super
    client.request_options.retries = 0
  end
end
Supply::Client.prepend(NoBlindPlayRetries)
ENV['SUPPLY_UPLOAD_MAX_RETRIES'] = '0'
ENV['FASTLANE_SKIP_UPDATE_CHECK'] = 'true'
ENV['FASTLANE_OPT_OUT_USAGE'] = 'true'
ENV.delete('DEBUG')
Google::Apis.logger.level = Logger::WARN

module ProkatPlayStore
  PACKAGE = 'com.auyltech.prokat'.freeze
  PublishGuard = Struct.new(:track, :version_code, :began, :edit_id)

  # Fixed text only. This class is not a Google::Apis::Error, so Supply's
  # call_google_api cannot rewrite it into a FastlaneError that quotes the body.
  class ChangesInReview < StandardError
    MESSAGE = 'PLAY_CHANGES_IN_REVIEW: commit refused, edit not committed; inspect Play Console before any retry'.freeze
    def initialize
      super(MESSAGE)
    end
  end

  class TrackNotClean < StandardError
    def initialize(status)
      token = status.to_s[/\A[A-Za-z0-9_.-]{1,64}\z/] || 'unrecognized'
      super("PLAY_PRODUCTION_TRACK_NOT_CLEAN status=#{token}")
    end
  end

  module ErrorIfInReview
    def commit_edit(*args, changes_in_review_behavior: nil, **kwargs, &block)
      unless ProkatPlayStore.review_behavior_parameter?(method(__method__).super_method)
        raise 'commit_edit is missing changes_in_review_behavior; state UNKNOWN'
      end
      # The caller's value is ignored. ERROR_IF_IN_REVIEW never cancels a review.
      super(*args, changes_in_review_behavior: 'ERROR_IF_IN_REVIEW', **kwargs, &block)
    rescue Google::Apis::ClientError => error
      raise ChangesInReview if ProkatPlayStore.changes_already_in_review?(error)
      raise
    end
  end

  module GuardedPublishEdit
    def begin_edit(package_name: nil)
      guard = ProkatPlayStore.publish_guard
      raise TrackNotClean, 'reentered' if guard&.began
      result = super
      return result unless guard

      guard.began = true
      guard.edit_id = current_edit&.id
      raise TrackNotClean, 'edit_mismatch' if guard.edit_id.nil?
      ProkatPlayStore.verify_publish_edit!(self, guard)
      result
    end

    def update_track(track_name, track_object)
      guard = ProkatPlayStore.publish_guard
      if guard
        raise TrackNotClean, 'track_mismatch' unless track_name.to_s == guard.track
        ProkatPlayStore.verify_track_releases!(self, track_name)
        ProkatPlayStore.refuse_unexpected_release!(track_object, guard)
      end
      super
    end
  end

  # Every production track write reaches AndroidPublisherService#update_edit_track,
  # including Supply::Client#upload_changelogs. Check the object that super sends.
  module GuardedTrackWrite
    def update_edit_track(package_name, edit_id, track, track_object = nil, **kwargs, &block)
      ProkatPlayStore.refuse_unguarded_track_write!(package_name, edit_id, track, track_object)
      super
    end
  end

  def self.publish_guard
    defined?(@publish_guard) ? @publish_guard : nil
  end

  def self.guard_publish!(track:, version_code:)
    raise 'Publish guard is already enabled' if publish_guard
    raise 'Publish guard only applies to the production track' unless track == 'production'
    @publish_guard = PublishGuard.new(track, version_code(version_code), false, nil)
  end

  def self.refuse_unguarded_track_write!(package_name, edit_id, track, track_object)
    guard = publish_guard
    return unless guard
    raise TrackNotClean, 'package_mismatch' unless package_name.to_s == PACKAGE
    raise TrackNotClean, 'edit_mismatch' unless guard.edit_id && edit_id.to_s == guard.edit_id.to_s
    raise TrackNotClean, 'track_mismatch' unless track.to_s == guard.track
    refuse_unexpected_release!(track_object, guard)
  end

  def self.refuse_unexpected_release!(track_object, guard)
    releases = Array(track_object&.releases)
    raise TrackNotClean, 'track_object' unless releases.length == 1 && releases[0].status.to_s == 'completed'
    raise TrackNotClean, 'track_object' unless release_codes(releases[0]) == [guard.version_code]
  end

  def self.release_codes(release)
    Array(release.version_codes).map { |code| version_code(code) }
  end

  def self.review_behavior_parameter?(method)
    method.parameters.any? { |kind, name| %i[key keyreq].include?(kind) && name == :changes_in_review_behavior }
  end

  def self.changes_already_in_review?(error)
    return false unless error.status_code.to_i == 400
    details = parsed_error_details(error.body)
    details.any? { |item| item.is_a?(Hash) && item['reason'] == 'CHANGES_ALREADY_IN_REVIEW' }
  end

  def self.parsed_error_details(body)
    data = case body
           when String
             return [] if body.empty?
             JSON.parse(body)
           when Hash
             body
           else
             return []
           end
    details = data.dig('error', 'details')
    details.is_a?(Array) ? details : []
  rescue JSON::ParserError, TypeError
    []
  end

  def self.verify_publish_edit!(supply, guard)
    verify_track_releases!(supply, guard.track)
    api = supply.client
    package = supply.current_package_name
    edit = supply.current_edit.id
    bundle_codes = Array(api.list_edit_bundles(package, edit).bundles).map(&:version_code)
    apk_codes = Array(api.list_edit_apks(package, edit).apks).map(&:version_code)
    present = (bundle_codes + apk_codes).any? { |code| version_code(code) == guard.version_code }
    raise TrackNotClean, 'version_code_present' if present
  end

  def self.verify_track_releases!(supply, track_name)
    supply.tracks(track_name).each do |track|
      Array(track.releases).each do |release|
        status = release.status.to_s
        raise TrackNotClean, status unless status == 'completed'
      end
    end
  end

  def self.version_code(value)
    unless value.to_s.match?(/\A[1-9][0-9]*\z/) && Integer(value).between?(1, 2_100_000_000)
      raise 'Malformed Play versionCode; state UNKNOWN'
    end
    Integer(value)
  end

  def self.snapshot(key)
    account = JSON.parse(File.read(key))
    raise 'A dedicated service-account JSON is required' unless account['type'] == 'service_account'
    client = File.open(key) do |credentials|
      Supply::Client.new(service_account_json: credentials, params: { timeout: 60 })
    end
    client.begin_edit(package_name: PACKAGE)
    begin
      api = client.client
      edit = client.current_edit.id
      bundles = api.list_edit_bundles(PACKAGE, edit).bundles || []
      apks = api.list_edit_apks(PACKAGE, edit).apks || []
      tracks = (api.list_edit_tracks(PACKAGE, edit).tracks || []).flat_map do |track|
        (track.releases || []).map { |r| { 'track' => track.track, 'status' => r.status, 'codes' => (r.version_codes || []).map { |code| version_code(code) } } }
      end
      codes = (bundles.map(&:version_code) + apks.map(&:version_code) + tracks.flat_map { |t| t.fetch('codes') }).map { |code| version_code(code) }.uniq
      language = api.get_edit_detail(PACKAGE, edit).default_language
      raise 'Primary Play locale is not covered by Git release notes' unless %w[ru-RU en-US kk].include?(language)
      { package: PACKAGE, observed_at: Time.now.utc.to_s, primary_locale: language, codes: codes.sort, tracks: tracks }
    ensure
      # Creates/deletes a temporary edit only. No upload, track update, validate
      # or commit; if abort fails, the caller reports UNKNOWN, never success.
      client.abort_current_edit
    end
  end
end

service = Google::Apis::AndroidpublisherV3::AndroidPublisherService
unless ProkatPlayStore.review_behavior_parameter?(service.instance_method(:commit_edit))
  raise 'commit_edit is missing changes_in_review_behavior; refusing to load'
end
track_write = service.instance_method(:update_edit_track).parameters
unless [[:req, :package_name], [:req, :edit_id], [:req, :track], [:opt, :track_object]].all? { |item| track_write.include?(item) }
  raise "update_edit_track signature changed: #{track_write.inspect}"
end
service.prepend(ProkatPlayStore::ErrorIfInReview)
service.prepend(ProkatPlayStore::GuardedTrackWrite)
Supply::Client.prepend(ProkatPlayStore::GuardedPublishEdit)
