import Component from "@glimmer/component";
import { service } from "@ember/service";
import { trustHTML } from "@ember/template";
import { block } from "discourse/blocks";
import { bind } from "discourse/lib/decorators";
import DAsyncContent from "discourse/ui-kit/d-async-content";
import DSkeleton from "discourse/ui-kit/d-skeleton";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dCategoryLink from "discourse/ui-kit/helpers/d-category-link";
import { i18n } from "discourse-i18n";

@block("theme:skills:featured-topics", {
  description: "Card grid of topics filtered by tag",
  args: {
    title: { type: "string" },
    linkLabel: { type: "string" },
    linkUrl: { type: "string" },
    tag: { type: "string", required: true },
    count: { type: "number", default: 6 },
    filter: { type: "string", default: "latest" },
  },
})
export default class BlockFeaturedTopics extends Component {
  @service store;

  get placeholders() {
    return Array.from({ length: this.args.count });
  }

  @bind
  async fetchTopics() {
    const tag = encodeURIComponent(this.args.tag);
    const filter = `tag/${tag}/l/${this.args.filter}`;
    const topicList = await this.store.findFiltered("topicList", { filter });
    const topics = topicList.topics?.slice(0, this.args.count) ?? [];
    return topics.length ? topics : null;
  }

  <template>
    <DAsyncContent @asyncData={{this.fetchTopics}}>
      <:loading>
        <div class="block-featured-topics__grid" aria-busy="true">
          {{#each this.placeholders}}
            <DSkeleton @variant="rect" @height="10rem" />
          {{/each}}
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
              {{#if @linkUrl}}
                <a href={{@linkUrl}} class="block-featured-topics__link">{{i18n
                    (themePrefix @linkLabel)
                  }}</a>
              {{/if}}
            </div>
          {{/if}}

          <div class="block-featured-topics__grid">
            {{#each topics as |topic|}}
              <a href={{topic.url}} class="block-featured-topics__card">
                <div class="block-featured-topics__card-body">
                  <h3 class="block-featured-topics__card-title">
                    {{trustHTML topic.fancyTitle}}
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
  </template>
}
