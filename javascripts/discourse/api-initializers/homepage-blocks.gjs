import BlockGroup from "discourse/blocks/builtin/block-group";
import { apiInitializer } from "discourse/lib/api";
import BlockBadgesTicker from "../blocks/block-badges-ticker";
import BlockCta from "../blocks/block-cta";
import BlockFeaturedList from "../blocks/block-featured-list";
import BlockFeaturedTopics from "../blocks/block-featured-topics";
import BlockLeaderboard from "../blocks/block-leaderboard";
import BlockUpcomingEvents from "../blocks/block-upcoming-events";

export default apiInitializer((api) => {
  api.renderBlocks("homepage-blocks", [
    {
      block: BlockFeaturedTopics,
      id: "featured-topics",
      args: {
        title: "homepage.featured_topics.title",
        linkText: "homepage.featured_topics.link_text",
      },
      conditions: { type: "setting", name: "tagging_enabled", enabled: true },
    },
    {
      block: BlockBadgesTicker,
      id: "badges-ticker",
      args: {
        title: "homepage.badges_ticker.title",
        buttonLabel: "homepage.badges_ticker.button_label",
        variant: "ticker",
      },
      conditions: {
        type: "setting",
        source: settings.badges_ticker[0],
        name: "placement",
        equals: "homepage-main",
      },
    },
    {
      block: BlockFeaturedList,
      id: "featured-list",
      args: {
        title: "homepage.featured_list.title",
        linkText: "homepage.featured_list.link_text",
        linkUrl: "/latest",
      },
    },
    {
      block: BlockGroup,
      id: "homepage-right",
      children: [
        {
          block: BlockLeaderboard,
          id: "homepage-leaderboard",
          args: {
            title: "homepage.leaderboard.title",
            buttonLabel: "homepage.leaderboard.button_label",
          },
          conditions: {
            type: "setting",
            name: "discourse_gamification_enabled",
            enabled: true,
          },
        },
        {
          block: BlockUpcomingEvents,
          id: "homepage-events",
          args: {
            title: "homepage.events.title",
            buttonLabel: "homepage.events.button_label",
            linkLabel: "homepage.events.link_label",
            linkUrl: "/upcoming-events",
          },
          conditions: {
            type: "setting",
            name: "calendar_enabled",
            enabled: true,
          },
        },
        {
          block: BlockBadgesTicker,
          id: "homepage-badges",
          args: {
            title: "homepage.badges_ticker.title",
            buttonLabel: "homepage.badges_ticker.button_label",
            variant: "rows",
          },
          conditions: {
            type: "setting",
            source: settings.badges_ticker[0],
            name: "placement",
            equals: "homepage-sidebar",
          },
        },
      ],
    },
    {
      block: BlockCta,
      id: "homepage-cta",
      args: {
        title: "homepage.cta.title",
        description: "homepage.cta.description",
        buttonLabel: "homepage.cta.button_label",
      },
    },
  ]);
});
