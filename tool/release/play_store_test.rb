require 'fileutils'
require 'ostruct'
require 'tempfile'
require 'tmpdir'
require 'supply/uploader'
require_relative 'play_store'
require_relative 'play_policy'

def verify_case(api_failure: false, abort_failure: false, locale: 'ru-RU', code: 18)
  api = Object.new
  api.define_singleton_method(:list_edit_bundles) { |*_| OpenStruct.new(bundles: [OpenStruct.new(version_code: code)]) }
  api.define_singleton_method(:list_edit_apks) { |*_| OpenStruct.new(apks: []) }
  api.define_singleton_method(:list_edit_tracks) do |*_|
    raise 'Simulated unavailable tracks API' if api_failure
    OpenStruct.new(tracks: [OpenStruct.new(track: 'internal', releases: [OpenStruct.new(status: 'completed', version_codes: ['18'])])])
  end
  api.define_singleton_method(:get_edit_detail) { |*_| OpenStruct.new(default_language: locale) }
  fake = OpenStruct.new(client: api, current_edit: OpenStruct.new(id: 'fixture'), aborted: false)
  fake.define_singleton_method(:begin_edit) { |**_| }
  fake.define_singleton_method(:abort_current_edit) do
    self.aborted = true
    raise 'Simulated abort failure' if abort_failure
  end
  original = Supply::Client.method(:new)
  Supply::Client.define_singleton_method(:new) { |**_| fake }
  Tempfile.create(['prokat-noncredential-fixture-', '.json']) do |file|
    file.write(JSON.generate(type: 'service_account'))
    file.flush
    failure = nil
    result = nil
    begin
      result = ProkatPlayStore.snapshot(file.path)
    rescue RuntimeError => error
      failure = error
    end
    if api_failure || abort_failure || locale == 'unsupported' || code != 18
      raise 'Expected unknown/blocked state' unless failure
    else
      raise failure if failure
      raise 'Wrong state' unless result[:codes] == [18] && result[:primary_locale] == locale
    end
  end
  raise 'Temporary edit was not aborted' unless fake.aborted
ensure
  Supply::Client.define_singleton_method(:new, original) if original
end

verify_case
verify_case(api_failure: true)
verify_case(abort_failure: true)
verify_case(locale: 'unsupported')
[nil, 'unknown', 0, -1, 2_100_000_001].each { |code| verify_case(code: code) }
auth = Object.new
auth.define_singleton_method(:fetch_access_token!) { {} }
client = Supply::Client.new(auth_client: auth, params: { timeout: 60 })
raise 'Blind transport retries still enabled' unless client.client.request_options.retries == 0

SENTINEL = 'SECRET_SENTINEL'.freeze
REVIEW_BODY = JSON.generate(
  error: {
    code: 400,
    message: "Changes are already in review #{SENTINEL}",
    details: [{ reason: 'CHANGES_ALREADY_IN_REVIEW', '@type': 'type.googleapis.com/google.rpc.ErrorInfo' }]
  }
).freeze

def clear_guard
  if ProkatPlayStore.instance_variable_defined?(:@publish_guard)
    ProkatPlayStore.remove_instance_variable(:@publish_guard)
  end
end

def supply_config
  Supply.config = FastlaneCore::Configuration.create(Supply::Options.available_options, {
    package_name: 'com.auyltech.prokat',
    track: 'production',
    version_code: 25,
    changes_not_sent_for_review: false,
    rescue_changes_not_sent_for_review: false,
    skip_upload_metadata: true,
    skip_upload_apk: true,
    skip_upload_images: true,
    skip_upload_screenshots: true
  })
end

def fail_commit(status:, body:)
  supply_config
  auth = Object.new
  auth.define_singleton_method(:fetch_access_token!) { {} }
  supply = Supply::Client.new(auth_client: auth, params: { timeout: 60 })
  supply.current_edit = OpenStruct.new(id: 'edit-1')
  supply.current_package_name = 'com.auyltech.prokat'
  supply.client.define_singleton_method(:execute_or_queue_command) do |_command, &block|
    raise Google::Apis::ClientError.new('request failed', status_code: status, body: body)
  end
  supply.commit_current_edit!
end

def assert_changes_in_review
  fail_commit(status: 400, body: REVIEW_BODY)
  raise 'Expected ChangesInReview'
rescue ProkatPlayStore::ChangesInReview => error
  raise 'ChangesInReview was rewritten as FastlaneError' if error.is_a?(FastlaneCore::Interface::FastlaneError)
  raise 'ChangesInReview inherited Google::Apis::Error' if error.is_a?(Google::Apis::Error)
  raise 'Fixed message changed' unless error.message == ProkatPlayStore::ChangesInReview::MESSAGE
  raise 'Response body leaked' if error.message.include?(SENTINEL)
  line = PlayPolicy.publish_failure_line(error)
  raise 'Displayed line leaked a response body' if line.include?(SENTINEL)
  raise 'Displayed line is not the fixed code' unless line == ProkatPlayStore::ChangesInReview::MESSAGE
end

def assert_unclassified(status:, body:)
  fail_commit(status: status, body: body)
  raise 'Expected FastlaneError'
rescue FastlaneCore::Interface::FastlaneError => error
  line = PlayPolicy.publish_failure_line(error)
  raise 'Unclassified line leaked a response body' if line.include?(SENTINEL) || line.include?(error.message)
  raise 'Unclassified line must stay UNKNOWN' unless line.include?('UNKNOWN')
  raise 'Unclassified line claimed a commit' if line.include?('PLAY_EDIT_COMMITTED')
end

def release_row(status:, codes: [24])
  OpenStruct.new(status: status, version_codes: codes)
end

def track_row(status:, codes: [24], name: 'production')
  OpenStruct.new(track: name, releases: [release_row(status: status, codes: codes)])
end

def scripted_client(calls, tracks:, bundles: [], apks: [])
  queue = tracks.dup
  api = Object.new
  api.define_singleton_method(:insert_edit) do |*|
    calls << :insert_edit
    OpenStruct.new(id: 'edit-1')
  end
  api.define_singleton_method(:list_edit_tracks) do |*|
    calls << :list_edit_tracks
    OpenStruct.new(tracks: queue.shift || [])
  end
  api.define_singleton_method(:list_edit_bundles) do |*|
    calls << :list_edit_bundles
    OpenStruct.new(bundles: bundles.map { |code| OpenStruct.new(version_code: code) })
  end
  api.define_singleton_method(:list_edit_apks) do |*|
    calls << :list_edit_apks
    OpenStruct.new(apks: apks.map { |code| OpenStruct.new(version_code: code) })
  end
  api.define_singleton_method(:update_edit_track) do |*|
    calls << :update_edit_track
    nil
  end
  api.define_singleton_method(:commit_edit) do |*|
    calls << :commit_edit
    nil
  end
  auth = Object.new
  auth.define_singleton_method(:fetch_access_token!) { {} }
  supply = Supply::Client.new(auth_client: auth, params: { timeout: 60 })
  supply.instance_variable_set(:@client, api)
  supply
end

def refute_mutation(calls)
  raise 'Upload or commit ran' if (calls & [:update_edit_track, :commit_edit, :upload_bundle]).any?
end

assert_changes_in_review
assert_unclassified(status: 403, body: JSON.generate(error: { message: SENTINEL, details: [{ reason: 'PERMISSION_DENIED' }] }))
assert_unclassified(status: 400, body: JSON.generate(error: { message: SENTINEL, details: [{ reason: 'OTHER' }] }))

prod = { 'platform' => 'android', 'channel' => 'production', 'build' => 25, 'destination' => 'production' }
raise unless PlayPolicy.check!(prod, [], 18, [{ 'track' => 'production', 'status' => 'completed', 'codes' => [24] }]) == 'production'
clear_guard
calls = []
supply = scripted_client(calls, tracks: [[track_row(status: 'draft')]])
ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
begin
  supply.begin_edit(package_name: 'com.auyltech.prokat')
  raise 'Draft that appeared after preflight was accepted'
rescue ProkatPlayStore::TrackNotClean => error
  raise 'Track status leaked a body' if error.message.include?(SENTINEL)
  raise 'Draft was not classified' unless error.message.include?('status=draft')
end
refute_mutation(calls)

%w[halted statusUnspecified weird].each do |status|
  clear_guard
  calls = []
  supply = scripted_client(calls, tracks: [[track_row(status: status)]])
  ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
  begin
    supply.begin_edit(package_name: 'com.auyltech.prokat')
    raise "#{status} was accepted"
  rescue ProkatPlayStore::TrackNotClean
  end
  refute_mutation(calls)
end

clear_guard
calls = []
supply = scripted_client(calls, tracks: [[track_row(status: 'completed')], [track_row(status: 'inProgress')]])
ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
supply.begin_edit(package_name: 'com.auyltech.prokat')
begin
  supply.update_track('production', OpenStruct.new(releases: [release_row(status: 'completed', codes: [25])]))
  raise 'inProgress discovered at update_track was accepted'
rescue ProkatPlayStore::TrackNotClean => error
  raise 'inProgress was not classified' unless error.message.include?('status=inProgress')
end
refute_mutation(calls)

clear_guard
calls = []
supply = scripted_client(calls, tracks: [[track_row(status: 'completed', codes: [])]], bundles: [25])
ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
begin
  supply.begin_edit(package_name: 'com.auyltech.prokat')
  raise 'Existing bundle version was accepted'
rescue ProkatPlayStore::TrackNotClean => error
  raise 'Bundle collision was not classified' unless error.message.include?('status=version_code_present')
end
refute_mutation(calls)

clear_guard
calls = []
supply = scripted_client(calls, tracks: [[track_row(status: 'completed', codes: [])]])
ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
supply.begin_edit(package_name: 'com.auyltech.prokat')
[ [release_row(status: 'completed', codes: [25]), release_row(status: 'completed', codes: [24])],
  [release_row(status: 'completed', codes: [26])] ].each do |releases|
  begin
    supply.update_track('production', OpenStruct.new(releases: releases))
    raise 'Malformed track object was accepted'
  rescue ProkatPlayStore::TrackNotClean => error
    raise 'Track object refusal leaked data' if error.message.include?('26') || error.message.include?(SENTINEL)
    raise 'Track object was not classified' unless error.message.include?('status=track_object')
  end
end
refute_mutation(calls)

clear_guard
calls = []
supply = scripted_client(calls, tracks: [[track_row(status: 'completed', codes: [])]])
supply.begin_edit(package_name: 'com.auyltech.prokat')
supply.update_track('production', OpenStruct.new(releases: [release_row(status: 'completed', codes: [25])]))
raise 'Unguarded RC path read the publish edit' if calls.include?(:list_edit_tracks) || calls.include?(:list_edit_bundles)
raise 'Unguarded update did not reach update_edit_track' unless calls.include?(:update_edit_track)
raise 'Unguarded path committed' if calls.include?(:commit_edit)

clear_guard
calls = []
supply = scripted_client(calls, tracks: [[track_row(status: 'completed', codes: [])]])
ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
supply.begin_edit(package_name: 'com.auyltech.prokat')
supply.current_edit = nil
begin
  supply.begin_edit(package_name: 'com.auyltech.prokat')
  raise 'Second begin_edit was accepted'
rescue ProkatPlayStore::TrackNotClean => error
  raise 'Re-entry was not classified' unless error.message.include?('status=reentered')
end
raise 'Second begin_edit inserted another edit' unless calls.count { |call| call == :insert_edit } == 1
refute_mutation(calls)

clear_guard
begin
  ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
  ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
  raise 'Publish guard was enabled twice'
rescue RuntimeError => error
  raise 'Second guard leaked data' if error.message.include?(SENTINEL)
end

class RecordingStdout
  def initialize(original)
    @original = original
    @buffer = +''
  end

  attr_reader :buffer

  def write(data)
    @buffer << data.to_s
    @original.write(data)
  end

  def method_missing(name, *args, **kwargs, &block)
    @original.public_send(name, *args, **kwargs, &block)
  end

  def respond_to_missing?(name, include_private = false)
    @original.respond_to?(name, include_private)
  end
end

def capture_stdout
  original = $stdout
  recorder = RecordingStdout.new(original)
  $stdout = recorder
  yield
  recorder.buffer
ensure
  $stdout = original
end

def assert_written_release(write, edit_id)
  raise 'Track write used another edit' unless write[:edit] == edit_id
  raise 'Track write used another track' unless write[:track] == 'production'
  releases = Array(write[:object]&.releases)
  raise 'Track write was not the expected release' unless releases.length == 1 && releases[0].status.to_s == 'completed'
  raise 'Track write versionCode drifted' unless Array(releases[0].version_codes) == [25]
end

def production_release_track(extra: false)
  releases = [AndroidPublisher::TrackRelease.new(status: 'completed', version_codes: [25], name: '1.2.3')]
  releases << AndroidPublisher::TrackRelease.new(status: 'completed', version_codes: [24], name: 'previous') if extra
  AndroidPublisher::Track.new(track: 'production', releases: releases)
end

# Drives the pinned Supply::Uploader path. execute_or_queue_command is the
# boundary below update_edit_track; nothing here opens a store connection.
def drive_release_notes(dirty_notes:)
  Dir.mktmpdir('prokat-notes-') do |dir|
    FileUtils.mkdir_p(File.join(dir, 'ru-RU', 'changelogs'))
    File.write(File.join(dir, 'ru-RU', 'changelogs', '25.txt'), "Ship notes\n")
    File.write(File.join(dir, 'app.aab'), '')
    state = { lists: 0, writes: [], commits: [] }
    auth = Object.new
    auth.define_singleton_method(:fetch_access_token!) { {} }
    supply = Supply::Client.new(auth_client: auth, params: { timeout: 60 })
    supply.client.define_singleton_method(:execute_or_queue_command) do |command, &block|
      pattern = command.url.respond_to?(:pattern) ? command.url.pattern.to_s : command.url.to_s
      verb = command.method
      if pattern.include?(':commit')
        state[:commits] << command.params['editId']
        next OpenStruct.new(id: 'edit-guarded')
      end
      if verb == :put && pattern.include?('/tracks/')
        state[:writes] << { edit: command.params['editId'], track: command.params['track'], object: command.request_object }
        next command.request_object
      end
      if verb == :get && pattern.include?('/listings/')
        raise Google::Apis::ClientError.new('missing listing', status_code: 404, body: '{}')
      end
      if verb == :get && pattern.include?('/tracks')
        state[:lists] += 1
        track = dirty_notes && state[:lists] >= 4 ? production_release_track(extra: true) : production_release_track
        next OpenStruct.new(tracks: [track])
      end
      if verb == :get && pattern.include?('/bundles')
        next OpenStruct.new(bundles: [])
      end
      if verb == :get && pattern.include?('/apks')
        next OpenStruct.new(apks: [])
      end
      if verb == :post && pattern.include?('/bundles')
        next OpenStruct.new(version_code: 25)
      end
      if verb == :post && pattern.include?('/edits')
        next OpenStruct.new(id: 'edit-guarded')
      end
      raise "Unexpected Play command #{verb} #{pattern}"
    end
    Supply.config = FastlaneCore::Configuration.create(Supply::Options.available_options, {
      package_name: 'com.auyltech.prokat',
      aab: File.join(dir, 'app.aab'),
      metadata_path: dir,
      track: 'production',
      version_code: 25,
      version_name: '1.2.3',
      release_status: 'completed',
      changes_not_sent_for_review: false,
      rescue_changes_not_sent_for_review: false,
      skip_upload_metadata: true,
      skip_upload_images: true,
      skip_upload_screenshots: true,
      skip_upload_apk: true,
      skip_upload_changelogs: false,
      timeout: 60
    })
    ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
    uploader = Supply::Uploader.new
    uploader.instance_variable_set(:@client, supply)
    error = nil
    output = capture_stdout do
      begin
        uploader.perform_upload
      rescue StandardError => failure
        error = failure
      end
    end
    state.merge(supply: supply, error: error, output: output)
  end
end

ENV['FL_NUMBER_OF_THREADS'] = '1'
clear_guard
happy = drive_release_notes(dirty_notes: false)
raise "Release notes path failed: #{happy[:error].class}: #{happy[:error].message}" if happy[:error]
raise 'Release notes path printed a commit marker' if happy[:output].include?('PLAY_EDIT_COMMITTED')
raise "Release notes path wrote #{happy[:writes].length} tracks" unless happy[:writes].length == 2
happy[:writes].each { |write| assert_written_release(write, 'edit-guarded') }
note_text = Array(happy[:writes][1][:object].releases[0].release_notes).map { |note| note.text.to_s }
raise 'Written release notes lost the changelog' unless note_text.any? { |text| text.include?('Ship notes') }
raise 'Commit used another edit' unless happy[:commits] == ['edit-guarded']
raise 'Guard edit diverged from the committed edit' unless ProkatPlayStore.publish_guard.edit_id == 'edit-guarded'
written = happy[:writes].length
[
  ['other-edit', 'production', production_release_track, 'edit_mismatch'],
  ['edit-guarded', 'internal', production_release_track, 'track_mismatch'],
  ['edit-guarded', 'production', production_release_track(extra: true), 'track_object']
].each do |edit_id, track_name, track_object, token|
  begin
    happy[:supply].client.update_edit_track('com.auyltech.prokat', edit_id, track_name, track_object)
    raise "Direct #{token} write was accepted"
  rescue ProkatPlayStore::TrackNotClean => error
    raise "Direct write was not classified #{token}" unless error.message.include?("status=#{token}")
  end
end
raise 'A bypass reached update_edit_track' unless happy[:writes].length == written && happy[:commits] == ['edit-guarded']
begin
  happy[:supply].client.update_edit_track(
    'com.auyltech.prokat',
    'edit-guarded',
    'production',
    OpenStruct.new(releases: [release_row(status: 'completed', codes: ['010'])])
  )
  raise 'Service accepted a leading-zero versionCode'
rescue RuntimeError => error
  raise 'Service leading-zero versionCode was not rejected' unless error.message.include?('Malformed')
end
raise 'Leading-zero versionCode reached the API' unless happy[:writes].length == written && happy[:commits] == ['edit-guarded']

clear_guard
unsafe = drive_release_notes(dirty_notes: true)
raise 'Unsafe release notes were written' unless unsafe[:error].is_a?(ProkatPlayStore::TrackNotClean) && unsafe[:error].message.include?('status=track_object')
raise 'Unsafe release notes reached commit_edit' unless unsafe[:commits].empty?
raise 'Unsafe release notes printed a commit marker' if unsafe[:output].include?('PLAY_EDIT_COMMITTED')
raise "Unsafe path wrote #{unsafe[:writes].length} tracks" unless unsafe[:writes].length == 1
assert_written_release(unsafe[:writes][0], 'edit-guarded')

clear_guard
calls = []
supply = scripted_client(calls, tracks: [[track_row(status: 'completed', codes: [])]])
ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
supply.begin_edit(package_name: 'com.auyltech.prokat')
begin
  supply.update_track('internal', OpenStruct.new(releases: [release_row(status: 'completed', codes: [25])]))
  raise 'Mismatched track_name was accepted'
rescue ProkatPlayStore::TrackNotClean => error
  raise 'Mismatched track was not classified' unless error.message.include?('status=track_mismatch')
end
refute_mutation(calls)

clear_guard
calls = []
supply = scripted_client(calls, tracks: [[track_row(status: 'completed', codes: [])], [track_row(status: 'completed', codes: [])]])
ProkatPlayStore.guard_publish!(track: 'production', version_code: 25)
supply.begin_edit(package_name: 'com.auyltech.prokat')
supply.update_track('production', OpenStruct.new(releases: [release_row(status: 'completed', codes: [25])]))
raise 'Expected versionCode did not reach update_edit_track' unless calls.include?(:update_edit_track)
raise 'Expected versionCode committed' if calls.include?(:commit_edit)

clear_guard
raise 'Ruby octal baseline drifted' unless Integer('010') == 8
begin
  ProkatPlayStore.version_code('010')
  raise 'Leading zero was accepted'
rescue RuntimeError => error
  raise 'Leading zero bypassed version_code' unless error.message == 'Malformed Play versionCode; state UNKNOWN'
end
raise 'Ordinary versionCode drifted' unless ProkatPlayStore.version_code(25) == 25 && ProkatPlayStore.version_code('25') == 25
calls = []
supply = scripted_client(calls, tracks: [[track_row(status: 'completed', codes: [])]])
ProkatPlayStore.guard_publish!(track: 'production', version_code: 8)
supply.begin_edit(package_name: 'com.auyltech.prokat')
begin
  supply.update_track('production', OpenStruct.new(releases: [release_row(status: 'completed', codes: ['010'])]))
  raise 'Octal versionCode was written'
rescue RuntimeError => error
  raise 'Octal versionCode was not rejected' unless error.message.include?('Malformed')
end
refute_mutation(calls)

clear_guard
%w[0 08 25abc].each do |bad|
  begin
    ProkatPlayStore.version_code(bad)
    raise "#{bad.inspect} was accepted"
  rescue RuntimeError => error
    raise "#{bad.inspect} was not rejected" unless error.message.include?('Malformed')
  end
end

clear_guard
rc_executed = false
auth = Object.new
auth.define_singleton_method(:fetch_access_token!) { {} }
rc = Supply::Client.new(auth_client: auth, params: { timeout: 60 })
rc.client.define_singleton_method(:execute_or_queue_command) do |command, &block|
  rc_executed = command.method == :put && command.params['track'] == 'internal'
  nil
end
rc.client.update_edit_track('com.auyltech.prokat', 'rc-edit', 'internal', OpenStruct.new(releases: [release_row(status: 'draft', codes: ['010'])]))
raise 'RC track write was blocked' unless rc_executed

puts 'VERIFIED: snapshot, commit classification, publish-edit guard, and zero transport retries; no real store requests'
