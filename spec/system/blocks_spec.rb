# frozen_string_literal: true

RSpec.describe "Skills theme blocks" do
  let!(:theme) { upload_theme_or_component }

  fab!(:admin)
  fab!(:user)
  fab!(:category) { Fabricate(:category, name: "Product", description: "All about the product") }
  fab!(:other_category) { Fabricate(:category, name: "Off topic") }
  fab!(:topic) { Fabricate(:topic_with_op, title: "A topic for the homepage list", category:) }

  def update_setting(name, value)
    theme.update_setting(name, value)
    theme.save!
  end

  def create_event(title, all_day: false, starts_at: 3.days.from_now)
    event_topic = Fabricate(:topic_with_op, title:)
    Fabricate(
      :event,
      post: event_topic.first_post,
      all_day:,
      original_starts_at: all_day ? Time.now.utc.midnight : starts_at,
    )
  end

  before { sign_in(user) }

  describe "homepage" do
    it "renders the hero, the featured list and the call to action" do
      visit("/")

      expect(page).to have_css(".block-hero__title", text: "Build something great together")
      expect(page).to have_css(".block-featured-list .topic-list", text: topic.title)
      expect(page).to have_css(".block-cta__title", text: "Ready to join the conversation?")
    end

    it "shows featured topics for the configured tag" do
      SiteSetting.tagging_enabled = true
      tag = Fabricate(:tag, name: "featured")
      Fabricate(:topic_with_op, title: "A featured topic with a tag", tags: [tag])
      update_setting(:featured_topics_tag, "featured")

      visit("/")

      expect(page).to have_css(".block-featured-topics__card", text: "A featured topic with a tag")
    end
  end

  describe "upcoming events" do
    before do
      SiteSetting.discourse_events_enabled = true
      SiteSetting.discourse_post_event_enabled = true
    end

    it "lists upcoming events, including an all-day event of today" do
      create_event("A meetup later this week")
      create_event("An all-day workshop today", all_day: true)

      visit("/")

      within(".block-upcoming-events") do
        expect(page).to have_css(".block-panel__title", text: "Upcoming events")
        expect(page).to have_css(
          ".block-upcoming-events__event-title",
          text: "A meetup later this week",
        )
        expect(page).to have_css(
          ".block-upcoming-events__event-title",
          text: "An all-day workshop today",
        )
      end
    end

    it "falls back to recent events when none are upcoming" do
      create_event("A meetup last week", starts_at: 5.days.ago)

      visit("/")

      within(".block-upcoming-events") do
        expect(page).to have_css(".block-panel__title", text: "Recent events")
        expect(page).to have_css(".block-upcoming-events__event-title", text: "A meetup last week")
      end
    end

    it "is not rendered when the events plugin is disabled" do
      SiteSetting.discourse_events_enabled = false

      visit("/")

      expect(page).to have_css(".block-featured-list")
      expect(page).to have_no_css(".block-upcoming-events")
    end
  end

  describe "leaderboard" do
    fab!(:leaderboard) { Fabricate(:gamification_leaderboard, name: "Top helpers") }
    fab!(:scorer) { Fabricate(:user, username: "top_scorer") }

    before do
      SiteSetting.discourse_gamification_enabled = true
      Fabricate(
        :gamification_leaderboard_score,
        leaderboard_id: leaderboard.id,
        user_id: scorer.id,
        score: 25,
      )
      DiscourseGamification::LeaderboardCachedView.create_all
    end

    it "lists the top users" do
      visit("/")

      within(".block-leaderboard") do
        expect(page).to have_css(".block-panel__title", text: "Top contributors")
        expect(page).to have_css(".block-leaderboard__name", text: "top_scorer")
      end
    end
  end

  describe "category banner" do
    it "shows the current category and follows navigation" do
      SiteSetting.default_navigation_menu_categories = "#{category.id}|#{other_category.id}"
      sign_in(Fabricate(:user))

      visit(category.url)
      expect(page).to have_css(".block-category-banner__name", text: "Product")
      expect(page).to have_css(".block-category-banner__description", text: "All about the product")

      find(".sidebar-section-link", text: other_category.name).click

      expect(page).to have_css(".block-category-banner__name", text: "Off topic")
    end

    it "only shows on the configured categories" do
      update_setting(:banner_categories, category.id.to_s)

      visit(category.url)
      expect(page).to have_css(".block-category-banner__name", text: "Product")

      visit(other_category.url)
      expect(page).to have_css(".category-breadcrumb")
      expect(page).to have_no_css(".block-category-banner__name")
    end
  end
end
