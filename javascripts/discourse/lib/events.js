import { ajax } from "discourse/lib/ajax";
import getURL from "discourse/lib/get-url";

// The server orders by each event's stored date, which for a recurring event
// can lie before its next occurrence, so fetch a margin and sort here.
function requestLimit(count) {
  return Math.min(Math.max(count * 5, 15), 100);
}

// All-day dates come as a bare "YYYY-MM-DD"; parsed as is they would be
// midnight UTC, a day early west of UTC. Parse them as local days instead.
function parse(value) {
  if (!value) {
    return null;
  }
  const allDay = /^\d{4}-\d{2}-\d{2}$/.test(value);
  const date = new Date(allDay ? `${value}T00:00:00` : value);
  return Number.isNaN(date.getTime()) ? null : { date, allDay };
}

// An all-day event lasts until the end of its last day, a timed one until
// its end time, or its start time when it has none.
function endOf(start, end) {
  const last = end ?? start;
  if (start.allDay) {
    const date = new Date(last.date);
    date.setHours(23, 59, 59, 999);
    return date.getTime();
  }
  return last.date.getTime();
}

function occurrences(event) {
  const rows = event.occurrences?.length ? event.occurrences : [event];
  return rows
    .map((row) => {
      const start = parse(row.starts_at);
      return start
        ? {
            iso: row.starts_at,
            start,
            ms: start.date.getTime(),
            endMs: endOf(start, parse(row.ends_at)),
          }
        : null;
    })
    .filter(Boolean);
}

function serialize([event, occurrence]) {
  return {
    id: event.id,
    title: event.name?.trim() || event.post?.topic?.title || "",
    iso: occurrence.iso,
    date: occurrence.start.date,
    allDay: occurrence.start.allDay,
    url: event.post?.url ? getURL(event.post.url) : null,
  };
}

async function search({ categoryId, count, ...range }) {
  const result = await ajax("/discourse-post-event/events.json", {
    data: {
      category_id: categoryId,
      include_subcategories: true,
      include_details: true,
      limit: requestLimit(count),
      ...range,
    },
  });
  return result?.events ?? [];
}

function pick(events, choose, compare, count) {
  return events
    .map((event) => [event, choose(occurrences(event))])
    .filter(([, occurrence]) => occurrence)
    .sort(([, a], [, b]) => compare(a, b))
    .slice(0, count)
    .map(serialize);
}

// Post events of the whole site, or of a category and its subcategories
// when one is given. The next `count` events that are not over yet; when
// there are none, the `count` most recent past events instead, flagged with
// `recent`. Null when there are no events at all, so the panel hides itself.
export async function fetchEvents({ categoryId, count }) {
  const now = Date.now();

  // The server stores an all-day event as midnight UTC of its date, so with
  // "now" as the cutoff today's all-day events would already count as past.
  // Two days back covers every timezone; the filter below decides what is
  // still running.
  const upcoming = pick(
    await search({
      categoryId,
      count,
      after: new Date(now - 2 * 24 * 60 * 60 * 1000).toISOString(),
      include_ongoing: true,
      order: "asc",
    }),
    (rows) =>
      rows.filter((row) => row.endMs >= now).sort((a, b) => a.ms - b.ms)[0],
    (a, b) => a.ms - b.ms,
    count
  );

  if (upcoming.length) {
    return { events: upcoming, recent: false };
  }

  const recent = pick(
    await search({ categoryId, count, before: "now", order: "desc" }),
    (rows) =>
      rows.filter((row) => row.endMs < now).sort((a, b) => b.ms - a.ms)[0],
    (a, b) => b.ms - a.ms,
    count
  );

  return recent.length ? { events: recent, recent: true } : null;
}
