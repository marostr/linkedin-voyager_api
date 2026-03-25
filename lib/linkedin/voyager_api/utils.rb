# frozen_string_literal: true

module LinkedIn
  module VoyagerApi
    module Utils
      module_function

      def id_from_urn(urn)
        urn.split(":")[3]
      end
    end
  end
end
