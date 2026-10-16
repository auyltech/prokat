require_relative 'play_policy'

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
puts 'VERIFIED: 22 Play history/state/error-redaction cases; known floor 18 never replaces live state; no store requests'
