import BlockGroup from "discourse/blocks/builtin/block-group";
import { apiInitializer } from "discourse/lib/api";
import BlockBadgesTicker from "../blocks/block-badges-ticker";
import BlockCta from "../blocks/block-cta";
import BlockFeaturedList from "../blocks/block-featured-list";
import BlockFeaturedTopics from "../blocks/block-featured-topics";
import BlockLeaderboard from "../blocks/block-leaderboard";
import BlockUpcomingEvents from "../blocks/block-upcoming-events";

function idList(value) {
  return value ? String(value).split("|").map(Number).filter(Boolean) : [];
}

function settingList(value) {
  return value ? String(value).split("|") : [];
}

export default apiInitializer((api) => {
  api.renderBlocks("homepage-blocks", [
    {
      block: BlockFeaturedTopics,
      id: "featured-topics",
      args: {
        title: "homepage.featured_topics.title",
        linkText: "homepage.featured_topics.link_text",
        linkUrl: `/tag/${settings.featured_topics_tag}`,
        tag: settings.featured_topics_tag,
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
      block: BlockBadgesTicker,
      id: "badges-ticker",
      args: {
        title: "homepage.badges_ticker.title",
        buttonLabel: "homepage.badges_ticker.button_label",
        variant: "ticker",
        count: settings.badges_ticker_count,
        badgeIds: idList(settings.badges_ticker_badge_ids),
        tiers: settingList(settings.badges_ticker_tiers),
      },
      conditions: {
        type: "setting",
        source: settings,
        name: "badges_ticker_location",
        equals: "main",
      },
    },
    {
      block: BlockFeaturedList,
      id: "featured-list",
      args: {
        title: "homepage.featured_list.title",
        linkText: "homepage.featured_list.link_text",
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
            count: settings.leaderboard_count,
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
            count: settings.events_count,
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
            count: settings.badges_ticker_count,
            badgeIds: idList(settings.badges_ticker_badge_ids),
            tiers: settingList(settings.badges_ticker_tiers),
          },
          conditions: {
            type: "setting",
            source: settings,
            name: "badges_ticker_location",
            equals: "sidebar",
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
