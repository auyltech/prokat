require 'ostruct'
require 'tempfile'
require_relative 'play_store'

def verify_case(api_failure: false, abort_failure: false, locale: 'ru-RU')
  api = Object.new
  api.define_singleton_method(:list_edit_bundles) { |*_| OpenStruct.new(bundles: [OpenStruct.new(version_code: 18)]) }
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
    if api_failure || abort_failure || locale == 'unsupported'
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
auth = Object.new
auth.define_singleton_method(:fetch_access_token!) { {} }
client = Supply::Client.new(auth_client: auth, params: { timeout: 60 })
raise 'Blind transport retries still enabled' unless client.client.request_options.retries == 0
puts 'VERIFIED: snapshot, API failure, abort failure, unsupported locale, zero transport retries; no real store requests'
