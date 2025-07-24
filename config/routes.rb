Rails.application.routes.draw do
  get "/eligibility_check" => "eligibility_check#index"
  get "/verify" => "eligibility_check#show"
end
