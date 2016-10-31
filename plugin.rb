# name: open-community
# about: Open Community plugin for Discourse
# version: 0.0.1
# authors: Vinoth Kannan (vinothkannan@vinkas.com)

OPEN_COMMUNITY = 'discourse_open_community'.freeze

SUPPRESS_CATEGORY_LISTING = 'suppress_category_listing'.freeze
OPEN_COMMUNITY_CATEGORIES = 'open_community_categories'.freeze

enabled_site_setting :open_community_enabled

register_asset 'stylesheets/open-community.scss'

after_initialize do

  module ::DiscourseOpenCommunity
    class Engine < ::Rails::Engine
      engine_name OPEN_COMMUNITY
      isolate_namespace DiscourseOpenCommunity
    end
  end

  class DiscourseOpenCommunity::Guardian

    @@allowed_open_community_categories_cache = DistributedCache.new(OPEN_COMMUNITY_CATEGORIES)

    def self.reset_open_community_categories_cache
      @@allowed_open_community_categories_cache["allowed"] =
        begin
          Set.new(
            CategoryCustomField
              .where(name: OPEN_COMMUNITY_CATEGORIES, value: "true")
              .pluck(:category_id)
          )
          Set.new(
            CategoryCustomField
              .where(name: SUPPRESS_CATEGORY_LISTING, value: "true")
              .pluck(:category_id)
          )
        end
    end

    def open_community_category?(category_id)
      self.class.reset_open_community_categories_cache unless @@allowed_open_community_categories_cache["allowed"]
      @@allowed_open_community_categories_cache["allowed"].include?(category_id)
    end

  end

  class ::Category
    after_save :reset_open_community_categories_cache

    protected
    def reset_open_community_categories_cache
      ::Guardian.reset_open_community_categories_cache
    end
  end

  add_to_serializer(:site, :open_community_category_ids) { CategoryCustomField.where(name: OPEN_COMMUNITY_CATEGORIES, value: "true").pluck(:category_id) }
  add_to_serializer(:site, :suppressed_category_listing_ids) { CategoryCustomField.where(name: SUPPRESS_CATEGORY_LISTING, value: "true").pluck(:category_id) }

end
