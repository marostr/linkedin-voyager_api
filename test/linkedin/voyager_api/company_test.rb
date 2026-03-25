# frozen_string_literal: true

require "test_helper"

module LinkedIn
  module VoyagerApi
    class CompanyParsingTest < Minitest::Test
      include FixtureHelper

      def test_parse_company_returns_first_element
        data = load_fixture("company.json")
        company = Company.parse_company(data)

        assert_equal "LinkedIn", company["name"]
        assert_equal "linkedin", company["universalName"]
        assert_equal 16000, company["staffCount"]
      end

      def test_parse_company_returns_nil_for_failed_response
        data = load_fixture("company_failed.json")
        company = Company.parse_company(data)

        assert_nil company
      end

      def test_decoration_id_matches_python_lib
        assert_equal(
          "com.linkedin.voyager.deco.organization.web.WebFullCompanyMain-12",
          Company::DECORATION_ID
        )
      end
    end
  end
end
