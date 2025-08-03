Rails.application.routes.draw do
  get "/eligibility_check" => "eligibility_check#index"
  get "/verify" => "eligibility_check#show"

  post "/login" => "sessions#create"
  delete "/logout" => "sessions#destroy"
end
