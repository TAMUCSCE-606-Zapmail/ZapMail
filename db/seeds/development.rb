# db/seeds/development.rb

puts "Seeding development data."

# Clear old data to avoid duplication
AutomationHistory.delete_all
Automation.delete_all
StrategyAction.delete_all
Condition.delete_all
Rule.delete_all
Strategy.delete_all
User.delete_all

# --- Users ---
user1 = User.create!(
  name: "Alice Johnson",
  email: "alice@example.com",
  password: "password"
)

user2 = User.create!(
  name: "Bob Smith",
  email: "bob@example.com",
  password: "password"
)

user3 = User.create!(
    name: "Developer",
    email: "dev@example.com",
    password: "password"
)

# --- Strategies ---
strategy1 = Strategy.create!(
  user: user1,
  name: "Email Engagement Strategy",
  csv_file_path: "/tmp/email_list.csv"
)

strategy2 = Strategy.create!(
  user: user2,
  name: "Customer Retention Strategy",
  csv_file_path: "/tmp/retention.csv"
)

strategy3 = Strategy.create!(
    user: user3,
    name: "Absent Student Check-Ins",
    csv_file_path: "/temp/absences.csv"
)

# --- Rules for strategy1 ---
rule1 = Rule.create!(strategy: strategy1, order: 1)
rule2 = Rule.create!(strategy: strategy1, order: 2)
rule3 = Rule.create!(strategy: strategy3, order: 1)

# --- Conditions ---
Condition.create!(rule: rule1, column_name: "open_rate", operator: ">", value: "0.5")
Condition.create!(rule: rule2, column_name: "click_rate", operator: "==", value: "1.0")
Condition.create!(rule: rule3, column_name: "absences", operator: ">=", value: "3")

# --- Actions ---
StrategyAction.create!(rule: rule1, action_type: "send_email", prompt_template: "Send a reminder email to {{email}}.")
StrategyAction.create!(rule: rule2, action_type: "send_email", prompt_template: "Send a discount code to {{email}}.")
StrategyAction.create!(rule: rule3, action_type: "send_email", prompt_template: "Send a absence email to {{email}}")

# --- Automations ---
automation1 = Automation.create!(
  strategy: strategy1,
  status: "scheduled",
  next_run_time: 1.day.from_now,
  schedule_type: "periodic",
  end_time: 1.month.from_now
)

automation2 = Automation.create!(
  strategy: strategy2,
  status: "running",
  next_run_time: Time.now,
  schedule_type: "one_time"
)

automation3 = Automation.create!(
    strategy: strategy3,
    status: "scheduled",
    next_run_time: 1.day.from_now,
    schedule_type: "periodic",
    end_time: 4.month.from_now
)

# --- Automation Histories ---
AutomationHistory.create!(
  automation: automation1,
  row_data: { "email" => "test1@example.com", "open_rate" => 0.6 },
  email_status: "sent",
  api_response: "200 OK",
  error_message: nil
)

AutomationHistory.create!(
  automation: automation2,
  row_data: { "email" => "test2@example.com", "click_rate" => 1.0 },
  email_status: "failed",
  api_response: "500 Internal Server Error",
  error_message: "SMTP connection timeout"
)

AutomationHistory.create!(
    automation: automation3,
    row_data: { "email" => "student1@tamu.edu", "absences" => 3 },
    email_status: "failed",
    api_response: "500 Internal Server Error",
    error_message: "SMTP connection timeout"
)

AutomationHistory.create!(
    automation: automation3,
    row_data: { "email" => "student2@tamu.edu", "absences" => 6 },
    email_status: "successful",
    api_response: "200 Success!",
    error_message: ""
)


puts "Development seeds created successfully."
