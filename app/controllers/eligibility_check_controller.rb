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
        dob: params[:dob]
        }

    uri = URI.parse("http://localhost:3000/verify.json")
    uri.query = URI.encode_www_form(@params)

    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Get.new(uri)
    bearer_token = ENV["API_TOKEN"] # Gets token from .env file
    request["Authorization"] = "Bearer #{bearer_token}"

    response = http.request(request)

    puts "Response Code: #{response.code}"
    puts "Response Body: #{response.body}"

    render json: response.body
  end
end
