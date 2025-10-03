# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Clear existing data (optional - remove if you want to keep existing data)
Automation.destroy_all
Template.destroy_all
User.destroy_all

# Create test users
puts "Creating users..."
user1 = User.create!(
  name: "John Doe",
  email: "john@tamu.edu",
  password: "password123",
  password_confirmation: "password123",
  classification: "Senior",
  uin: "123456789"
)

user2 = User.create!(
  name: "Jane Smith",
  email: "jane@tamu.edu",
  password: "password123",
  password_confirmation: "password123",
  classification: "Graduate",
  uin: "987654321"
)

puts "Created #{User.count} users"

# Create templates for user1
puts "Creating templates..."
template1 = user1.templates.create!(
  name: "Welcome Email Campaign",
  spreadsheet_url: "https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit",
  rules_data: { 
    columns: [
      { name: 'email', type: 'string' },
      { name: 'name', type: 'string' },
      { name: 'status', type: 'string' }
    ],
    rules: []
  }
)

template2 = user1.templates.create!(
  name: "Newsletter Campaign",
  spreadsheet_url: "https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit",
  rules_data: { 
    columns: [
      { name: 'email', type: 'string' },
      { name: 'name', type: 'string' }
    ],
    rules: []
  }
)

template3 = user1.templates.create!(
  name: "Event Invitation",
  spreadsheet_url: "https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit",
  rules_data: { 
    columns: [
      { name: 'email', type: 'string' },
      { name: 'name', type: 'string' },
      { name: 'event_date', type: 'date' }
    ],
    rules: []
  }
)

puts "Created #{Template.count} templates"

# Create automations with various statuses
puts "Creating automations..."

# Completed automations (past dates)
10.times do |i|
  user1.automations.create!(
    template: [template1, template2, template3].sample,
    status: 'completed',
    send_at: (i + 1).days.ago,
    enabled: true,
    action_data: {
      to: "recipient#{i}@example.com",
      subject: "Email Campaign #{i + 1}",
      body: "This is a test email body for campaign #{i + 1}"
    }
  )
end

# Failed automations
5.times do |i|
  user1.automations.create!(
    template: [template1, template2, template3].sample,
    status: 'failed',
    send_at: (i + 1).days.ago,
    enabled: true,
    action_data: {
      to: "failed#{i}@example.com",
      subject: "Failed Campaign #{i + 1}",
      body: "This email failed to send"
    },
    error_message: "SMTP Error: Connection timeout"
  )
end

# Scheduled automations (future dates)
15.times do |i|
  user1.automations.create!(
    template: [template1, template2, template3].sample,
    status: 'scheduled',
    send_at: (i + 1).hours.from_now,
    enabled: true,
    action_data: {
      to: "scheduled#{i}@example.com",
      subject: "Scheduled Campaign #{i + 1}",
      body: "This email is scheduled to be sent"
    }
  )
end

# Some disabled scheduled automations
3.times do |i|
  user1.automations.create!(
    template: [template1, template2, template3].sample,
    status: 'scheduled',
    send_at: (i + 1).days.from_now,
    enabled: false,
    action_data: {
      to: "disabled#{i}@example.com",
      subject: "Disabled Campaign #{i + 1}",
      body: "This automation is disabled"
    }
  )
end

# Create some automations for user2 (to test user isolation)
5.times do |i|
  user2_template = user2.templates.create!(
    name: "User 2 Template #{i}",
    spreadsheet_url: "https://docs.google.com/spreadsheets/d/1BItHXS8Hh0xeunjWj04yi91djUt5CVxsk6w61iTC8zE/edit",
    rules_data: { columns: [], rules: [] }
  )
  
  user2.automations.create!(
    template: user2_template,
    status: ['scheduled', 'completed', 'failed'].sample,
    send_at: rand(-5..5).days.from_now,
    enabled: true,
    action_data: {
      to: "user2_recipient#{i}@example.com",
      subject: "User 2 Campaign #{i}",
      body: "User 2 email body"
    }
  )
end

puts "Created #{Automation.count} automations"

# Summary
puts "\n Seed Summary:"
puts "  Users: #{User.count}"
puts "  Templates: #{Template.count}"
puts "  Automations: #{Automation.count}"
puts "    - Completed: #{Automation.completed.count}"
puts "    - Failed: #{Automation.failed.count}"
puts "    - Scheduled: #{Automation.scheduled.count}"
puts "    - Total for user1 (john@tamu.edu): #{user1.automations.count}"
puts "    - Total for user2 (jane@tamu.edu): #{user2.automations.count}"

puts "\n Seeding complete!"
puts "\n Login credentials:"
puts "  Email: john@tamu.edu"
puts "  Password: password123"
puts "  ---"
puts "  Email: jane@tamu.edu"
puts "  Password: password123"
