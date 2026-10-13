---
name: discourse-block-authoring
description: Use when creating, registering, or rendering Discourse block components in themes — covers the @block decorator, plugin API registration, layout files and settings, outlets, conditions, container blocks, async data in panels, and testing
---

# Discourse Block Authoring

Blocks are the modular UI composition system in Discourse. They allow themes to define self-contained Glimmer components that can be registered, conditionally shown, and rendered into named outlets throughout the app.

## Conventions

### File Structure

```
javascripts/discourse/
├── api-initializers/
│   ├── homepage-blocks.gjs       # one file per outlet
│   ├── hero-blocks.gjs
│   ├── sidebar-discovery-blocks.gjs
│   └── main-outlet-blocks.gjs
├── blocks/
│   ├── block-hero.gjs             # always prefixed block-
│   ├── block-featured-list.gjs
│   └── block-leaderboard.gjs
├── components/
│   └── block-panel.gjs            # shared chrome used by several blocks
└── lib/
    └── events.js                  # data helpers shared by blocks
```

- Block files are always named `block-*.gjs` inside `blocks/`
- Components shared by blocks (the panel, its skeleton) live in `components/`; data helpers in `lib/`
- Initializer files are named after the outlet they configure (e.g., `homepage-blocks.gjs`)
- **Exactly one initializer file per outlet, and exactly one outlet per initializer file.** Never call `api.renderBlocks()` for two different outlets in the same file. If you need to render into `main-outlet-blocks` and `homepage-blocks`, create two separate initializer files.

### Block Names

Block names follow a strict namespacing pattern:

| Context | Pattern                       | Example               |
| ------- | ----------------------------- | --------------------- |
| Core    | `block-name`                  | `group`, `head`       |
| Plugin  | `plugin-name:block-name`      | `chat:message-widget` |
| Theme   | `theme:theme-name:block-name` | `theme:tactile:hero`  |

Append `?` to mark a reference as optional (no error if not registered):

```javascript
{
  block: "chat:sidebar-widget?";
}
```

## Defining a Block

Use the `@block` decorator on a Glimmer component:

```javascript
import Component from "@glimmer/component";
import { block } from "discourse/blocks";
import DButton from "discourse/ui-kit/d-button";

@block("theme:my-theme:hero", {
  description: "A hero banner with title, subtitle, and button",
  args: {
    title:       { type: "string" },
    subtitle:    { type: "string" },
    buttonLabel: { type: "string" },
    buttonLink:  { type: "string" },
    buttonIcon:  { type: "string" },
    image:       { type: "string" },
  },
})
export default class BlockHero extends Component {
  <template>
    <div class="block-hero__layout">
      {{#if @title}}<h1 class="block-hero__title">{{@title}}</h1>{{/if}}
      {{#if @buttonLink}}
        <DButton
          class="btn-primary"
          @icon={{@buttonIcon}}
          @href={{@buttonLink}}
          @translatedLabel={{@buttonLabel}}
        />
      {{/if}}
    </div>
  </template>
}
```

### Decorator Options

| Option                | Type                     | Description                                      |
| --------------------- | ------------------------ | ------------------------------------------------ |
| `description`         | string                   | Human-readable label                             |
| `args`                | object                   | Schema for block arguments                       |
| `childArgs`           | object                   | Schema for children args (container blocks only) |
| `container`           | boolean                  | Whether this block renders children              |
| `allowedOutlets`      | string[]                 | Restrict to specific outlets                     |
| `deniedOutlets`       | string[]                 | Exclude from specific outlets                    |
| `classNames`          | string \| string[] \| fn | Extra CSS classes on the wrapper                 |
| `constraints`         | object                   | Cross-arg validation rules                       |

### Args Schema

```javascript
args: {
  title:    { type: "string",  required: true },
  count:    { type: "number",  default: 5, min: 1, max: 50 },
  visible:  { type: "boolean", default: true },
  variant:  { type: "string",  enum: ["small", "large"] },
  badgeIds: { type: "array",   itemType: "number" },
  tiers:    { type: "array",   itemEnum: ["gold", "silver", "bronze"] },
}
```

Valid arg types: `string`, `number`, `boolean`, `array`, `object`, `any`.

Valid schema properties (anything else raises a `BlockError` at registration): `type`, `required`, `default`, `itemType`, `itemEnum`, `pattern`, `minLength`, `maxLength`, `min`, `max`, `integer`, `enum`, `properties`, `instanceOf`, `instanceOfName`.

Property applicability by type: `min`/`max`/`integer` → number; `minLength`/`maxLength` → string or array; `pattern` (RegExp) → string; `enum` → string or number; `itemType` (`string`/`number`/`boolean`) and `itemEnum` → array; `properties`/`instanceOf` → object.

### Dynamic CSS Classes

`classNames` can be a function that receives the block's args:

```javascript
@block("theme:my-theme:card", {
  args: {
    variant: { type: "string", enum: ["compact", "full"] },
  },
  classNames: (args) => `--${args.variant}`,
})
```

### Constraints

Constraints validate relationships between args at registration time:

```javascript
@block("theme:my-theme:media", {
  args: {
    imageUrl: { type: "string" },
    videoUrl: { type: "string" },
    altText:  { type: "string" },
  },
  constraints: {
    atLeastOne: ["imageUrl", "videoUrl"],  // at least one must be provided
    atMostOne: ["imageUrl", "videoUrl"],   // no more than one
    requires: { altText: "imageUrl" },     // altText requires imageUrl
  },
})
```

Available constraint types: `atLeastOne`, `exactlyOne`, `allOrNone`, `atMostOne`, `requires`.

### Async Data

Blocks that load data render inside a shared panel component (see `javascripts/discourse/components/block-panel.gjs` in this repo). The panel owns the chrome — header (icon + title), body, footer with one link — and wraps only the body in `DAsyncContent`, so the header and footer stay put while data loads:

- **Loading:** a skeleton shaped like the rows it replaces (`@skeleton={{hash rows="user" count=@count}}`), never a spinner, so the panel keeps its height.
- **Errors:** pass `@onRetry`; a failed load shows a message and a retry button. Retry by bumping a tracked counter that is part of `@context`, which makes `DAsyncContent` refetch.
- **Missing plugin:** treat a 403/404 from a plugin endpoint as "not available" and render nothing, instead of relying only on a setting condition.
- **Empty:** return `null` from the fetch for "no data" and either yield `<:empty>` or hide the block.

```javascript
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { hash } from "@ember/helper";
import { themePrefix } from "virtual:theme";
import { block } from "discourse/blocks";
import { ajax } from "discourse/lib/ajax";
import { bind } from "discourse/lib/decorators";
import { i18n } from "discourse-i18n";
import BlockPanel from "../components/block-panel";

@block("theme:my-theme:leaderboard", {
  args: {
    title: { type: "string", required: true },
    icon: { type: "string" },
    count: { type: "number", default: 8 },
    linkLabel: { type: "string", required: true },
  },
})
export default class BlockLeaderboard extends Component {
  @tracked unavailable = false;
  @tracked retryCount = 0;

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
      return data.users?.length ? data.users : null;
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
        @title={{i18n (themePrefix @title)}}
        @icon={{@icon}}
        @asyncData={{this.fetchLeaderboard}}
        @context={{this.context}}
        @skeleton={{hash rows="user" count=@count}}
        @onRetry={{this.retry}}
        class="block-leaderboard"
      >
        <:content as |users|>{{! rows }}</:content>
        <:footer>
          <a class="block-panel__link" href="/leaderboard">
            {{i18n (themePrefix @linkLabel)}}
          </a>
        </:footer>
      </BlockPanel>
    {{/unless}}
  </template>
}
```

### Rendering Content

Reuse what core already does for its own lists, so blocks match the rest of the site:

| Content | Use | Not |
| --- | --- | --- |
| Category name / description | `category.displayName`, `category.descriptionText` (run through the `category-display-name` / `category-description-text` transformers) | `category.name`, `category.description_text` |
| Topic title in hand-rolled markup | `{{trustHTML topic.fancyTitle}}` (emoji, censored words) | `topic.title` |
| Counts | `dNumber` helper, or `number()` from `discourse/lib/formatter` inside a translated string (`%{formatted_number} topics` with `count` for the plural form) | the raw number |
| Dates | `discourse/lib/formatter` (`shortDateNoYear`, `longDate`, …) — they follow the user's locale | `Intl` with the browser locale |
| Current category | the `discovery` service (`this.discovery.category`), which updates on navigation | parsing router params once on insert |
| Tags | `site.top_tags` for popular tags; link to `/tag/{slug}/{id}` | fetching all of `/tags.json`; `/tag/{name}` |
| Values in URLs | `encodeURIComponent` for tags and other free text; `getURL` for site paths | string concatenation |

## Rendering Blocks

Import block classes and pass them to `api.renderBlocks()` in an `apiInitializer`. Always use `apiInitializer` (not `apiPreInitializer`) for `renderBlocks` calls.

**Initializers are layout files, and settings stay visible in them.** One `api.renderBlocks()` call with a declarative list of entries — `block`, `id`, `args`, `conditions`, `children`. The layout is where theme settings meet blocks: read `settings` here and pass the values as args (counts, tags, categories, URLs), next to the display-string i18n keys. Someone reading the layout file then sees the whole configuration — which block shows where, with what — without opening every block. Blocks get everything through args and never read `settings` themselves.

Keep shaping light and inline (`settings.banner_categories.split("|").filter(Boolean).map(Number)`). When settings hold one entry per scope (e.g. per category), map each entry to a layout entry in place so the ordering stays visible; small helpers for repeated condition shapes can live in `lib/`.

```javascript
import BlockGroup from "discourse/blocks/builtin/block-group";
import { apiInitializer } from "discourse/lib/api";
import BlockFeaturedList from "../blocks/block-featured-list";
import BlockLeaderboard from "../blocks/block-leaderboard";
import BlockPromo from "../blocks/block-promo";

export default apiInitializer((api) => {
  api.renderBlocks("homepage-blocks", [
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
      id: "main-right",
      children: [
        { block: BlockPromo, args: { title: "homepage.promo.title" } },
        {
          block: BlockLeaderboard,
          id: "homepage-leaderboard",
          args: {
            title: "homepage.leaderboard.title",
            count: settings.leaderboard_count,
          },
          conditions: {
            type: "setting",
            name: "discourse_gamification_enabled",
            enabled: true,
          },
        },
      ],
    },
  ]);
});
```

### Layout Entry Fields

| Field           | Description                                                                                                          |
| --------------- | -------------------------------------------------------------------------------------------------------------------- |
| `block`         | The block class (required)                                                                                           |
| `id`            | Stable identifier — renders as a BEM modifier on the block wrapper (`__block--{id}`) or container wrapper (`__block-container--{id}`) |
| `args`          | Arguments passed to the block component                                                                              |
| `conditions`    | Single condition object OR array of conditions                                                                       |
| `children`      | Child entries for container blocks                                                                                   |
| `containerArgs` | Args passed by a parent container to a child                                                                         |

### Available Outlets

These core outlets are always available:

- `hero-blocks`
- `homepage-blocks`
- `main-outlet-blocks`
- `sidebar-blocks`
- `sidebar-discovery`

Plugins can register additional outlets via `api.registerBlockOutlet()`. Themes cannot register new outlets — they can only render into existing ones.

`api.renderBlocks()` raises a `BlockError` for unknown outlets. If a theme targets an outlet that only exists on some core versions (e.g. one added by an in-progress core branch), guard the call:

```javascript
import { BLOCK_OUTLETS } from "discourse/lib/registry/block-outlets";

if (!BLOCK_OUTLETS.includes("sidebar-right")) {
  return;
}
```

### Styling Outlet Layouts

Each outlet renders a BEM structure using the outlet name as the block:

- `.homepage-blocks` — the outlet wrapper
- `.homepage-blocks__layout` — the layout container for all blocks
- `.homepage-blocks__block--{id}` — wrapper for individual blocks (modifier from `id`)
- `.homepage-blocks__block-container--{id}` — wrapper for container blocks like BlockGroup (modifier from `id`)

Use these BEM elements and modifiers to style the layout. Make the outlet wrapper a size container and switch columns with the core `lib/container` mixins (library breakpoints only), so the layout follows the space it gets — an open sidebar counts — rather than the viewport:

```scss
.homepage-blocks {
  container-type: inline-size;
  container-name: homepage-blocks;

  &__layout {
    display: grid;
    gap: var(--space-3);
    grid-template-columns: 1fr;
    grid-template-areas: "featured-list" "main-right";
  }

  @include container.from(md, homepage-blocks) {
    // two columns only while the right column renders something
    &__layout:has(.homepage-blocks__block-container--main-right .block-panel) {
      grid-template-areas: "featured-list main-right";
      grid-template-columns: 2fr 1fr;
    }
  }

  &__block--featured-list {
    grid-area: featured-list;
  }

  &__block-container--main-right {
    grid-area: main-right;
    display: flex;
    flex-direction: column;
    gap: var(--space-4);

    // core keeps a wrapper per block even when the block renders nothing,
    // so `:empty` never matches; test for content instead
    &:not(:has(.block-panel)),
    .homepage-blocks__block:not(:has(.block-panel)) {
      display: none;
    }
  }
}
```

Give an entry an `id` when you style it — it becomes the `--{id}` modifier. The `id` is optional otherwise: a group that only carries conditions doesn't need one.

## Translations & Theme Settings

### Translations

Theme locale files (`locales/en.yml`) register keys under the theme's i18n namespace. In block templates, wrap the arg with `themePrefix` so the key resolves correctly:

```yaml
# locales/en.yml
en:
  homepage:
    banner:
      title: "Welcome"
      link_text: "Learn more"
```

```javascript
// In template:
{{i18n (themePrefix @sectionTitle)}}
{{i18n (themePrefix @linkText)}}
```

```javascript
// In the initializer — hardcode the i18n key as the arg value:
{
  block: BlockBanner,
  args: {
    sectionTitle: "homepage.banner.title",
    linkText: "homepage.banner.link_text",
  },
}
```

**Key rule:** Display strings (titles, labels) are hardcoded i18n keys in the initializer and resolved via `themePrefix` in the template. Functional values (URLs, counts, tags, filters) come from theme settings, read in the initializer and passed as args. Do NOT put display strings in the settings schema.

Strings hardcoded directly in the template (not passed as args) also use `themePrefix`:

```javascript
{{i18n (themePrefix "homepage.featured_categories.topic_count") count=category.topic_count}}
```

### Theme Settings

Theme settings are available via the global `settings` object in the initializer. Pick the simplest type that fits each need — an `integer`, an `enum`, a `list` with `list_type: tag` or `category` — named `<block>_<thing>` (`leaderboard_count`, `featured_topics_tag`). List blocks get a `_count` setting. Use an `objects` setting only for genuinely repeating structured entries, such as one entry per category scope.

```javascript
{
  block: BlockFeaturedTopics,
  id: "featured-topics",
  args: {
    title: "homepage.featured_topics.title",
    tag: settings.featured_topics_tag,
    count: settings.featured_topics_count,
  },
}
```

A block that needs configuration to work (a tag, a category) renders nothing when unconfigured — guard the template — or the layout gates it with a setting condition (see Setting Condition).

## Conditions

`conditions` can be a **single object** or an **array** (AND logic):

```javascript
// Single condition (shorthand)
conditions: { type: "route", pages: ["HOMEPAGE"] }

// Multiple conditions (AND — all must pass)
conditions: [
  { type: "route", pages: ["CATEGORY_PAGES"] },
  { not: { type: "route", pages: ["HOMEPAGE"] } },
]
```

### Boolean Logic

```javascript
// OR — use { any: [...] }
{ any: [
  { type: "user", admin: true },
  { type: "user", moderator: true },
]}

// NOT — use { not: {...} }
{ not: { type: "route", pages: ["CATEGORY_PAGES"] } }

// Combined (AND + NOT)
conditions: [
  { type: "route", pages: ["TAG_PAGES"] },
  { not: { type: "route", pages: ["CATEGORY_PAGES"] } },
]
```

### Route Condition

Match by semantic page type, URL pattern, route params, or query params.

**Page types** match semantic contexts without requiring knowledge of URL structure:

| Page Type         | Description                                                 | Available Params                                          |
| ----------------- | ----------------------------------------------------------- | --------------------------------------------------------- |
| `HOMEPAGE`        | Custom homepage only                                        | (none)                                                    |
| `CATEGORY_PAGES`  | Category listing pages                                      | `categoryId`, `categorySlug`, `parentCategoryId`          |
| `TAG_PAGES`       | Tag listing pages                                           | `tagId`, `categoryId`, `categorySlug`, `parentCategoryId` |
| `DISCOVERY_PAGES` | Discovery routes (latest, top, etc.) excluding homepage     | `filter`                                                  |
| `TOP_MENU`        | Top nav discovery routes (excludes category, tag, homepage) | `filter`                                                  |
| `TOPIC_PAGES`     | Individual topic pages                                      | `id`, `slug`                                              |
| `USER_PAGES`      | User profile pages                                          | `username`                                                |
| `ADMIN_PAGES`     | Admin section pages                                         | (none)                                                    |
| `GROUP_PAGES`     | Group pages                                                 | `name`                                                    |

```javascript
// Match homepage
{ type: "route", pages: ["HOMEPAGE"] }

// Match multiple page types (OR logic)
{ type: "route", pages: ["CATEGORY_PAGES", "TAG_PAGES"] }

// Match specific category by ID
{ type: "route", pages: ["CATEGORY_PAGES"], params: { categoryId: 5 } }

// Match specific category by slug
{ type: "route", pages: ["CATEGORY_PAGES"], params: { categorySlug: "support" } }

// URL glob patterns (picomatch syntax: *, **, ?, [abc], {a,b})
{ type: "route", urls: ["/c/general/**", "/c/ideas/**"] }

// Combined pages + urls (either must match)
{ type: "route", pages: ["TOP_MENU"], urls: ["/tags"] }

// With query params (route AND query must both match)
{ type: "route", urls: ["/latest"], queryParams: { filter: "solved" } }

// Params support any/not operators
{ type: "route", pages: ["CATEGORY_PAGES"], params: {
  any: [{ categorySlug: "support" }, { categorySlug: "help" }]
}}
```

URL matching automatically handles Discourse subfolder installations — patterns like `/c/**` work regardless of whether Discourse runs on `/forum` or root.

### User Condition

Match by user state. All specified conditions use AND logic. When `source` is provided, checks a user object from outlet args instead of the current user.

```javascript
// Logged-in users only
{ type: "user", loggedIn: true }

// Anonymous users only
{ type: "user", loggedIn: false }

// Admin users
{ type: "user", admin: true }

// Moderators (includes admins)
{ type: "user", moderator: true }

// Staff (admin or moderator)
{ type: "user", staff: true }

// Trust level range
{ type: "user", minTrustLevel: 2 }
{ type: "user", minTrustLevel: 1, maxTrustLevel: 3 }

// Group membership (OR logic — user must be in at least one)
{ type: "user", groups: ["beta-testers", "power-users"] }

// Combined (AND): trust level 2+ AND in group
{ type: "user", minTrustLevel: 2, groups: ["beta-testers"] }

// Check a user from outlet args
{ type: "user", source: "@outletArgs.topicAuthor", admin: true }

// Check if source user IS the current user
{ type: "user", source: "@outletArgs.post.user", loggedIn: true }
```

### Setting Condition

Match by site setting or theme setting values. An unknown setting name evaluates to `false` without an error, so a renamed plugin setting silently hides the block — check the current name in the plugin's `config/settings.yml` (e.g. the events plugin uses `discourse_events_enabled`, gamification `discourse_gamification_enabled`). Supports multiple check types:

| Check         | Setting Type          | Question                                   |
| ------------- | --------------------- | ------------------------------------------ |
| `enabled`     | Boolean               | Is the setting truthy/falsy?               |
| `equals`      | Any                   | Does the setting exactly equal this value? |
| `includes`    | Single value (enum)   | Is the setting value IN my list?           |
| `contains`    | List (pipe-separated) | Does the setting list CONTAIN my value?    |
| `containsAny` | List (pipe-separated) | Does the list contain ANY of my values?    |

```javascript
// Boolean setting
{ type: "setting", name: "enable_badges", enabled: true }

// Exact match
{ type: "setting", name: "desktop_category_page_style", equals: "categories_and_latest_topics" }

// Setting is one of several values
{ type: "setting", name: "desktop_category_page_style",
  includes: ["categories_and_latest_topics", "categories_and_top_topics"] }

// List setting contains value
{ type: "setting", name: "top_menu", contains: "hot" }

// List setting contains any of values
{ type: "setting", name: "share_links", containsAny: ["twitter", "facebook"] }

// Theme setting (pass settings object as source)
{ type: "setting", source: settings, name: "show_sidebar", enabled: true }

// `source` accepts ANY object — e.g. one entry of an objects-type setting,
// letting conditions match nested per-block configuration
const topicList = settings.topic_lists[0] ?? {};
{ type: "setting", source: topicList, name: "list", equals: "top" }
```

### Viewport Condition

Match by screen size using breakpoints (`sm`, `md`, `lg`, `xl`, `2xl`) and touch capability. For layout and show/hide, prefer CSS container queries on the outlet (see Styling Outlet Layouts) — the viewport ignores an open sidebar. Use this condition only when a block must not be in the DOM at all.

```javascript
// Large screens only (lg and up)
{ type: "viewport", min: "lg" }

// Small screens only (below sm)
{ type: "viewport", max: "sm" }

// Medium to large screens
{ type: "viewport", min: "md", max: "xl" }

// Touch devices only
{ type: "viewport", touch: true }

// Non-touch large screens
{ type: "viewport", min: "lg", touch: false }
```

At least one of `min`, `max`, or `touch` must be specified.

### Outlet Arg Condition

Match on args passed via `@outletArgs` using dot-notation paths:

```javascript
{ type: "outlet-arg", path: "post.staff", value: true }

// An array value matches any of its elements
{ type: "outlet-arg", path: "category.id", value: [5, 6] }
```

## Container Blocks

Container blocks render children. Two built-in containers are available:

### BlockGroup — Render All Children

Use `BlockGroup` for simple grouping. It renders all children whose conditions pass:

```javascript
import BlockGroup from "discourse/blocks/builtin/block-group";

{
  block: BlockGroup,
  id: "main-right",
  children: [
    { block: BlockPromo, args: { title: "Promo" } },
    { block: BlockLeaderboard, args: { count: 5 } },
  ],
}
```

Groups can be nested — `BlockGroup` inside `BlockGroup` is a common layout pattern.

### BlockHead — Render First Matching Child

Use `BlockHead` for if/else fallback logic. It renders only the first child whose conditions pass:

```javascript
import BlockHead from "discourse/blocks/builtin/block-head";

{
  block: BlockHead,
  children: [
    // Show support panel for support category
    {
      block: InfoPanel,
      args: { variant: "support" },
      conditions: { type: "route", pages: ["CATEGORY_PAGES"], params: { categorySlug: "support" } },
    },
    // Show dev panel for dev category
    {
      block: InfoPanel,
      args: { variant: "dev" },
      conditions: { type: "route", pages: ["CATEGORY_PAGES"], params: { categorySlug: "dev" } },
    },
    // Default fallback (no conditions = always matches)
    { block: InfoPanel, args: { variant: "default" } },
  ],
}
```

### Custom Containers

For custom containers, use `container: true` and render `@children`:

```javascript
@block("theme:my-theme:card-grid", {
  container: true,
  childArgs: {
    featured: { type: "boolean", default: false },
  },
})
export default class CardGrid extends Component {
  <template>
    <div class="card-grid">
      {{#each @children key="key" as |child|}}
        <div class="card-grid__item {{if child.containerArgs.featured "--featured"}}">
          <child.Component />
        </div>
      {{/each}}
    </div>
  </template>
}
```

## Testing

Use the test helpers from `discourse/tests/helpers/block-testing`:

```javascript
import {
  registerBlock,
  resetBlockRegistryForTesting,
} from "discourse/tests/helpers/block-testing";

module("My block tests", function (hooks) {
  hooks.beforeEach(() => registerBlock(MyBlock));
  hooks.afterEach(() => resetBlockRegistryForTesting());
});
```

## Common Mistakes

| Mistake                                            | Fix                                                                                                                                                    |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Calling `renderBlocks` in a pre-initializer        | Move to a plain `apiInitializer`                                                                                                                       |
| Using `<MyBlock />` directly in a template         | Only `<BlockOutlet>` can render blocks                                                                                                                 |
| Forgetting namespace in block name                 | Theme blocks must be `theme:theme-name:block-name`                                                                                                     |
| Trying to register a custom outlet from a theme    | Themes cannot register outlets — only plugins can (requires pre-initializer phase)                                                                     |
| Conditions array with OR logic using a plain array | Use `{ any: [...] }` for OR; plain array is always AND                                                                                                 |
| Multiple blocks of same type without `id`          | Add `id` to each entry for stable DOM identity                                                                                                         |
| Using `sizes` in viewport condition                | Use `min`/`max` breakpoints: `{ type: "viewport", min: "lg" }`                                                                                         |
| Using `oneOf` in an args schema                    | Use `enum` (string/number args) or `itemEnum` (array items) — `oneOf` is not a valid schema property                                                   |
| Two themes/components rendering into the same outlet | An outlet accepts exactly ONE layout globally, not one per theme ("already has a layout registered"). Consolidate into one theme, or uninstall the other |
| Gating an entry with a missing required arg via conditions | Required args are validated at `renderBlocks()` time, BEFORE conditions are evaluated — make the arg optional and let the block render nothing when unconfigured |
| Reading `settings` inside a block                  | Read settings in the initializer and pass them as args, so the layout shows the whole configuration                                                    |
| A setting condition on a renamed or unknown setting | Unknown names evaluate to `false` silently — verify the name in the plugin's `config/settings.yml`                                                    |
| `name` in an outlet-arg condition                  | The key is `path`: `{ type: "outlet-arg", path: "category.id", value: 5 }`                                                                             |
| `:empty` on a block container                      | Core keeps a wrapper per block even when it renders nothing — use `:not(:has(.block-panel))`                                                           |
| Viewport queries or viewport conditions for outlet layouts | Make the outlet a size container and use `container.from/until` with library breakpoints                                                       |
| A spinner as the loading state                     | Render a skeleton shaped like the content, inside the panel body                                                                                       |
| Importing UI components from legacy paths           | Prefer `discourse/ui-kit/*` (e.g. `discourse/ui-kit/d-button`, `d-async-content`, `d-user-link`, `helpers/d-avatar`, `helpers/d-icon`, `helpers/d-number`) — the old `discourse/components/*` and `discourse/helpers/*` paths are compatibility shims (see core `ui-kit-shims.js` for the full map) |
| Using `trust_level` in user condition              | Use `minTrustLevel`/`maxTrustLevel` (camelCase, separate min/max)                                                                                      |
| Using `enabled` alone in setting condition         | Always include `name`: `{ type: "setting", name: "...", enabled: true }`                                                                               |
| Multiple outlets in one initializer file           | Never call `renderBlocks()` for different outlets in the same file. One file = one outlet. Create separate initializer files named after their outlet. |
