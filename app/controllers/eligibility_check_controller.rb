class EligibilityCheckController < ApplicationController
    require "net/http"
    require "uri"

    rate_limit to: 10, within: 2.minutes, only: :create, alert: "Too many attempts. Only 10 attempts every 3 minutes."

  def index
    @eligibility_checks = EligibilityCheck.all

    render json: @eligibility_checks
  end

  def create
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
    @response_code = response.code
    @data = JSON.parse(response.body)
    pp "-------"
    puts @data["message"]
    # puts @data.message
    pp "-------"
    if @response_code == "200"
      @active = true
      save_or_update_member
      create_elig_check_record
      render json: @member
    else
      @active = false
      if @member = Member.find_by(external_member_id: @params[:external_member_id] || @params[:first_name] && @params[:last_name] && @params[:dob] && @params[:zip])
      @member.update(
        active: false,
        terminated_at: Time.current
      )
      create_elig_check_record
      render json: @data && @member
      else
        # pp "-------"
        # puts @member.errors.full_messages
        # pp "-------"
        render json: { errors: @data["message"] }, status: :not_found
      end
    end
  end

  private
  def save_or_update_member
    if @data["external_member_id"].present?
      @member = Member.find_or_initialize_by(external_member_id: @data["external_member_id"])
    else
      @member = Member.find_or_initialize_by(
        first_name: @data["first_name"],
        last_name: @data["last_name"],
        dob: @data["dob"],
        zip: @data["zip"]
      )
    end
    @member.external_member_id = @data["external_member_id"]
    @member.first_name = @data["first_name"]
    @member.last_name = @data["last_name"]
    @member.zip = @data["zip"]
    @member.group_number = @data["group_number"]
    @member.dob = @data["dob"]
    @member.active = true
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
