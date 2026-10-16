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
