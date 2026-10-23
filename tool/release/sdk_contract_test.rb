require_relative 'play_store'
require 'supply/options'

api = Google::Apis::AndroidpublisherV3::AndroidPublisherService.new
%i[list_edit_bundles list_edit_apks list_edit_tracks get_edit_detail].each do |method|
  raise "Missing pinned SDK method #{method}" unless api.respond_to?(method)
end
raise unless Supply::Client.instance_methods.include?(:abort_current_edit)
keys = Supply::Options.available_options.map(&:key)
%i[package_name json_key aab metadata_path track version_code version_name release_status
   changes_not_sent_for_review rescue_changes_not_sent_for_review skip_upload_metadata
   skip_upload_images skip_upload_screenshots skip_upload_apk skip_upload_changelogs timeout].each do |key|
  raise "Missing Supply option #{key}" unless keys.include?(key)
end
configuration = FastlaneCore::Configuration.create(Supply::Options.available_options, {
  package_name: 'com.auyltech.prokat', version_code: 108, track: 'internal', skip_upload_metadata: true
})
raise 'Supply version_code must remain an Integer' unless configuration[:version_code] == 108
service = Google::Apis::AndroidpublisherV3::AndroidPublisherService
raise 'ErrorIfInReview is not installed' unless service.ancestors.include?(ProkatPlayStore::ErrorIfInReview)
raise 'GuardedPublishEdit is not installed' unless Supply::Client.ancestors.include?(ProkatPlayStore::GuardedPublishEdit)
raise 'call_google_api contract missing' unless Supply::AbstractGoogleServiceClient.private_instance_methods.include?(:call_google_api)
{
  begin_edit: [[:key, :package_name]],
  tracks: [[:rest]],
  update_track: [[:req, :track_name], [:req, :track_object]],
  commit_current_edit!: []
}.each do |name, expected|
  actual = Supply::Client.instance_method(name).parameters
  raise "#{name} arity changed: #{actual.inspect}" unless actual == expected || (name == :tracks && actual == [[:rest, :tracknames]])
end
captured = nil
api = service.new
api.define_singleton_method(:execute_or_queue_command) do |command, &block|
  captured = command
  nil
end
api.commit_edit('com.auyltech.prokat', 'edit-1', changes_in_review_behavior: 'CANCEL_IN_REVIEW_AND_SUBMIT')
raise 'commit_edit did not force ERROR_IF_IN_REVIEW' unless captured.query['changesInReviewBehavior'] == 'ERROR_IF_IN_REVIEW'
puts 'VERIFIED: pinned Supply/Google API methods, ERROR_IF_IN_REVIEW, and publishing options; no store requests'
