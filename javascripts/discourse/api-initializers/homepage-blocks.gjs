import BlockGroup from "discourse/blocks/builtin/block-group";
import { apiInitializer } from "discourse/lib/api";
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
        linkLabel: "homepage.featured_topics.link_label",
        linkUrl: `/tag/${encodeURIComponent(settings.featured_topics_tag.split("|")[0])}`,
        tag: settings.featured_topics_tag.split("|")[0],
        count: settings.featured_topics_count,
      },
      conditions: [
        { type: "setting", name: "tagging_enabled", enabled: true },
        {
          type: "setting",
          source: settings,
          name: "featured_topics_tag",
          enabled: true,
        },
      ],
    },
    {
      block: BlockFeaturedList,
      id: "featured-list",
      args: {
        title: "homepage.featured_list.title",
        linkLabel: "homepage.featured_list.link_label",
        linkUrl: "/latest",
        count: settings.featured_list_count,
        filter: settings.featured_list_filter,
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
            icon: "trophy",
            count: settings.leaderboard_count,
            linkLabel: "homepage.leaderboard.link_label",
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
            recentTitle: "homepage.events.recent_title",
            icon: "far-calendar",
            count: settings.events_count,
            linkLabel: "homepage.events.link_label",
            linkUrl: "/upcoming-events",
          },
          conditions: {
            type: "setting",
            name: "discourse_events_enabled",
            enabled: true,
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
        buttonLink: settings.cta_link,
      },
    },
  ]);
});
