require "test_helper"

class GuideExternalLinkTest < ActionDispatch::IntegrationTest
  test "an event links out with the origin site's mark and domain" do
    event = create_event(external_url: "https://www.facebook.com/events/1234567890")

    get event_path(event)
    assert_response :success

    assert_select %(a[href="#{event.external_url}"][target="_blank"][rel="noopener"]) do
      assert_select "svg", 2                          # brand mark + external-link arrow
      assert_match I18n.t("guide.official_link"), response.body
    end
    assert_match "facebook.com", response.body        # www. stripped
    assert_match "color: #1877F2", response.body      # the mark, not the fallback
  end

  test "an unknown domain still renders, with the neutral glyph" do
    event = create_event(external_url: "https://municipalidad.gov.py/agenda")

    get event_path(event)
    assert_response :success

    assert_select %(a[href="#{event.external_url}"]), 1
    assert_match "municipalidad.gov.py", response.body
    assert_no_match(/color: #1877F2/, response.body)
  end

  test "an event without an external link renders no outbound link" do
    event = create_event(external_url: nil)

    get event_path(event)
    assert_response :success
    assert_no_match(/#{I18n.t("guide.official_link")}/, response.body)
  end

  private
    def create_event(external_url:)
      GuideEntry.create!(kind: "event", title_es: "Carnaval Encarnaceno", published: true,
        starts_at: 1.week.from_now, external_url: external_url)
    end
end
