Rails.application.routes.draw do
  get "/eligibility_check" => "eligibility_check#index"
  get "/eligibility_check/:external_member_id" => "eligibility_check#show"
end
