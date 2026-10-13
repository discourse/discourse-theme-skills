import Component from "@glimmer/component";
import { eq } from "discourse/truth-helpers";
import DSkeleton from "discourse/ui-kit/d-skeleton";

// Loading placeholder for a panel body, shaped like the rows it stands in
// for so the panel keeps its height when the data arrives:
//   { rows: "user", count }   avatar circle + name line + score
//   { rows: "event", count }  date badge + title line + date line
//   { rows: "topic", count }  title line + meta line
export default class BlockPanelSkeleton extends Component {
  get rows() {
    const count = this.args.shape?.count ?? 5;
    return Array.from({ length: count }, (_, index) => index);
  }

  <template>
    <div class="block-panel-skeleton" aria-hidden="true">
      {{#each this.rows as |row|}}
        {{#if (eq @shape.rows "event")}}
          <div class="block-panel-skeleton__row --event" data-row={{row}}>
            <DSkeleton @variant="rect" @width="3.5rem" @height="1.75rem" />
            <div class="block-panel-skeleton__lines">
              <DSkeleton @variant="text" @width="70%" />
              <DSkeleton @variant="text" @width="45%" />
            </div>
          </div>
        {{else if (eq @shape.rows "topic")}}
          <div class="block-panel-skeleton__row --topic" data-row={{row}}>
            <div class="block-panel-skeleton__lines">
              <DSkeleton @variant="text" @width="85%" />
              <DSkeleton @variant="text" @width="35%" />
            </div>
          </div>
        {{else}}
          <div class="block-panel-skeleton__row --user" data-row={{row}}>
            <DSkeleton @variant="circle" @size="1.5rem" />
            <DSkeleton @variant="text" @width="55%" />
            <DSkeleton @variant="text" @width="2.5rem" />
          </div>
        {{/if}}
      {{/each}}
    </div>
  </template>
}
