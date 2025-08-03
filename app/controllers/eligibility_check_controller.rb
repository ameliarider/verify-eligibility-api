class EligibilityCheckController < ApplicationController
    require "net/http"
    require "uri"

    rate_limit to: 10, within: 3.minutes, only: :show, alert: "Too many attempts. Only 10 attempts every 3 minutes."

  def index
    uri = URI.parse("http://localhost:3000/members.json")
    http = Net::HTTP.new(uri.host, uri.port)
    # http.use_ssl = true # Use SSL for secure communication

    request = Net::HTTP::Get.new(uri.request_uri)
    bearer_token = ENV["API_TOKEN"] # Gets token from .env file
    request["Authorization"] = "Bearer #{bearer_token}"

    response = http.request(request)

    @members = response.body

    render json: @members
  end

  def show
    @params = {
        external_member_id: params[:external_member_id],
        first_name: params[:first_name],
        last_name: params[:last_name],
        zip: params[:zip],
        group_number: params[:group_number],
        dob: params[:dob]
        }

    uri = URI.parse("http://localhost:3000/verify.json")
    uri.query = URI.encode_www_form(@params)

    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Get.new(uri)
    bearer_token = ENV["API_TOKEN"] # Gets token from .env file
    request["Authorization"] = "Bearer #{bearer_token}"

    response = http.request(request)
    @data = JSON.parse(response.body)
    if response.code == "200"
      @active = true
      save_or_update_member
      render json: @member
    else
      @active = false
      @member = Member.find_by(external_member_id: @params[:external_member_id])
      @member.update(
        active: false,
        terminated_at: Time.current
      )
      render json: @data && @member
    end
    create_elig_check_record
  end

  private
  def save_or_update_member
    @member = Member.find_or_initialize_by(external_member_id: @data[:external_member_id] || @data[:first_name] && @data[:last_name] && @data[:dob] && @data[:zip])
    @member.external_member_id = @data["external_member_id"]
    @member.first_name = @data["first_name"]
    @member.last_name = @data["last_name"]
    @member.zip = @data["zip"]
    @member.group_number = @data["group_number"]
    @member.dob = @data["dob"]
    @member.active = true,
    @member.terminated_at = nil
    @member.save!
  end

  def create_elig_check_record
    @eligibility_check = EligibilityCheck.create!(
      member_id: @member.id,
      active: @active
    )
  end
end
