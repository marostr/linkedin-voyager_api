# frozen_string_literal: true

module LinkedIn
  module VoyagerApi
    module Profile
      STANDARD_WEBSITE_TYPE = "com.linkedin.voyager.identity.profile.StandardWebsite"
      CUSTOM_WEBSITE_TYPE = "com.linkedin.voyager.identity.profile.CustomWebsite"
      VECTOR_IMAGE_TYPE = "com.linkedin.common.VectorImage"

      def get_profile(public_id: nil, urn_id: nil)
        data = get("/identity/profiles/#{public_id || urn_id}/profileView")
        profile = self.class.module_eval { Profile }.parse_profile(data)
        return profile unless profile

        profile["skills"] = get_profile_skills(public_id: public_id, urn_id: urn_id)
        profile
      end

      def get_profile_contact_info(public_id: nil, urn_id: nil)
        data = get("/identity/profiles/#{public_id || urn_id}/profileContactInfo")
        Profile.parse_contact_info(data)
      end

      def get_profile_skills(public_id: nil, urn_id: nil)
        data = get("/identity/profiles/#{public_id || urn_id}/skills", params: {count: 100, start: 0})
        Profile.parse_skills(data)
      end

      def get_user_profile
        get("/me")
      end

      module_function

      def parse_profile(data)
        return nil if data && data["status"] && data["status"] != 200

        profile = data["profile"].dup

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
        contact_info = {
          "email_address" => data["emailAddress"],
          "websites" => [],
          "twitter" => data["twitterHandles"],
          "birthdate" => data["birthDateOn"],
          "ims" => data["ims"],
          "phone_numbers" => data.fetch("phoneNumbers", []),
        }

        websites = data.fetch("websites", [])
        websites.each do |item|
          if item["type"].key?(STANDARD_WEBSITE_TYPE)
            item["label"] = item["type"][STANDARD_WEBSITE_TYPE]["category"]
          elsif item["type"].key?(CUSTOM_WEBSITE_TYPE)
            item["label"] = item["type"][CUSTOM_WEBSITE_TYPE]["label"]
          end
          item.delete("type")
        end

        contact_info["websites"] = websites
        contact_info
      end

      def parse_skills(data)
        skills = data.fetch("elements", [])
        skills.each { |item| item.delete("entityUrn") }
        skills
      end

      private

      def self.parse_experience(elements)
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

      def self.parse_education(elements)
        elements.each do |item|
          next unless item["school"] && item["school"]["logo"]

          item["school"]["logoUrl"] = item["school"]["logo"][VECTOR_IMAGE_TYPE]["rootUrl"]
          item["school"].delete("logo")
        end
        elements
      end
    end
  end
end
