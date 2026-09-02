import Component from "@glimmer/component";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import { bind } from "discourse/lib/decorators";
import DAsyncContent from "discourse/ui-kit/d-async-content";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import { i18n } from "discourse-i18n";

@block("theme:skills:featured-topics", {
  description: "Card grid of topics filtered by tag",
  args: {
    title: { type: "string" },
    linkText: { type: "string" },
  },
})
export default class BlockFeaturedTopics extends Component {
  @service store;

  get config() {
    return settings.featured_topics[0] ?? {};
  }

  get tag() {
    return this.config.tag?.[0];
  }

  get linkUrl() {
    return this.tag && `/tag/${this.tag}`;
  }

  @bind
  async fetchTopics() {
    const filter = `tag/${this.tag}/l/latest`;
    const count = this.config.count ?? 6;

    const topicList = await this.store.findFiltered("topicList", { filter });
    if (!topicList.topics?.length) {
      return null;
    }
    return topicList.topics.slice(0, count);
  }

  <template>
    {{#if this.tag}}
      <DAsyncContent @asyncData={{this.fetchTopics}}>
        <:loading>
          <div class="block-featured-topics__loading">
            <div class="spinner" />
          </div>
        </:loading>

        <:empty>
          <div class="block-featured-topics__empty">
            {{i18n "topics.none.latest"}}
          </div>
        </:empty>

        <:content as |topics|>
          <div class="block-featured-topics__layout">
            {{#if @title}}
              <div class="block-featured-topics__header">
                <h2 class="block-featured-topics__heading">
                  {{i18n (themePrefix @title)}}
                </h2>
                {{#if this.linkUrl}}
                  <a
                    href={{this.linkUrl}}
                    class="block-featured-topics__link"
                  >{{i18n (themePrefix @linkText)}}</a>
                {{/if}}
              </div>
            {{/if}}

            <div class="block-featured-topics__grid">
              {{#each topics as |topic|}}
                <a href={{topic.url}} class="block-featured-topics__card">
                  <div class="block-featured-topics__card-body">
                    <h3 class="block-featured-topics__card-title">
                      {{topic.title}}
                    </h3>
                    {{#if topic.excerpt}}
                      <p class="block-featured-topics__card-excerpt">
                        {{topic.excerpt}}
                      </p>
                    {{/if}}
                  </div>
                  <div class="block-featured-topics__card-meta">
                    <div class="block-featured-topics__card-author">
                      {{dAvatar topic.creator imageSize="tiny"}}
                      <span>{{topic.creator.username}}</span>
                    </div>
                    {{dCategoryLink topic.category}}
                  </div>
                </a>
              {{/each}}
            </div>
          </div>
        </:content>
      </DAsyncContent>
    {{/if}}
  </template>
}
