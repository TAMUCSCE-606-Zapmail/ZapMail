import { Controller } from "@hotwired/stimulus"
import Tribute from "tributejs"
import { post } from '@rails/request.js'

export default class extends Controller {
  static targets = [
    "container", "rulesContainer", "ruleTemplate", "conditionTemplate", "output", "rule", "condition",
    "previewContainer"
  ]
  static values = { rules: Object }

  connect() {
    this.tributeInstances = [];
    this.stringOperators = [
      { value: '==', label: 'is' }, { value: '!=', label: 'is not' },
      { value: 'contains', label: 'contains' }, { value: 'not_contains', label: 'does not contain' }
    ];
    this.numberOperators = [
      { value: '>', label: '>' }, { value: '<', label: '<' },
      { value: '==', label: '==' }, { value: '!=', label: '!=' }
    ];
    const initialData = this.rulesValue;
    if (initialData && initialData.columns && initialData.columns.length > 0) {
      this.columns = initialData.columns;
      this.emailColumns = this.findEmailColumns(this.columns);
      this.containerTarget.classList.remove("hidden");
      if(this.hasPreviewContainerTarget) this.previewContainerTarget.classList.remove("hidden");
      this.loadInitialRules(initialData.rules);
    }
  }

  disconnect() {
    this.tributeInstances.forEach(tribute => tribute.detach());
  }
  
  findEmailColumns(columns) {
    return columns.filter(c => c.name.toLowerCase().includes('email')).map(c => c.name);
  }

  handleVerification({ detail: { columns, emailColumns } }) {
    this.columns = columns;
    this.emailColumns = emailColumns;
    this.containerTarget.classList.remove("hidden");
    if(this.hasPreviewContainerTarget) this.previewContainerTarget.classList.remove("hidden");
    this.rulesContainerTarget.innerHTML = '';
    this.addRule();
  }

  handleReset() {
    this.containerTarget.classList.add("hidden");
    if(this.hasPreviewContainerTarget) this.previewContainerTarget.classList.add("hidden");
    this.rulesContainerTarget.innerHTML = '';
    this.tributeInstances.forEach(tribute => tribute.detach());
    this.tributeInstances = [];
  }

  loadInitialRules(rules = []) {
    this.rulesContainerTarget.innerHTML = '';
    if (rules && rules.length > 0) {
      rules.forEach(ruleData => this.addRule(null, ruleData));
    } else {
      this.addRule();
    }
  }

  addRule(event, ruleData = null) {
    if (event) event.preventDefault();
    const content = this.ruleTemplateTarget.content.cloneNode(true);
    const newRuleEl = content.querySelector('[data-rule-editor-target="rule"]');
    const tributeInputs = newRuleEl.querySelectorAll('[data-mention-input="true"]');
    this.attachTribute(tributeInputs);
    this.rulesContainerTarget.appendChild(content);

    const action = ruleData?.action || {};
    this._populateColumns(newRuleEl.querySelector('.action-email-to'), this.emailColumns, action.toColumn);
    newRuleEl.querySelector('.action-subject').value = action.subject || '';
    newRuleEl.querySelector('.action-body').value = action.body || '';

    // Set scheduling fields
    const isRepeatingCheckbox = newRuleEl.querySelector('.action-is-repeating');
    isRepeatingCheckbox.checked = action.isRepeating || false;
    this.toggleRepeatOptions({ currentTarget: isRepeatingCheckbox });

    if(action.isRepeating) {
      newRuleEl.querySelector('.action-repeat-frequency').value = action.repeatFrequency || 'daily';
      newRuleEl.querySelector('.action-repeat-deadline').value = action.repeatDeadline || '';
    } else {
      newRuleEl.querySelector('.action-onetime-send-at').value = action.oneTimeSendAt || '';
    }

    const conditionsContainer = newRuleEl.querySelector('[data-rule-editor-target="conditionsContainer"]');
    if (!ruleData || !ruleData.conditions || ruleData.conditions.length === 0) {
      this.addCondition(conditionsContainer);
    } else {
      ruleData.conditions.forEach(conditionData => {
        this.addCondition(conditionsContainer, conditionData);
      });
    }
  }
  
  toggleRepeatOptions(event) {
    const checkbox = event.currentTarget;
    const ruleElement = checkbox.closest('[data-rule-editor-target="rule"]');
    const repeatOptions = ruleElement.querySelector('.action-repeat-options');
    const onetimeOptions = ruleElement.querySelector('.action-onetime-send');

    if (checkbox.checked) {
      repeatOptions.classList.remove('hidden');
      onetimeOptions.classList.add('hidden');
    } else {
      repeatOptions.classList.add('hidden');
      onetimeOptions.classList.remove('hidden');
    }
  }

  addCondition(eventOrContainer, conditionData = null) {
    let conditionsContainer;
    if (eventOrContainer.currentTarget) {
      eventOrContainer.preventDefault();
      conditionsContainer = eventOrContainer.currentTarget.closest('.bg-slate-800').querySelector('[data-rule-editor-target="conditionsContainer"]');
    } else {
      conditionsContainer = eventOrContainer;
    }
    const content = this.conditionTemplateTarget.content.cloneNode(true);
    const columnSelect = content.querySelector('.condition-column');
    this._populateColumns(columnSelect, this.columns.map(c => c.name), conditionData?.column);
    const operatorSelect = content.querySelector('.condition-operator');
    this._updateOperators(operatorSelect, conditionData?.column);
    if(conditionData) operatorSelect.value = conditionData.operator;
    const valueInput = content.querySelector('.condition-value');
    valueInput.value = conditionData?.value || '';
    columnSelect.addEventListener('change', (e) => this._updateOperators(operatorSelect, e.target.value));
    conditionsContainer.appendChild(content);
  }

  attachTribute(elements) {
    if (!this.columns || this.columns.length === 0) return;
    const tribute = new Tribute({
      trigger: '@',
      values: this.columns.map(col => ({ key: col.name, value: `{${col.name}}` })),
      selectTemplate: (item) => item.original.value,
      allowSpaces: false,
      menuItemLimit: 10,
    });
    tribute.attach(elements);
    this.tributeInstances.push(tribute);
  }

  async preview(event) {
    event.preventDefault();
    this.save();
    const rulesData = this.outputTarget.value;
    const spreadsheetUrl = document.querySelector('[data-form-verification-target="urlInput"]').value;
    const templateId = this.element.closest("form").action.split('/').pop();
    
    await post(`/templates/${templateId}/preview`, {
      body: { rules_data: rulesData, spreadsheet_url: spreadsheetUrl },
      responseKind: 'turbo-stream'
    });
  }
  
  async schedule(event) {
    event.preventDefault();
    if (!confirm("Are you sure you want to schedule these actions? This will create automation jobs for all matching rows.")) {
      return;
    }
    this.save();

    const rulesData = this.outputTarget.value;
    const spreadsheetUrl = document.querySelector('[data-form-verification-target="urlInput"]').value;
    const templateId = this.element.closest("form").action.split('/').pop();

    const response = await post(`/templates/${templateId}/schedule`, {
      body: {
        rules_data: rulesData,
        spreadsheet_url: spreadsheetUrl
      },
      responseKind: 'json'
    });

    if (response.ok) {
        const data = await response.json;
        alert(`Successfully scheduled ${data.scheduled_count} emails.`);
    } else {
        const errorData = await response.json;
        alert(`Failed to schedule emails: ${errorData.error}`);
    }
  }

  removeRule(event) {
    event.preventDefault();
    const ruleElement = event.currentTarget.closest('[data-rule-editor-target="rule"]');
    const tributeInputs = ruleElement.querySelectorAll('[data-mention-input="true"]');
    this.tributeInstances.forEach(tribute => {
      tribute.detach(tributeInputs);
    });
    ruleElement.remove();
  }

  removeCondition(event) {
    event.preventDefault();
    event.currentTarget.closest('[data-rule-editor-target="condition"]').remove();
  }
  
  save() {
    const rules = Array.from(this.ruleTargets).map(ruleEl => {
      const conditions = Array.from(ruleEl.querySelectorAll('[data-rule-editor-target="condition"]')).map(condEl => ({
        column: condEl.querySelector('.condition-column').value,
        operator: condEl.querySelector('.condition-operator').value,
        value: condEl.querySelector('.condition-value').value
      }));
      const isRepeating = ruleEl.querySelector('.action-is-repeating').checked;
      const action = {
        type: 'sendEmail',
        toColumn: ruleEl.querySelector('.action-email-to').value,
        subject: ruleEl.querySelector('.action-subject').value,
        body: ruleEl.querySelector('.action-body').value,
        isRepeating: isRepeating,
        repeatFrequency: isRepeating ? ruleEl.querySelector('.action-repeat-frequency').value : null,
        repeatDeadline: isRepeating ? ruleEl.querySelector('.action-repeat-deadline').value : null,
        oneTimeSendAt: !isRepeating ? ruleEl.querySelector('.action-onetime-send-at').value : null,
      };
      return { conditions, action };
    });
    const finalData = { columns: this.columns, rules: rules };
    this.outputTarget.value = JSON.stringify(finalData);
  }

  _populateColumns(selectElement, columns, selectedValue) {
    selectElement.innerHTML = '<option value="">Select column...</option>';
    columns.forEach(column => {
      const option = new Option(column, column);
      option.selected = (column === selectedValue);
      selectElement.add(option);
    });
  }

  _updateOperators(operatorSelect, columnName) {
    const column = this.columns.find(c => c.name === columnName);
    const type = column ? column.type : 'string';
    const operators = (type === 'number') ? this.numberOperators : this.stringOperators;
    operatorSelect.innerHTML = '';
    operators.forEach(op => {
      const option = new Option(op.label, op.value);
      operatorSelect.add(option);
    });
  }
}
