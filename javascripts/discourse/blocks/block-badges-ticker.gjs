import Component from "@glimmer/component";
import { action } from "@ember/object";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";
import { themePrefix } from "virtual:theme";
import { block } from "discourse/blocks";
import BadgePill from "discourse/components/user-badge";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import { relativeAge } from "discourse/lib/formatter";
import UserBadge from "discourse/models/user-badge";
import DAsyncContent from "discourse/ui-kit/d-async-content";
import DButton from "discourse/ui-kit/d-button";
import DUserLink from "discourse/ui-kit/d-user-link";
import dAvatar from "discourse/ui-kit/helpers/d-avatar";
import { i18n } from "discourse-i18n";

const TIER_IDS = { gold: 1, silver: 2, bronze: 3 };

const TickerEntry = <template>
  <li class="badge-ticker-entry {{@grant.badge.badgeTypeClassName}}">
    <DUserLink @user={{@grant.user}} class="badge-ticker-entry__avatar">
      {{dAvatar @grant.user imageSize="large"}}
    </DUserLink>
    <div class="badge-ticker-entry__body">
      <DUserLink @user={{@grant.user}} class="badge-ticker-entry__username">
        {{@grant.user.username}}
      </DUserLink>
      {{! BadgePill doesn't splat attributes — the class must live on a wrapper }}
      <span class="badge-ticker-entry__badge">
        <BadgePill
          @badge={{@grant.badge}}
          @user={{@grant.user}}
          @showName={{true}}
        />
      </span>
      <span class="badge-ticker-entry__earned">{{@grant.earnedAgo}}</span>
    </div>
  </li>
</template>;

@block("theme:skills:badges-ticker", {
  description:
    "Recently awarded badges — as compact member rows or an arrow-navigated ticker",
  args: {
    title: { type: "string" },
    buttonLabel: { type: "string" },
    badgeIds: { type: "array", itemType: "number" },
    tiers: { type: "array", itemEnum: ["gold", "silver", "bronze"] },
    count: { type: "number", default: 6 },
    variant: {
      type: "string",
      enum: ["auto", "rows", "ticker"],
      default: "auto",
    },
  },
})
export default class BlockBadgesTicker extends Component {
  viewportEl = null;

  get variantClass() {
    return `--${this.args.variant ?? "auto"}`;
  }

  @action
  registerViewport(element) {
    this.viewportEl = element;
  }

  @action
  scrollPrev() {
    this.#scrollByPage(-1);
  }

  @action
  scrollNext() {
    this.#scrollByPage(1);
  }

  #scrollByPage(direction) {
    this.viewportEl?.scrollBy({
      left: direction * this.viewportEl.clientWidth * 0.8,
      behavior: "smooth",
    });
  }

  async resolveBadgeIds() {
    if (this.args.badgeIds?.length) {
      return this.args.badgeIds.map(Number);
    }

    const tierIds = (this.args.tiers ?? [])
      .map((tier) => TIER_IDS[tier])
      .filter(Boolean);

    const { badges } = await ajax("/badges.json").catch(() => ({ badges: [] }));

    return (badges ?? [])
      .filter(
        (badge) =>
          badge.enabled &&
          (!tierIds.length || tierIds.includes(badge.badge_type_id))
      )
      .map((badge) => badge.id);
  }

  @bind
  async fetchGrants() {
    const ids = await this.resolveBadgeIds();

    if (!ids.length) {
      return [];
    }

    const grants = await Promise.all(
      ids.map((id) => UserBadge.findByBadgeId(id).catch(() => []))
    );

    const seen = new Set();
    const entries = grants
      .flat()
      .filter((userBadge) => userBadge.user && userBadge.grantedAt)
      .sort((a, b) => b.grantedAt - a.grantedAt)
      .filter((userBadge) => {
        if (seen.has(userBadge.user.id)) {
          return false;
        }
        seen.add(userBadge.user.id);
        return true;
      })
      .slice(0, this.args.count);

    entries.forEach((userBadge) => {
      userBadge.earnedAgo = relativeAge(new Date(userBadge.grantedAt), {
        format: "medium",
        leaveAgo: true,
        wrapInSpan: false,
      });
    });

    return entries;
  }

  <template>
    <DAsyncContent @asyncData={{this.fetchGrants}}>
      <:loading></:loading>
      <:content as |grants|>
        {{#if grants.length}}
          <section class="block-badges-ticker {{this.variantClass}}">
            {{#if @title}}
              <h3 class="block-badges-ticker__title">
                {{i18n (themePrefix @title)}}
              </h3>
            {{/if}}

            <div class="block-badges-ticker__scroller">
              <DButton
                @icon="chevron-left"
                @action={{this.scrollPrev}}
                @translatedTitle={{i18n (themePrefix "badges_ticker.previous")}}
                class="block-badges-ticker__arrow --prev"
              />

              <div
                class="block-badges-ticker__viewport"
                {{didInsert this.registerViewport}}
              >
                <ul class="block-badges-ticker__track">
                  {{#each grants key="id" as |grant|}}
                    <TickerEntry @grant={{grant}} />
                  {{/each}}
                </ul>
              </div>

              <DButton
                @icon="chevron-right"
                @action={{this.scrollNext}}
                @translatedTitle={{i18n (themePrefix "badges_ticker.next")}}
                class="block-badges-ticker__arrow --next"
              />
            </div>

            {{#if @buttonLabel}}
              <DButton
                class="btn-default block-badges-ticker__button"
                @href="/badges"
                @translatedLabel={{i18n (themePrefix @buttonLabel)}}
              />
            {{/if}}
          </section>
        {{/if}}
      </:content>
    </DAsyncContent>
  </template>
}
