import { Controller } from "stimulus"

export default class extends Controller {
  static values = {text: String}
  static targets = ["feedback"]

  copy() {
    if (!this.textValue) {
      console.error("Element missing data-clipboard-text attribute");
    } else if (!this.feedbackTarget) {
      console.error("Missing feedback element");
    } else if (!navigator.clipboard) {
      setTimeout(() => this.feedbackTarget.classList.add("hidden"), 1500);
      this.feedbackTarget.classList.remove("hidden")
      this.feedbackTarget.textContent = "Unsupported browser :(";
    } else {
      setTimeout(() => this.feedbackTarget.classList.add("hidden"), 1500);
      navigator.clipboard.writeText(this.textValue).then(
        () => {
          this.feedbackTarget.classList.remove("hidden")
          this.feedbackTarget.textContent = "Copied!";
        },
        (err) => {
          console.error('Could not copy text: ', err);
          this.feedbackTarget.classList.remove("hidden")
          this.feedbackTarget.textContent = "Error :(";
        }
      );
    }
  }
}
