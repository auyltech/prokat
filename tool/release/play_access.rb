# Explicit U2 access diagnostic. Never called automatically, never publishes.
require_relative 'play_store'

begin
  raise 'Expected --credentials PATH to a local service-account JSON' unless ARGV.length == 2 && ARGV.first == '--credentials'
  puts JSON.generate(ProkatPlayStore.snapshot(File.expand_path(ARGV.last)))
  puts 'VERIFIED: Play snapshot read and temporary edit deleted; no binary uploaded or release committed. Test/production write permissions are NOT proven by this probe.'
rescue StandardError => error
  warn "BLOCKED: Play access/state UNKNOWN (#{error.class}); inspect API enablement, app permissions, primary locale and temporary-edit cleanup. Credentials/response bodies suppressed."
  exit 1
end
