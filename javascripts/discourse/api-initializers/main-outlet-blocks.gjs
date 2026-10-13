import { apiInitializer } from "discourse/lib/api";
import BlockCategoryBanner from "../blocks/block-category-banner";
import BlockHero from "../blocks/block-hero";

export default apiInitializer((api) => {
  api.renderBlocks("main-outlet-blocks", [
    {
      block: BlockHero,
      id: "homepage-hero",
      args: {
        title: "hero.title",
        subtitle: "hero.subtitle",
        buttonLabel: "hero.button_label",
        buttonLink: "/signup",
      },
      conditions: { type: "route", pages: ["HOMEPAGE"] },
    },
    {
      block: BlockCategoryBanner,
      id: "category-banner",
      args: {
        categoryIds: settings.banner_categories
          .split("|")
          .filter(Boolean)
          .map(Number),
        showDescription: true,
        showLogo: true,
      },
      conditions: { type: "route", pages: ["CATEGORY_PAGES"] },
    },
  ]);
});
