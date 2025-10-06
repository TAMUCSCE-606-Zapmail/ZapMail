import { Controller } from "@hotwired/stimulus"
import { post } from '@rails/request.js'

export default class extends Controller {
  static targets = ["urlInput", "status", "saveButton"]

  async verify(event) {
    event.preventDefault();
    const url = this.urlInputTarget.value;

    this.statusTarget.textContent = "Verifying...";
    this.statusTarget.className = "mt-2 text-sm h-5 text-yellow-400";
    this.urlInputTarget.classList.remove("border-green-500", "border-red-500");

    if (!url) {
      this.handleError("URL cannot be blank.");
      return;
    }

    try {
      const response = await post('/templates/verify_spreadsheet', {
        body: { spreadsheet_url: url },
        responseKind: 'json'
      });

      const data = await response.json;
      if (data.success) {
        this.statusTarget.textContent = `✅ Success: ${data.message}`;
        this.statusTarget.className = "mt-2 text-sm h-5 text-green-400";
        this.urlInputTarget.classList.add("border-green-500");
        this.saveButtonTarget.disabled = false;

        // Dispatch a custom event with the column data for the other controller to hear.
        this.dispatch("verified", { detail: { columns: data.columns, emailColumns: data.emailColumns } });

      } else {
        this.handleError(data.message);
      }
    } catch (error) {
       const errorData = await error.response.json;
       this.handleError(errorData.message || "An unknown server error occurred.");
    }
  }

  reset() {
    this.statusTarget.textContent = "";
    this.urlInputTarget.classList.remove("border-green-500", "border-red-500");
    this.saveButtonTarget.disabled = true;
    
    // Dispatch an event to tell the rule editor to lock itself again.
    this.dispatch("reset");
  }

  handleError(message) {
    this.statusTarget.textContent = `❌ Error: ${message}`;
    this.statusTarget.className = "mt-2 text-sm h-5 text-red-400";
    this.urlInputTarget.classList.add("border-red-500");
    this.saveButtonTarget.disabled = true;
    this.dispatch("reset"); // Also lock the rule editor on error.
  }
}

