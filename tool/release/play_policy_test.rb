require_relative 'play_policy'
require 'stringio'

def assert_blocked
  begin
    yield
  rescue RuntimeError
    return
  end
  raise 'Expected policy to block'
end

rc = { 'platform' => 'android', 'channel' => 'rc', 'build' => 108, 'destination' => 'internal' }
raise unless PlayPolicy.check!(rc, [107], 100, []) == 'internal'
assert_blocked { PlayPolicy.check!(rc, [108], 100, [{ 'track' => 'internal', 'status' => 'completed', 'codes' => [108] }]) }
assert_blocked { PlayPolicy.check!(rc, [109], 100, []) }
assert_blocked { PlayPolicy.check!(rc, [], 108, []) }
assert_blocked { PlayPolicy.check!(rc.merge('destination' => 'production'), [], 100, []) }
assert_blocked { PlayPolicy.check!(rc.merge('platform' => 'ios'), [], 100, []) }
prod = rc.merge('channel' => 'production', 'destination' => 'production')
raise unless PlayPolicy.check!(prod, [], 100, []) == 'production'
%w[draft inProgress halted statusUnspecified weird].each do |status|
  assert_blocked { PlayPolicy.check!(prod, [], 100, [{ 'track' => 'production', 'status' => status, 'codes' => [] }]) }
end
raise unless PlayPolicy.check!(prod, [], 100, [{ 'track' => 'production', 'status' => 'completed', 'codes' => [] }]) == 'production'
raise unless PlayPolicy.check!(rc, [], 100, [{ 'track' => 'production', 'status' => 'draft', 'codes' => [] }]) == 'internal'
raise 'SDK/credential body leaked' if PlayPolicy.safe_error(RuntimeError.new('SIMULATED_PRIVATE_RESPONSE')).include?('SIMULATED_PRIVATE_RESPONSE')
raise 'Policy diagnostic lost' unless PlayPolicy.safe_error(PlayPolicy::Blocked.new('Known safe policy diagnostic')) == 'Known safe policy diagnostic'
raise unless PlayPolicy.history_floor!('18') == 18
[nil, '', '0', '17', '018', '18.0', '2100000001'].each { |value| assert_blocked { PlayPolicy.history_floor!(value) } }
next_build = rc.merge('build' => 19)
raise unless PlayPolicy.check!(next_build, [18], 18, []) == 'internal'
assert_blocked { PlayPolicy.check!(rc.merge('build' => 18), [18], 18, []) }
assert_blocked { PlayPolicy.check!(next_build, [19], 18, []) }
assert_blocked { PlayPolicy.check!(next_build, [20], 18, []) }
raise unless PlayPolicy.check!(rc.merge('build' => 21), [20], 18, []) == 'internal'
sentinel = 'SECRET_SENTINEL'
leaky = Class.new(RuntimeError) do
  define_method(:message) { sentinel }
end
unknown = PlayPolicy.publish_failure_line(leaky.new)
raise 'Failure line leaked a response body' if unknown.include?(sentinel)
raise 'Unclassified failure must stay UNKNOWN' unless unknown.include?('UNKNOWN')
raise 'Unclassified failure must not claim a commit' if unknown.include?('PLAY_EDIT_COMMITTED')
sha = 'a' * 40
context = {'channel' => 'production', 'tag' => 'android/v1.2.4+25', 'build' => 25}
good = {
  'PRODUCTION_PUBLISHING_ENABLED' => 'true',
  'GITHUB_SHA' => sha,
  'GITHUB_RUN_ATTEMPT' => '1',
  'PRODUCTION_RELEASE_AUTH_ANDROID' => "#{context['tag']}@#{sha}#1"
}
PlayPolicy.authorize_android!(context, good)
PlayPolicy.authorize_android!(context, good)
marker = StringIO.new
PlayPolicy.handoff_to_publisher(context, good, marker)
raise 'Marker missing' unless marker.string == "PUBLISHER_INVOKED platform=android tag=#{context['tag']}\n"
raise 'Marker is not publication success' if marker.string.include?('PLAY_EDIT_COMMITTED')
[
  good.merge('PRODUCTION_PUBLISHING_ENABLED' => 'false'),
  good.merge('PRODUCTION_RELEASE_AUTH_ANDROID' => "#{context['tag']}@#{sha}#2"),
  good.merge('GITHUB_RUN_ATTEMPT' => 'x'),
  good.merge('GITHUB_SHA' => 'b' * 40),
  good.merge('PRODUCTION_RELEASE_AUTH_ANDROID' => " #{good['PRODUCTION_RELEASE_AUTH_ANDROID']}")
].each do |env|
  buffer = StringIO.new
  begin
    PlayPolicy.handoff_to_publisher(context, env, buffer)
    raise 'Bad authorization reached the publisher marker'
  rescue PlayPolicy::Blocked => error
    raise error.message unless error.message == 'ANDROID_CLOUD_AUTHORIZATION_INVALID'
    raise 'Marker printed before authorization' unless buffer.string.empty?
  end
end
rc = {'channel' => 'rc', 'tag' => 'rc/android/v1.2.4+25', 'build' => 25}
PlayPolicy.authorize_android!(rc, {})
rc_marker = StringIO.new
PlayPolicy.handoff_to_publisher(rc, {}, rc_marker)
raise 'RC marker missing' unless rc_marker.string.include?('PUBLISHER_INVOKED platform=android')
publisher = File.read(File.expand_path('play.rb', __dir__))
raise 'Upload is not immediately after the publisher handoff' unless publisher.match?(
  /PlayPolicy\.handoff_to_publisher\(context, ENV\)\n\s*Supply::Uploader\.new\.perform_upload/
)
raise 'Preflight prints the publisher marker' if publisher.match?(/PUBLISHER_INVOKED/)
puts 'VERIFIED: Play history, production track status, redacted failure lines, and cloud handoff; no store requests'
