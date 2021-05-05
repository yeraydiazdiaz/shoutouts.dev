import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["repo"]

  all() {
    this.repoTargets.forEach(repo => repo.setAttribute("checked", "checked"))
  }

  none() {
    this.repoTargets.forEach(repo => repo.removeAttribute("checked"))
  }
}
