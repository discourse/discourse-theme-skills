import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { block } from "discourse/blocks";
import { ajax } from "discourse/lib/ajax";
import dIcon from "discourse/ui-kit/helpers/d-icon";
import { i18n } from "discourse-i18n";

@block("theme:skills:top-tags", {
  description: "Popular tags list",
  args: {
    title: { type: "string" },
    count: { type: "number", default: 10 },
  },
})
export default class BlockTopTags extends Component {
  @tracked topTags;

  constructor() {
    super(...arguments);
    this.getTags();
  }

  @action
  async getTags() {
    const count = this.args.count || 10;
    const tagsList = await ajax("/tags.json");
    this.topTags = tagsList.tags.slice(0, count);
  }

  <template>
    <div class="block-top-tags__layout">
      {{#if @title}}
        <h2 class="block-top-tags__title">
          {{i18n (themePrefix @title)}}
        </h2>
      {{/if}}
      {{#if this.topTags}}
        <ul class="block-top-tags__list">
          {{#each this.topTags as |tag|}}
            <li class="block-top-tags__item">
              {{dIcon "tag"}}
              <a href="/tag/{{tag.name}}">{{tag.name}}</a>
            </li>
          {{/each}}
        </ul>
      {{/if}}
    </div>
  </template>
}
