import Component from "@glimmer/component";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import getURL from "discourse/lib/get-url";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

@block("theme:skills:home-link", {
  description: "Sidebar link to the custom homepage",
  args: {
    label: { type: "string", required: true },
  },
})
export default class BlockHomeLink extends Component {
  @service router;

  get isHomepage() {
    return this.router.currentRouteName === "discovery.custom";
  }

  <template>
    <ul class="sidebar-section-link-list" aria-label="Home">
      <li class="sidebar-section-link-wrapper">
        <a
          class="sidebar-section-link sidebar-row
            {{if this.isHomepage 'active'}}"
          href={{getURL "/custom"}}
        >
          <span class="sidebar-section-link-prefix icon">{{dIcon
              "house"
            }}</span>
          <span class="sidebar-section-link-content-text">{{i18n
              (themePrefix @label)
            }}</span>
        </a>
      </li>
    </ul>
  </template>
}
