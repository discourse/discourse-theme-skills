import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import { block } from "discourse/blocks";
import CategoryTitleLink from "discourse/components/category-title-link";
import Category from "discourse/models/category";
import dReplaceEmoji from "discourse/ui-kit/helpers/d-replace-emoji";

@block("theme:skills:category-topics", {
  description: "Recent topics from a specific category",
})
export default class BlockCategoryTopics extends Component {
  @service store;

  @tracked topics = null;
  @tracked category = null;

  constructor() {
    super(...arguments);
    const config = settings.category_topics[0] ?? {};
    const count = config.count ?? 10;
    const categoryId = config.category?.[0];

    if (!categoryId) {
      return;
    }

    this.category = Category.findById(categoryId);
    const filter = `c/${categoryId}`;

    this.store.findFiltered("topicList", { filter }).then((topicList) => {
      if (topicList.topics) {
        this.topics = topicList.topics.slice(0, count);
      }
    });
  }

  willDestroy() {
    super.willDestroy(...arguments);
    this.topics = null;
  }

  <template>
    {{#if this.topics}}
      <div class="block-category-topics__layout">
        <div class="block-category-topics__header">
          <CategoryTitleLink @category={{this.category}} />
        </div>
        <div class="block-category-topics__list">
          {{#each this.topics as |topic|}}
            <a href={{topic.url}} class="block-category-topics__topic">
              {{htmlSafe (dReplaceEmoji topic.fancy_title)}}
              <span class="block-category-topics__post-count">
                ({{topic.posts_count}})
              </span>
            </a>
          {{/each}}
        </div>
      </div>
    {{/if}}
  </template>
}
