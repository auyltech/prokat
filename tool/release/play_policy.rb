# Pure store-state policy, separately tested without credentials or network.
module PlayPolicy
  class Blocked < RuntimeError; end

  # Owner-confirmed historical baseline, not a claim about today's store state.
  KNOWN_HISTORICAL_MAX = 18

  def self.history_floor!(value)
    unless value.is_a?(String) && value.match?(/\A(?:0|[1-9][0-9]*)\z/)
      raise Blocked, 'U2 must confirm PLAY_HISTORICAL_MAX_BUILD as an integer'
    end
    floor = Integer(value)
    unless floor.between?(KNOWN_HISTORICAL_MAX, 2_100_000_000)
      raise Blocked, "PLAY_HISTORICAL_MAX_BUILD must be at least the known historical #{KNOWN_HISTORICAL_MAX} and within Android limits"
    end
    floor
  end

  def self.safe_error(error)
    return error.message if error.is_a?(Blocked)
    "Store/credential operation failed (#{error.class}); state UNKNOWN; response bodies suppressed"
  end

  # The only Play failure text play.rb may print. Google bodies stay inside the exception.
  def self.publish_failure_line(error)
    case error.class.name
    when 'ProkatPlayStore::ChangesInReview'
      'PLAY_CHANGES_IN_REVIEW: commit refused, edit not committed; inspect Play Console before any retry'
    when 'ProkatPlayStore::TrackNotClean'
      error.message
    else
      "BLOCKED: #{safe_error(error)}. No automatic retry. Inspect store state before any next attempt."
    end
  end

  def self.check!(context, codes, historical_floor, tracks)
    history_floor!(historical_floor.to_s)
    platform = context.fetch('platform')
    channel = context.fetch('channel')
    raise Blocked, 'Invalid Android release context' unless platform == 'android' && %w[rc production].include?(channel)
    expected_track = channel == 'rc' ? 'internal' : 'production'
    raise Blocked, 'Release channel/track mismatch' unless context.fetch('destination') == expected_track
    build = Integer(context.fetch('build'))
    if codes.include?(build)
      locations = tracks.select { |t| t.fetch('codes').include?(build) }.map { |t| "#{t.fetch('track')}:#{t.fetch('status')}" }
      raise Blocked, "Build #{build} is already accepted; tracks=#{locations.join(',')}. Inspect Play App bundle explorer; do not reupload. See RELEASE_RUNBOOK.md."
    end
    ceiling = [historical_floor, *codes].max
    raise Blocked, "Build #{build} must exceed historical/current maximum #{ceiling}; choose a new build number" if build <= ceiling
    if channel == 'production'
      tracks.each do |track|
        next unless track.fetch('track') == 'production'
        status = track.fetch('status').to_s
        raise Blocked, "Production track release is not completed (#{status})" unless status == 'completed'
      end
    end
    expected_track
  end
end
