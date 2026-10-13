import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";
import { themePrefix } from "virtual:theme";
import { block } from "discourse/blocks";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import getURL from "discourse/lib/get-url";
import { or } from "discourse/truth-helpers";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dNumber from "discourse/ui-kit/helpers/d-number";
import { i18n } from "discourse-i18n";
import BlockPanel from "../components/block-panel";

// Top users of the gamification plugin's default leaderboard. Without a
// title the panel shows the leaderboard's own name. The panel disappears
// when the plugin answers 403/404.
@block("theme:skills:leaderboard", {
  description: "Gamification leaderboard showing top users",
  args: {
    title: { type: "string" },
    icon: { type: "string" },
    count: { type: "number", default: 8 },
    linkLabel: { type: "string", required: true },
  },
})
export default class BlockLeaderboard extends Component {
  @service siteSettings;

  @tracked unavailable = false;
  @tracked leaderboard;
  @tracked retryCount = 0;

  get title() {
    return this.args.title
      ? i18n(themePrefix(this.args.title))
      : this.leaderboard?.name;
  }

  get leaderboardUrl() {
    return getURL(
      this.leaderboard ? `/leaderboard/${this.leaderboard.id}` : "/leaderboard"
    );
  }

  get skeleton() {
    return { rows: "user", count: this.args.count };
  }

  get context() {
    return { count: this.args.count, retryCount: this.retryCount };
  }

  @bind
  retry() {
    this.retryCount++;
  }

  @bind
  async fetchLeaderboard({ count }) {
    try {
      const data = await ajax("/leaderboard", { data: { user_limit: count } });
      if (!this.isDestroying && !this.isDestroyed) {
        this.leaderboard = data.leaderboard;
      }
      if (!data.users?.length) {
        return null;
      }

      const personal = data.personal;
      return {
        users: data.users.map((user) => ({
          ...user,
          isCurrentUser: user.id === personal?.user?.id,
        })),
        personal,
        currentUserNotInTop: personal?.position > count,
      };
    } catch (error) {
      if (error.jqXHR?.status === 403 || error.jqXHR?.status === 404) {
        if (!this.isDestroying && !this.isDestroyed) {
          this.unavailable = true;
        }
        return null;
      }
      throw error;
    }
  }

  <template>
    {{#unless this.unavailable}}
      <BlockPanel
        @title={{this.title}}
        @icon={{@icon}}
        @asyncData={{this.fetchLeaderboard}}
        @context={{this.context}}
        @skeleton={{this.skeleton}}
        @onRetry={{this.retry}}
        class="block-leaderboard"
      >
        <:content as |data|>
          <div class="block-leaderboard__list">
            {{#if data.currentUserNotInTop}}
              <div class="block-leaderboard__row --self">
                <span class="block-leaderboard__rank">
                  {{data.personal.position}}
                </span>
                <span class="block-leaderboard__name">
                  {{i18n "gamification.you"}}
                </span>
                <span class="block-leaderboard__score">
                  {{dNumber data.personal.user.total_score}}
                </span>
              </div>
            {{/if}}

            {{#each data.users key="id" as |rank|}}
              <div
                class="block-leaderboard__row
                  {{if rank.isCurrentUser '--highlight'}}"
              >
                <div
                  class="block-leaderboard__user"
                  data-user-card={{rank.username}}
                >
                  {{dAvatar rank imageSize="small"}}
                  <span class="block-leaderboard__name">
                    {{#if this.siteSettings.prioritize_username_in_ux}}
                      {{rank.username}}
                    {{else}}
                      {{or rank.name rank.username}}
                    {{/if}}
                  </span>
                </div>
                <span class="block-leaderboard__score">
                  {{dNumber rank.total_score}}
                </span>
              </div>
            {{/each}}
          </div>
        </:content>
        <:footer>
          <a class="block-panel__link" href={{this.leaderboardUrl}}>
            {{i18n (themePrefix @linkLabel)}}
          </a>
        </:footer>
      </BlockPanel>
    {{/unless}}
  </template>
}
