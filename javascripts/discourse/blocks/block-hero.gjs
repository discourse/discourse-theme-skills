import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

@block("theme:skills:hero", {
  description: "Hero banner with title, subtitle, and call-to-action button",
  args: {
    title: { type: "string", required: true },
    subtitle: { type: "string" },
    buttonLabel: { type: "string" },
    buttonLink: { type: "string" },
  },
})
export default class BlockHero extends Component {
  <template>
    <div class="block-hero__layout">
      <div class="block-hero__content">
        <h1 class="block-hero__title">
          {{i18n (themePrefix @title)}}
        </h1>
        {{#if @subtitle}}
          <p class="block-hero__subtitle">
            {{i18n (themePrefix @subtitle)}}
          </p>
        {{/if}}
        {{#if @buttonLink}}
          <DButton
            class="btn-primary block-hero__button"
            @href={{@buttonLink}}
            @translatedLabel={{i18n (themePrefix @buttonLabel)}}
          />
        {{/if}}
      </div>
    </div>
  </template>
}
