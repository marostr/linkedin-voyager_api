# frozen_string_literal: true

require "test_helper"

module LinkedIn
  module VoyagerApi
    class UtilsTest < Minitest::Test
      def test_id_from_urn_extracts_last_segment
        assert_equal "abc123", Utils.id_from_urn("urn:li:fs_miniProfile:abc123")
      end

      def test_id_from_urn_with_member_urn
        assert_equal "ACoAAAKT9JQ", Utils.id_from_urn("urn:li:member:ACoAAAKT9JQ")
      end

      def test_id_from_urn_with_numeric_id
        assert_equal "12345", Utils.id_from_urn("urn:li:company:12345")
      end
    end
  end
end
