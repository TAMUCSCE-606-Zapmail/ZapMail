# This initializer loads the cron job schedule from the YAML file
# when the Rails application boots.

# We only want to load the schedule in the Sidekiq server process, not in the web process or console.
if Sidekiq.server?
    Rails.application.config.after_initialize do
      Sidekiq::Cron::Job.load_from_hash YAML.load_file(Rails.root.join('config/sidekiq_schedule.yml'))
    end
  end
  