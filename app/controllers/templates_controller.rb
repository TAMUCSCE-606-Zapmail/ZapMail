class TemplatesController < ApplicationController

  before_action :authorize

  require 'open-uri'
  require 'csv'

  before_action :set_template, only: [:edit, :update, :destroy, :preview, :schedule, :duplicate]

  class RuleProcessorService
    def initialize(rules, data)
      @rules = rules
      @data = data
    end
    def run
      results = []
      @data.each_with_index do |row, index|
        matching_rule = @rules.find { |rule| conditions_met?(rule['conditions'], row) }
        if matching_rule
          action = matching_rule['action']
          condition_columns = matching_rule['conditions'].map { |c| c['column'] }.uniq
          conditional_data = row.slice(*condition_columns)
          results << {
            row_number: index + 2, row: row, action: action, conditional_data: conditional_data,
            substituted_subject: substitute_placeholders(action['subject'], row),
            substituted_body: substitute_placeholders(action['body'], row)
          }
        end
      end
      results
    end
    private
    def substitute_placeholders(text, row)
      return "" if text.blank?
      text.gsub(/\{([a-zA-Z0-9_]+)\}/) { |match| row.fetch($1, match) }
    end
    def conditions_met?(conditions, row)
      return false if conditions.any? { |c| c['column'].blank? }
      conditions.all? { |condition| evaluate_condition(condition, row) }
    end
    def evaluate_condition(condition, row)
      row_value = row[condition['column']]
      condition_value = condition['value']
      return false if row_value.nil?
      if ['<', '>'].include?(condition['operator'])
        row_value = Float(row_value) rescue row_value
        condition_value = Float(condition_value) rescue condition_value
      end
      case condition['operator']
      when '==' then row_value.to_s == condition_value.to_s
      when '!=' then row_value.to_s != condition_value.to_s
      when '>'  then row_value > condition_value
      when '<'  then row_value < condition_value
      when 'contains' then row_value.to_s.downcase.include?(condition_value.to_s.downcase)
      when 'not_contains' then !row_value.to_s.downcase.include?(condition_value.to_s.downcase)
      else false
      end
    end
  end

  def index
    @templates = current_user.templates.order(updated_at: :desc).page(params[:page]).per(6)
  end

  def new
    @template = current_user.templates.build
  end

  def create
    @template = current_user.templates.build(processed_template_params)
    if @template.save
      SlackNotifierService.new.notify("User `#{current_user.email}` created a new template: '#{@template.name}'.")
      redirect_to edit_template_path(@template), notice: 'Template created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @template.update(processed_template_params)
      SlackNotifierService.new.notify("User `#{current_user.email}` updated the template: '#{@template.name}'.")
      redirect_to edit_template_path(@template), notice: 'Template updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    template_name = @template.name
    @template.destroy
    SlackNotifierService.new.notify("User `#{current_user.email}` deleted the template: '#{template_name}'.", :warning)
    redirect_to templates_url, notice: 'Template destroyed.'
  end

  def duplicate
    new_template = @template.dup
    new_template.name = "#{@template.name} (Copy)"
    if new_template.save
      SlackNotifierService.new.notify("User `#{current_user.email}` duplicated the template: '#{@template.name}'.")
      redirect_to templates_path, notice: "Template was successfully duplicated."
    else
      redirect_to templates_path, alert: "Could not duplicate the template."
    end
  end

  def verify_spreadsheet
    url = params[:spreadsheet_url]
    begin
      data = fetch_spreadsheet_data(url)
      headers = data.first.keys
      columns = headers.map do |header|
        is_numeric = data.all? { |row| row[header].to_s.match?(/\A-?\d+(\.\d+)?\z/) }
        { name: header, type: is_numeric ? 'number' : 'string' }
      end
      email_columns = columns.select { |c| c[:name].downcase.include?('email') }.map { |c| c[:name] }
      if email_columns.empty?
        render json: { success: false, message: "No 'email' column found." }, status: :unprocessable_entity
      else
        render json: { success: true, message: 'Spreadsheet verified!', columns: columns, emailColumns: email_columns }
      end
    rescue StandardError => e
      SlackNotifierService.new.notify("Spreadsheet verification failed for user `#{current_user.email}`. Error: `#{e.message}`", :error)
      render json: { success: false, message: "Could not access spreadsheet: #{e.message}" }, status: :unprocessable_entity
    end
  end

  def preview
    begin
      rules_data = JSON.parse(params[:rules_data])
      rules = rules_data['rules']
      data = fetch_spreadsheet_data(params[:spreadsheet_url])
      processor = RuleProcessorService.new(rules, data)
      all_results = processor.run
      @paginated_results = Kaminari.paginate_array(all_results).page(params[:page]).per(5)

      render turbo_stream: turbo_stream.update("preview_results_frame", 
        partial: "templates/preview_results", 
        locals: { results: @paginated_results })
    rescue StandardError => e
      SlackNotifierService.new.notify("Rule preview failed for template '#{@template.name}'. Error: `#{e.message}`", :error)
      @error_message = e.message
      render turbo_stream: turbo_stream.update("preview_results_frame", 
        partial: "templates/preview_error", 
        locals: { error: @error_message })
    end
  end

  def schedule
    begin
      rules_data = JSON.parse(params[:rules_data])
      rules = rules_data['rules']
      data = fetch_spreadsheet_data(params[:spreadsheet_url])
      processor = RuleProcessorService.new(rules, data)
      results = processor.run
      
      scheduled_count = 0
      results.each do |result|
        action = result[:action]
        send_at = Time.parse(action['oneTimeSendAt'])
        
        @template.automations.create!(
          user: current_user,
          send_at: send_at,
          status: 'scheduled',
          action_data: {
            to: result[:row][action['toColumn']],
            subject: result[:substituted_subject],
            body: result[:substituted_body],
          }
        )
        scheduled_count += 1
      end

      SlackNotifierService.new.notify("User `#{current_user.email}` scheduled #{scheduled_count} emails from template '#{@template.name}'.", :success)
      render json: { success: true, scheduled_count: scheduled_count }
    rescue StandardError => e
      SlackNotifierService.new.notify("Failed to schedule jobs for template '#{@template.name}'. Error: `#{e.message}`", :error)
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def set_template
    @template = current_user.templates.find(params[:id])
  end

  def template_params
    params.require(:template).permit(:name, :spreadsheet_url, :rules_data)
  end

  def processed_template_params
    permitted_params = template_params
    rules_json_string = permitted_params[:rules_data]
    if rules_json_string.is_a?(String) && rules_json_string.present?
      begin
        return permitted_params.merge(rules_data: JSON.parse(rules_json_string))
      rescue JSON::ParserError
        return permitted_params.except(:rules_data)
      end
    end
    permitted_params
  end

  def fetch_spreadsheet_data(url)
    export_url = convert_to_csv_export_url(url)
    csv_text = URI.parse(export_url).open.read
    CSV.parse(csv_text, headers: true).map(&:to_h)
  end

  def convert_to_csv_export_url(url)
    match = url.match(/spreadsheets\/d\/([a-zA-Z0-9\-_]+)/)
    return url unless match
    spreadsheet_id = match[1]
    "https://docs.google.com/spreadsheets/d/#{spreadsheet_id}/export?format=csv&gid=0"
  end
end
