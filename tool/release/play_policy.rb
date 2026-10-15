# Pure store-state policy, separately tested without credentials or network.
module PlayPolicy
  def self.check!(context, codes, historical_floor, tracks)
    platform = context.fetch('platform')
    channel = context.fetch('channel')
    raise 'Invalid Android release context' unless platform == 'android' && %w[rc production].include?(channel)
    expected_track = channel == 'rc' ? 'internal' : 'production'
    raise 'Release channel/track mismatch' unless context.fetch('destination') == expected_track
    build = Integer(context.fetch('build'))
    if codes.include?(build)
      locations = tracks.select { |t| t.fetch('codes').include?(build) }.map { |t| "#{t.fetch('track')}:#{t.fetch('status')}" }
      raise "Build #{build} is already accepted; tracks=#{locations.join(',')}. Inspect Play App bundle explorer; do not reupload. See RELEASE_RUNBOOK.md."
    end
    ceiling = [historical_floor, *codes].max
    raise "Build #{build} must exceed historical/current maximum #{ceiling}; choose a new build number" if build <= ceiling
    expected_track
  end
end
