// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// From https://www.justin.ly/tree-shaking-fontawesome-5-icons/
// install @fortawesome/fontawesome-svg-core"
// and whatever set of icons you need https://www.npmjs.com/search?q=%40fortawesome
// @fortawesome/free-solid-svg-icons" has the basics
import { library, dom } from '@fortawesome/fontawesome-svg-core'
// Pick icons from https://fontawesome.com/icons?d=gallery&s=solid
// Import them here from solid, brands, etc
import {
  faGithub, faTwitter
} from '@fortawesome/free-brands-svg-icons'
import {
  faFlag as faFlagRegular,
  faCopy as faCopyRegular,
} from '@fortawesome/free-regular-svg-icons'
import {
  faThumbtack, faSignOutAlt, faFlag, faBars, faSearch
} from '@fortawesome/free-solid-svg-icons'
// Add them to the library here
library.add(faGithub, faTwitter, faThumbtack, faSignOutAlt, faFlag, faFlagRegular, faBars, faSearch, faCopyRegular)
// And make use of them in the classNames on <span> tags with no content
dom.watch()

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"
import { Socket } from "phoenix"
import LiveSocket from "phoenix_live_view"

const hooks = {
  shoutoutInit: {
    mounted() {
      // Validate shoutout form when mounted with text
      // i.e. user inputed text, moved away and came back so the browser fills the form automatically
      if (this.el.value) {
        const payload = {
          shoutout: {
            text: this.el.value
          }
        }
        this.pushEventTo("#shoutout-form", "validate", payload);
      }
    }
  },
  alertAutoDismissal: {
    mounted() {
      const el = this.el;
      setTimeout(() => {el.click()}, 2500);
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken }, hooks: hooks })
liveSocket.connect()

/**
 *  Nav menu
 */

const bars = document.getElementById("nav-bars");
const menu = document.getElementById("nav-menu");
bars.onclick = function () {
  menu.classList.toggle("hidden")
};

/**
 * Background image ResizeObserver, resets the `top` property to keep the image in place.
 */

const resizeObserver = new ResizeObserver(entries => {
  for (let entry of entries) {
    resetBackgroundTop(entry)
  }
});

const bg = document.querySelector('.bg')
let intTop = 0;
if (bg) {
  const initialTop = window.getComputedStyle(bg).getPropertyValue("top");
  const match = initialTop.match(/(-?\d+)px/)
  if (match) {
    intTop = parseInt(match[1]);
    resizeObserver.observe(bg);
  }
}

function resetBackgroundTop(bg) {
  let newTop = intTop + (window.innerWidth / 10);
  newTop = newTop > intTop ? intTop : newTop;
  bg.target.style.setProperty('top', `${newTop}px`);
}

/**
 * Stimulus configuration
 */
import { Application } from "stimulus"
import { definitionsFromContext } from "stimulus/webpack-helpers"

const application = Application.start()
const context = require.context("./controllers", true, /\.js$/)
application.load(definitionsFromContext(context))
