class EligibilityBatchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :daily_jobs # Optional custom queue

  def perform
    Member.find_each do |member|
      EligibilityCheckWorker.perform_async({
        external_member_id: member.external_member_id,
        first_name: member.first_name,
        last_name: member.last_name,
        zip: member.zip,
        group_number: member.group_number,
        dob: member.dob&.to_s
      })
    end
  end
end

class EligibilityCheckWorker
  require "net/http"
  require "uri"

  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker
  sidekiq_options queue: :daily_jobs

  # Define the throttling strategy (5 jobs per 60 seconds)
  def self.throttled?
    Sidekiq::Throttled::Strategies::Threshold.new(limit: 5, period: 60)
  end

  # Define the key for throttling per member (based on external_member_id)
  def sidekiq_throttle_key(params)
    params["external_member_id"].to_s
  end

  def perform(params = {})
    Rails.logger.info "[EligibilityCheckWorker] Checking eligibility for #{params["external_member_id"] || params["first_name"]}"

    uri = URI.parse("http://localhost:3000/verify.json")
    uri.query = URI.encode_www_form(params)

    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{ENV["API_TOKEN"]}"

    response = http.request(request)
    data = JSON.parse(response.body)

    member = if data["external_member_id"].present?
               Member.find_or_initialize_by(external_member_id: data["external_member_id"])
    else
               Member.find_or_initialize_by(
                 first_name: data["first_name"],
                 last_name: data["last_name"],
                 dob: data["dob"],
                 zip: data["zip"]
               )
    end

    if response.code == "200"
      member.assign_attributes(
        external_member_id: data["external_member_id"],
        first_name: data["first_name"],
        last_name: data["last_name"],
        zip: data["zip"],
        group_number: data["group_number"],
        dob: data["dob"],
        active: true,
        terminated_at: nil
      )
      active = true
    else
      member.active = false
      member.terminated_at = Time.current
      active = false
    end

    member.save!

    EligibilityCheck.create!(
      member: member,
      active: active
    )

    Rails.logger.info "[EligibilityCheckWorker] Eligibility check completed for #{member.id} (Active: #{active})"
  rescue => e
    Rails.logger.error "[EligibilityCheckWorker] Error for #{params["external_member_id"]}: #{e.message}"
    raise e
  end
end
