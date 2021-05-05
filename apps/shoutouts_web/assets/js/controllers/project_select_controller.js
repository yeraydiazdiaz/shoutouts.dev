import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["repo"]

  all(event) {
    event.preventDefault()
    this.repoTargets.forEach(repo => repo.setAttribute("checked", "checked"))
  }

  none(event) {
    event.preventDefault()
    this.repoTargets.forEach(repo => repo.removeAttribute("checked"))
  }
}
