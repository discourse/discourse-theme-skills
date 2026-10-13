import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { themePrefix } from "virtual:theme";
import { block } from "discourse/blocks";
import { bind } from "discourse/lib/decorators";
import { longDate, shortDate, shortDateNoYear } from "discourse/lib/formatter";
import getURL from "discourse/lib/get-url";
import { i18n } from "discourse-i18n";
import BlockPanel from "../components/block-panel";
import { fetchEvents } from "../lib/events";

// The next events that are not over yet, or the most recent past ones under
// @recentTitle when none are coming up. The panel disappears when the events
// plugin answers 403/404, and when there are no events at all.
@block("theme:skills:upcoming-events", {
  description: "Upcoming events from the events plugin",
  args: {
    title: { type: "string", required: true },
    recentTitle: { type: "string", required: true },
    icon: { type: "string" },
    count: { type: "number", default: 5 },
    linkLabel: { type: "string" },
    linkUrl: { type: "string" },
  },
})
export default class BlockUpcomingEvents extends Component {
  @tracked hidden = false;
  @tracked recent = false;
  @tracked retryCount = 0;

  badgeDate = (event) => shortDateNoYear(event.date);

  fullDate = (event) =>
    event.allDay ? shortDate(event.date) : longDate(event.date);

  get title() {
    return i18n(
      themePrefix(this.recent ? this.args.recentTitle : this.args.title)
    );
  }

  get skeleton() {
    return { rows: "event", count: this.args.count };
  }

  get context() {
    return { count: this.args.count, retryCount: this.retryCount };
  }

  @bind
  retry() {
    this.retryCount++;
  }

  @bind
  async fetchEvents({ count }) {
    try {
      const result = await fetchEvents({ count });
      if (!this.isDestroying && !this.isDestroyed) {
        this.hidden = !result;
        this.recent = !!result?.recent;
      }
      return result?.events;
    } catch (error) {
      if (error.jqXHR?.status === 403 || error.jqXHR?.status === 404) {
        if (!this.isDestroying && !this.isDestroyed) {
          this.hidden = true;
        }
        return null;
      }
      throw error;
    }
  }

  <template>
    {{#unless this.hidden}}
      <BlockPanel
        @title={{this.title}}
        @icon={{@icon}}
        @asyncData={{this.fetchEvents}}
        @context={{this.context}}
        @skeleton={{this.skeleton}}
        @onRetry={{this.retry}}
        class="block-upcoming-events"
      >
        <:content as |events|>
          <ol class="block-upcoming-events__list">
            {{#each events key="id" as |event|}}
              <li class="block-upcoming-events__event">
                <a class="block-upcoming-events__link" href={{event.url}}>
                  <time
                    class="block-upcoming-events__date-badge"
                    datetime={{event.iso}}
                  >{{this.badgeDate event}}</time>
                  <span class="block-upcoming-events__event-info">
                    <span class="block-upcoming-events__event-title">
                      {{event.title}}
                    </span>
                    <span class="block-upcoming-events__event-long-date">
                      {{this.fullDate event}}
                    </span>
                  </span>
                </a>
              </li>
            {{/each}}
          </ol>
        </:content>
        <:footer>
          {{#if @linkUrl}}
            <a class="block-panel__link" href={{getURL @linkUrl}}>
              {{i18n (themePrefix @linkLabel)}}
            </a>
          {{/if}}
        </:footer>
      </BlockPanel>
    {{/unless}}
  </template>
}
