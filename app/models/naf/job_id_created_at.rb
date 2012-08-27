module Naf
  class JobIdCreatedAt < ::Partitioned::ByCreatedAt
    def self.connection
      return NafBase.connection
    end
  end
end
