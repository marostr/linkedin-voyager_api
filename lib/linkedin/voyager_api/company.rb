# frozen_string_literal: true

module LinkedIn
  module VoyagerApi
    module Company
      DECORATION_ID = "com.linkedin.voyager.deco.organization.web.WebFullCompanyMain-12"

      def get_company(public_id)
        raise ArgumentError, "public_id is required" unless public_id

        data = get(
          "/organization/companies",
          params: {
            decorationId: DECORATION_ID,
            q: "universalName",
            universalName: public_id,
          }
        )
        Company.parse_company(data)
      end

      module_function

      def parse_company(data)
        return nil if data && data["status"] && data["status"] != 200

        data["elements"][0]
      end
    end
  end
end
