import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import BasicTopicList from "discourse/components/basic-topic-list";
import { bind } from "discourse/lib/decorators";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import BlockPanel from "../components/block-panel";

@block("theme:skills:featured-list", {
  description: "A filterable list of topics in a panel",
  args: {
    title: { type: "string", required: true },
    icon: { type: "string" },
    linkLabel: { type: "string" },
    linkUrl: { type: "string" },
    count: { type: "number", default: 10 },
    filter: { type: "string", default: "latest" },
  },
})
export default class BlockFeaturedList extends Component {
  @service store;

  @tracked retryCount = 0;

  get skeleton() {
    return { rows: "topic", count: this.args.count };
  }

  get context() {
    return {
      filter: this.args.filter,
      count: this.args.count,
      retryCount: this.retryCount,
    };
  }

  @bind
  retry() {
    this.retryCount++;
  }

  @bind
  async fetchTopics({ filter, count }) {
    const topicList = await this.store.findFiltered("topicList", { filter });
    const topics = topicList.topics?.slice(0, count) ?? [];
    return topics.length ? topics : null;
  }

  <template>
    <BlockPanel
      @title={{i18n (themePrefix @title)}}
      @icon={{@icon}}
      @asyncData={{this.fetchTopics}}
      @context={{this.context}}
      @skeleton={{this.skeleton}}
      @onRetry={{this.retry}}
      class="block-featured-list"
    >
      <:content as |topics|>
        <div class="block-featured-list__list">
          <BasicTopicList @topics={{topics}} @showPosters="true" />
        </div>
      </:content>
      <:empty>
        <p class="block-featured-list__empty">
          {{i18n "topics.none.latest"}}
        </p>
      </:empty>
      <:footer>
        {{#if @linkUrl}}
          <a class="block-panel__link" href={{getURL @linkUrl}}>
            {{i18n (themePrefix @linkLabel)}}
          </a>
        {{/if}}
      </:footer>
    </BlockPanel>
  </template>
}
