import Component from "@glimmer/component";
import { service } from "@ember/service";
import { block } from "discourse/blocks";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import { or } from "discourse/truth-helpers";
import DAsyncContent from "discourse/ui-kit/d-async-content";
import DButton from "discourse/ui-kit/d-button";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import dNumber from "discourse/ui-kit/helpers/d-number";
import { i18n } from "discourse-i18n";

@block("theme:skills:leaderboard", {
  description: "Gamification leaderboard showing top users",
  args: {
    title: { type: "string" },
    buttonLabel: { type: "string", required: true },
  },
})
export default class BlockLeaderboard extends Component {
  @service siteSettings;

  @bind
  async fetchLeaderboard() {
    const count = settings.leaderboard[0]?.count ?? 8;
    const data = await ajax("/leaderboard", { data: { user_limit: count } });

    const users = (data.users || []).map((user, index) => ({
      ...user,
      isCurrentUser: user.id === data.personal?.user?.id,
      isTopRanked: index === 0,
    }));

    return {
      leaderboard: data.leaderboard,
      users,
      personal: data.personal,
      currentUserNotInTop: data.personal?.position > count,
    };
  }

  <template>
    <DAsyncContent @asyncData={{this.fetchLeaderboard}}>
      <:loading>
        <div class="block-leaderboard__loading"><div class="spinner" /></div>
      </:loading>

      <:content as |data|>
        <div class="block-leaderboard__layout">
          {{#if @title}}
            <h2 class="block-leaderboard__title">
              {{i18n (themePrefix @title)}}
            </h2>
          {{/if}}

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

            {{#each data.users as |rank|}}
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

          <DButton
            class="btn-default block-leaderboard__button"
            @href="/leaderboard/{{data.leaderboard.id}}"
            @translatedLabel={{i18n (themePrefix @buttonLabel)}}
          />
        </div>
      </:content>
    </DAsyncContent>
  </template>
}
