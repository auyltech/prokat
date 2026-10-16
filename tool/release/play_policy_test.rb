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
puts 'VERIFIED: 9 Play policy/error-redaction cases; no store requests'
