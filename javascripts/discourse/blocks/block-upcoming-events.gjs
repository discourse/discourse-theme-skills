import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import { longDate, shortDateNoYear } from "discourse/lib/formatter";
import { or } from "discourse/truth-helpers";
import DAsyncContent from "discourse/ui-kit/d-async-content";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

@block("theme:skills:upcoming-events", {
  description: "Upcoming events from discourse-post-event plugin",
  args: {
    title: { type: "string" },
    count: { type: "number", default: 5 },
    buttonLabel: { type: "string", required: true },
    linkLabel: { type: "string" },
    linkUrl: { type: "string" },
  },
})
export default class BlockUpcomingEvents extends Component {
  @bind
  async fetchEvents() {
    const count = this.args.count || 5;
    const results = await ajax("discourse-post-event/events");
    if (!results.events?.length) {
      return null;
    }
    return results.events.slice(0, count);
  }

  getShortDate(startsAt) {
    return shortDateNoYear(new Date(startsAt));
  }

  getLongDate(startsAt) {
    return longDate(new Date(startsAt));
  }

  <template>
    <DAsyncContent @asyncData={{this.fetchEvents}}>
      <:loading>
        <div class="block-upcoming-events__loading">
          <div class="spinner" />
        </div>
      </:loading>

      <:empty>
        <div class="block-upcoming-events__empty">
          {{i18n "discourse_post_event.events_list.empty"}}
        </div>
      </:empty>

      <:content as |events|>
        <div class="block-upcoming-events__layout">
          {{#if @title}}
            <h2 class="block-upcoming-events__title">
              {{i18n (themePrefix @title)}}
            </h2>
          {{/if}}
          <div class="block-upcoming-events__list">
            {{#each events as |event|}}
              <div class="block-upcoming-events__event">
                <span class="block-upcoming-events__date-badge">
                  {{this.getShortDate event.starts_at}}
                </span>
                <div class="block-upcoming-events__event-info">
                  <h3 class="block-upcoming-events__event-title">
                    {{or event.name event.post.topic.title}}
                  </h3>
                  <span class="block-upcoming-events__event-long-date">
                    {{this.getLongDate event.starts_at}}
                  </span>
                </div>
                <DButton
                  class="btn-flat"
                  @href={{event.post.url}}
                  @translatedLabel={{i18n (themePrefix @buttonLabel)}}
                />
              </div>
            {{/each}}
          </div>
          {{#if @linkUrl}}
            <DButton
              class="btn-default block-upcoming-events__link"
              @href={{@linkUrl}}
              @translatedLabel={{i18n (themePrefix @linkLabel)}}
            />
          {{/if}}
        </div>
      </:content>
    </DAsyncContent>
  </template>
}
