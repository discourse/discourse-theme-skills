import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

@block("theme:skills:cta", {
  description: "Call-to-action banner with title, description, and button",
  args: {
    title: { type: "string", required: true },
    description: { type: "string" },
    buttonLabel: { type: "string" },
    buttonLink: { type: "string" },
  },
})
export default class BlockCta extends Component {
  <template>
    <div class="block-cta__layout">
      <h2 class="block-cta__title">
        {{i18n (themePrefix @title)}}
      </h2>
      {{#if @description}}
        <p class="block-cta__description">
          {{i18n (themePrefix @description)}}
        </p>
      {{/if}}
      {{#if @buttonLink}}
        <DButton
          class="btn-primary block-cta__button"
          @href={{@buttonLink}}
          @translatedLabel={{i18n (themePrefix @buttonLabel)}}
        />
      {{/if}}
    </div>
  </template>
}
