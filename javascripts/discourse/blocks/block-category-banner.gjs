import Component from "@glimmer/component";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import CategoryLogo from "discourse/components/category-logo";
import { and, or } from "discourse/truth-helpers";
import { i18n } from "discourse-i18n";

// Name, logo and description of the current category. With @categoryIds the
// banner only shows on those categories and their subcategories.
@block("theme:skills:category-banner", {
  description:
    "Dynamic banner for category pages showing name, logo, and description",
  args: {
    categoryIds: { type: "array", itemType: "number", default: [] },
    showDescription: { type: "boolean", default: true },
    showLogo: { type: "boolean", default: true },
  },
})
export default class BlockCategoryBanner extends Component {
  @service discovery;

  get category() {
    const category = this.discovery.category;
    const ids = this.args.categoryIds;
    if (!category || !ids?.length) {
      return category;
    }
    return ids.includes(category.id) ||
      ids.includes(category.parent_category_id)
      ? category
      : null;
  }

  <template>
    {{#if this.category}}
      <div class="block-category-banner__layout">
        {{#if (and @showLogo this.category.uploaded_logo)}}
          <div class="block-category-banner__logo">
            <CategoryLogo @category={{this.category}} />
          </div>
        {{/if}}
        <div class="block-category-banner__content">
          <h1 class="block-category-banner__name">
            {{this.category.displayName}}
          </h1>
          {{#if @showDescription}}
            <p class="block-category-banner__description">
              {{or
                this.category.descriptionText
                (i18n (themePrefix "category_banner.fallback_description"))
              }}
            </p>
          {{/if}}
        </div>
      </div>
    {{/if}}
  </template>
}
