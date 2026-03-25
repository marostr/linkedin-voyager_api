# frozen_string_literal: true

require "test_helper"

module LinkedIn
  module VoyagerApi
    class ProfileParsingTest < Minitest::Test
      include FixtureHelper

      def setup
        @data = load_fixture("profile_view.json")
      end

      def test_parse_profile_extracts_basic_fields
        profile = Profile.parse_profile(@data)

        assert_equal "Tom", profile["firstName"]
        assert_equal "Quirk", profile["lastName"]
        assert_equal "Software engineer", profile["summary"]
      end

      def test_parse_profile_extracts_display_picture_url
        profile = Profile.parse_profile(@data)

        assert_equal "https://media.licdn.com/dms/image/photo.jpg", profile["displayPictureUrl"]
      end

      def test_parse_profile_extracts_profile_id_from_urn
        profile = Profile.parse_profile(@data)

        assert_equal "ACoAAAKT9JQ", profile["profile_id"]
      end

      def test_parse_profile_removes_mini_profile
        profile = Profile.parse_profile(@data)

        refute profile.key?("miniProfile")
      end

      def test_parse_profile_removes_metadata_keys
        profile = Profile.parse_profile(@data)

        refute profile.key?("defaultLocale")
        refute profile.key?("supportedLocales")
        refute profile.key?("versionTag")
        refute profile.key?("showEducationOnProfileTopCard")
      end

      def test_parse_profile_restructures_experience
        profile = Profile.parse_profile(@data)
        experience = profile["experience"]

        assert_equal 2, experience.length
        assert_equal "Senior Engineer", experience[0]["title"]
        assert_equal "https://media.licdn.com/dms/image/acme-logo.jpg", experience[0]["companyLogoUrl"]
        refute experience[0]["company"].key?("miniCompany")
      end

      def test_parse_profile_handles_experience_without_company
        profile = Profile.parse_profile(@data)
        experience = profile["experience"]

        assert_equal "Junior Engineer", experience[1]["title"]
        refute experience[1].key?("companyLogoUrl")
      end

      def test_parse_profile_restructures_education
        profile = Profile.parse_profile(@data)
        education = profile["education"]

        assert_equal 1, education.length
        assert_equal "https://media.licdn.com/dms/image/uq-logo.jpg", education[0]["school"]["logoUrl"]
        refute education[0]["school"].key?("logo")
      end

      def test_parse_profile_returns_nil_for_failed_response
        data = load_fixture("profile_view_failed.json")
        profile = Profile.parse_profile(data)

        assert_nil profile
      end

      def test_parse_profile_handles_missing_picture
        @data["profile"]["miniProfile"].delete("picture")
        profile = Profile.parse_profile(@data)

        refute profile.key?("displayPictureUrl")
        assert_equal "ACoAAAKT9JQ", profile["profile_id"]
      end
    end

    class ProfileContactInfoParsingTest < Minitest::Test
      include FixtureHelper

      def setup
        @data = load_fixture("profile_contact_info.json")
      end

      def test_parse_contact_info_extracts_email
        info = Profile.parse_contact_info(@data)

        assert_equal "tom@example.com", info["email_address"]
      end

      def test_parse_contact_info_extracts_twitter
        info = Profile.parse_contact_info(@data)

        assert_equal ["@tomquirk"], info["twitter"]
      end

      def test_parse_contact_info_extracts_phone_numbers
        info = Profile.parse_contact_info(@data)

        assert_equal 1, info["phone_numbers"].length
        assert_equal "+61412345678", info["phone_numbers"][0]["number"]
      end

      def test_parse_contact_info_labels_standard_websites
        info = Profile.parse_contact_info(@data)
        websites = info["websites"]

        assert_equal "PERSONAL", websites[0]["label"]
        assert_equal "https://tomquirk.com", websites[0]["url"]
        refute websites[0].key?("type")
      end

      def test_parse_contact_info_labels_custom_websites
        info = Profile.parse_contact_info(@data)
        websites = info["websites"]

        assert_equal "My Blog", websites[1]["label"]
        assert_equal "https://myblog.com", websites[1]["url"]
        refute websites[1].key?("type")
      end
    end

    class ProfileSkillsParsingTest < Minitest::Test
      include FixtureHelper

      def test_parse_skills_removes_entity_urn
        data = load_fixture("profile_skills.json")
        skills = Profile.parse_skills(data)

        assert_equal 3, skills.length
        assert_equal "Ruby", skills[0]["name"]
        skills.each { |s| refute s.key?("entityUrn") }
      end
    end
  end
end
