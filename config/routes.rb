require "sidekiq/web"
require "sidekiq-scheduler/web"

Rails.application.routes.draw do
  Sidekiq::Web.use ActionDispatch::Cookies
  Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_your_app_session"

  mount Sidekiq::Web => "/sidekiq"


  get "/eligibility_checks" => "eligibility_check#index"
  post "/verify" => "eligibility_check#create"

  get "/members" => "members#index"
  get "/members/:id" => "members#show"

  post "/login" => "sessions#create"
  delete "/logout" => "sessions#destroy"
end
