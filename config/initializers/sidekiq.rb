require "sidekiq"
require "sidekiq-scheduler"
require "sidekiq/throttled"

Sidekiq.strict_args!(false)

Sidekiq.configure_server do |config|
  config.on(:startup) do
    schedule_file = "config/sidekiq.yml"

    if File.exist?(schedule_file) && Sidekiq.server?
      schedule = YAML.load_file(schedule_file)[:schedule]
      Sidekiq.schedule = schedule
      Sidekiq::Scheduler.reload_schedule!
    end
  end
end
