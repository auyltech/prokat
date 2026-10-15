require 'json'
require 'fastlane'
require 'supply'
require 'supply/client'
require 'supply/options'
require 'supply/uploader'
require_relative 'play_policy'

# Supply 2.241.0 defaults its Google transport to five retries. Disable those
# for every created client: an ambiguous upload/commit must be inspected first.
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

PACKAGE = 'com.auyltech.prokat'.freeze
ROOT = File.expand_path('../..', __dir__)
CONTEXT = File.join(ROOT, 'build/release/context.json')
KEY = File.join(ROOT, 'build/release/play-service-account.json')

def snapshot_and_check(context)
  floor = ENV.fetch('PLAY_HISTORICAL_MAX_BUILD')
  raise 'PLAY_HISTORICAL_MAX_BUILD must be confirmed at U2 (zero only for a confirmed new app)' unless floor.match?(/\A(?:0|[1-9][0-9]*)\z/)
  client = Supply::Client.new(service_account_json: File.open(KEY), params: { timeout: 60 })
  client.begin_edit(package_name: PACKAGE)
  edit = client.current_edit.id
  begin
    api = client.client
    bundles = api.list_edit_bundles(PACKAGE, edit).bundles || []
    apks = api.list_edit_apks(PACKAGE, edit).apks || []
    tracks = (api.list_edit_tracks(PACKAGE, edit).tracks || []).flat_map do |track|
      (track.releases || []).map { |r| { 'track' => track.track, 'status' => r.status, 'codes' => (r.version_codes || []).map(&:to_i) } }
    end
    codes = (bundles.map(&:version_code) + apks.map(&:version_code) + tracks.flat_map { |t| t.fetch('codes') }).map(&:to_i).uniq
    language = api.get_edit_detail(PACKAGE, edit).default_language
    raise 'Primary Play locale is not covered by Git release notes; configure mapping first' unless %w[ru-RU en-US kk].include?(language)
    state = { package: PACKAGE, observed_at: Time.now.utc.to_s, codes: codes.sort, tracks: tracks, historical_floor: Integer(floor) }
    File.write(File.join(ROOT, 'build/release/play-state.json'), JSON.pretty_generate(state))
    puts JSON.generate(state)
    PlayPolicy.check!(context, codes, Integer(floor), tracks)
  ensure
    # This edit was only a snapshot, never commit it. If deletion fails, abort
    # instead of reporting a successful/empty store state.
    client.abort_current_edit
  end
end

begin
  raise 'Expected preflight or publish' unless ARGV.length == 1 && %w[preflight publish].include?(ARGV.first)
  context = JSON.parse(File.read(CONTEXT))
  channel = context.fetch('channel')
  if channel == 'production' && ENV['PRODUCTION_PUBLISHING_ENABLED'] != 'true'
    raise 'Production publishing disabled until U5'
  end
  track = snapshot_and_check(context)
  if ARGV.first == 'publish'
    raise 'Only GitHub tag pushes may publish' unless ENV['GITHUB_EVENT_NAME'] == 'push' && ENV['GITHUB_REF'] == "refs/tags/#{context.fetch('tag')}" && ENV['GITHUB_REF_TYPE'] == 'tag'
    Supply.config = FastlaneCore::Configuration.create(Supply::Options.available_options, {
      package_name: PACKAGE,
      json_key: KEY,
      aab: File.join(ROOT, 'build/app/outputs/bundle/release/app-release.aab'),
      metadata_path: File.join(ROOT, 'build/release/play'),
      track: track,
      version_code: context.fetch('build').to_s,
      version_name: context.fetch('version'),
      release_status: 'completed',
      changes_not_sent_for_review: false,
      rescue_changes_not_sent_for_review: false,
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true,
      skip_upload_apk: true,
      skip_upload_changelogs: false,
      timeout: 300
    })
    Supply::Uploader.new.perform_upload
    puts 'PLAY_EDIT_COMMITTED: store review/managed publishing can still delay availability; verify the track.'
  else
    puts 'PLAY_PREFLIGHT_VERIFIED: current state read; no binary uploaded.'
  end
rescue StandardError => error
  # Store SDK errors may contain HTTP bodies: keep credentials out of output.
  safe = error.class.name.start_with?('Google::') ? "Store API unavailable/rejected (#{error.class}); state UNKNOWN" : error.message
  warn "BLOCKED: #{safe}. No automatic retry. Inspect store state before any next attempt."
  exit 1
end
