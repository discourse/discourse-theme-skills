import Component from "@glimmer/component";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import BasicTopicList from "discourse/components/basic-topic-list";
import { bind } from "discourse/lib/decorators";
import DAsyncContent from "discourse/ui-kit/d-async-content";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

@block("theme:skills:featured-list", {
  description: "A filterable list of topics with heading and link",
  args: {
    title: { type: "string" },
    linkText: { type: "string" },
    linkUrl: { type: "string" },
  },
})
export default class BlockFeaturedList extends Component {
  @service store;

  @bind
  async fetchTopics() {
    const config = settings.featured_list[0] ?? {};
    const filter = config.filter ?? "latest";
    const count = config.count ?? 10;

    const topicList = await this.store.findFiltered("topicList", { filter });
    if (!topicList.topics?.length) {
      return null;
    }
    return topicList.topics.slice(0, count);
  }

  <template>
    <DAsyncContent @asyncData={{this.fetchTopics}}>
      <:loading>
        <div class="block-featured-list__loading"><div class="spinner" /></div>
      </:loading>

      <:empty>
        <div class="block-featured-list__empty">
          {{i18n "topics.none.latest"}}
        </div>
      </:empty>

      <:content as |topics|>
        <div class="block-featured-list__layout">
          {{#if @title}}
            <div class="block-featured-list__header">
              <h2 class="block-featured-list__title">
                {{i18n (themePrefix @title)}}
              </h2>
              {{#if @linkUrl}}
                <DButton
                  class="btn-flat block-featured-list__link"
                  @href={{@linkUrl}}
                  @translatedLabel={{i18n (themePrefix @linkText)}}
                />
              {{/if}}
            </div>
          {{/if}}
          <div class="block-featured-list__list">
            <BasicTopicList @topics={{topics}} @showPosters="true" />
          </div>
        </div>
      </:content>
    </DAsyncContent>
  </template>
}
