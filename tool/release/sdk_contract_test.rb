require 'fastlane'
require 'supply'
require 'supply/client'
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
puts 'VERIFIED: pinned Supply/Google API methods and publishing options; no store requests'
