import { themePrefix } from "virtual:theme";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

// The failed-load message and retry button of a panel body.
// @onRetry runs when the button is pressed
const BlockPanelError = <template>
  <div class="block-panel-error">
    <p class="block-panel-error__message" role="alert">
      {{i18n (themePrefix "panel.load_error")}}
    </p>
    <DButton
      @action={{@onRetry}}
      @label={{themePrefix "panel.retry"}}
      class="btn-small block-panel-error__button"
    />
  </div>
</template>;

export default BlockPanelError;
