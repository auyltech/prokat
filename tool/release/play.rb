require_relative 'play_store'
require 'supply/options'
require 'supply/uploader'
require_relative 'play_policy'


PACKAGE = 'com.auyltech.prokat'.freeze
ROOT = File.expand_path('../..', __dir__)
CONTEXT = File.join(ROOT, 'build/release/context.json')
KEY = File.join(ROOT, 'build/release/play-service-account.json')

def snapshot_and_check(context)
  floor = ENV.fetch('PLAY_HISTORICAL_MAX_BUILD')
  raise PlayPolicy::Blocked, 'PLAY_HISTORICAL_MAX_BUILD must be confirmed at U2 (zero only for a confirmed new app)' unless floor.match?(/\A(?:0|[1-9][0-9]*)\z/)
  state = ProkatPlayStore.snapshot(KEY).merge(historical_floor: Integer(floor))
  File.write(File.join(ROOT, 'build/release/play-state.json'), JSON.pretty_generate(state))
  puts JSON.generate(state)
  PlayPolicy.check!(context, state.fetch(:codes), Integer(floor), state.fetch(:tracks))
end

begin
  raise PlayPolicy::Blocked, 'Expected preflight or publish' unless ARGV.length == 1 && %w[preflight publish].include?(ARGV.first)
  context = JSON.parse(File.read(CONTEXT))
  channel = context.fetch('channel')
  if channel == 'production' && ENV['PRODUCTION_PUBLISHING_ENABLED'] != 'true'
    raise PlayPolicy::Blocked, 'Production publishing disabled until U5'
  end
  track = snapshot_and_check(context)
  if ARGV.first == 'publish'
    raise PlayPolicy::Blocked, 'Only GitHub tag pushes may publish' unless ENV['GITHUB_EVENT_NAME'] == 'push' && ENV['GITHUB_REF'] == "refs/tags/#{context.fetch('tag')}" && ENV['GITHUB_REF_TYPE'] == 'tag'
    Supply.config = FastlaneCore::Configuration.create(Supply::Options.available_options, {
      package_name: PACKAGE,
      json_key: KEY,
      aab: File.join(ROOT, 'build/app/outputs/bundle/release/app-release.aab'),
      metadata_path: File.join(ROOT, 'build/release/play'),
      track: track,
      version_code: Integer(context.fetch('build')),
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
  safe = PlayPolicy.safe_error(error)
  warn "BLOCKED: #{safe}. No automatic retry. Inspect store state before any next attempt."
  exit 1
end
