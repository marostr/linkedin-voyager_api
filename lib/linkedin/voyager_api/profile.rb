# frozen_string_literal: true

require "json"

module LinkedIn
  module VoyagerApi
    module Profile
      STANDARD_WEBSITE_TYPE = "com.linkedin.voyager.identity.profile.StandardWebsite"
      CUSTOM_WEBSITE_TYPE = "com.linkedin.voyager.identity.profile.CustomWebsite"
      VECTOR_IMAGE_TYPE = "com.linkedin.common.VectorImage"

      def get_profile(public_id: nil, urn_id: nil)
        identifier = require_identifier(public_id, urn_id)
        data = get("/identity/profiles/#{identifier}/profileView")
        profile = Profile.parse_profile(data)
        return profile unless profile

        profile["skills"] = get_profile_skills(public_id: public_id, urn_id: urn_id)
        profile
      end

      def get_profile_contact_info(public_id: nil, urn_id: nil)
        identifier = require_identifier(public_id, urn_id)
        data = get("/identity/profiles/#{identifier}/profileContactInfo")
        Profile.parse_contact_info(data)
      end

      def get_profile_skills(public_id: nil, urn_id: nil)
        identifier = require_identifier(public_id, urn_id)
        data = get("/identity/profiles/#{identifier}/skills", params: {count: 100, start: 0})
        Profile.parse_skills(data)
      end

      module_function

      def parse_profile(data)
        return nil if data && data["status"] && data["status"] != 200

        data = deep_dup(data)
        profile = data["profile"]

        if profile["miniProfile"]
          mini = profile["miniProfile"]
          if mini["picture"] && mini["picture"][VECTOR_IMAGE_TYPE]
            profile["displayPictureUrl"] = mini["picture"][VECTOR_IMAGE_TYPE]["rootUrl"]
          end
          profile["profile_id"] = Utils.id_from_urn(mini["entityUrn"])
          profile.delete("miniProfile")
        end

        profile.delete("defaultLocale")
        profile.delete("supportedLocales")
        profile.delete("versionTag")
        profile.delete("showEducationOnProfileTopCard")

        profile["experience"] = parse_experience(data["positionView"]["elements"])
        profile["education"] = parse_education(data["educationView"]["elements"])

        profile
      end

      def parse_contact_info(data)
        websites = data.fetch("websites", []).map(&:dup)
        websites.each do |item|
          if item["type"].key?(STANDARD_WEBSITE_TYPE)
            item["label"] = item["type"][STANDARD_WEBSITE_TYPE]["category"]
          elsif item["type"].key?(CUSTOM_WEBSITE_TYPE)
            item["label"] = item["type"][CUSTOM_WEBSITE_TYPE]["label"]
          end
          item.delete("type")
        end

        {
          "email_address" => data["emailAddress"],
          "websites" => websites,
          "twitter" => data["twitterHandles"],
          "birthdate" => data["birthDateOn"],
          "ims" => data["ims"],
          "phone_numbers" => data.fetch("phoneNumbers", []),
        }
      end

      def parse_skills(data)
        data.fetch("elements", []).map { |item| item.reject { |k, _| k == "entityUrn" } }
      end

      def parse_experience(elements)
        elements.each do |item|
          next unless item["company"] && item["company"]["miniCompany"]

          mini = item["company"]["miniCompany"]
          if mini["logo"]
            logo = mini["logo"][VECTOR_IMAGE_TYPE]
            item["companyLogoUrl"] = logo["rootUrl"] if logo
          end
          item["company"].delete("miniCompany")
        end
        elements
      end

      def parse_education(elements)
        elements.each do |item|
          next unless item["school"] && item["school"]["logo"]

          logo = item["school"]["logo"][VECTOR_IMAGE_TYPE]
          item["school"]["logoUrl"] = logo["rootUrl"] if logo
          item["school"].delete("logo")
        end
        elements
      end

      def deep_dup(obj)
        JSON.parse(JSON.generate(obj))
      end

      private_class_method :parse_experience, :parse_education, :deep_dup
    end
  end
end
