# name: community-hub
# about: Community Hub plugin for Discourse
# version: 0.0.1
# authors: Vinoth Kannan (vinothkannan@vinkas.com)
# url: https://codiss.com/c/discourse-community-hub

enabled_site_setting :community_hub_enabled

register_asset 'stylesheets/community-hub.scss'

PLUGIN_NAME ||= 'community_hub'.freeze
SETTING_NAME ||= "communities_category".freeze

after_initialize do

  module ::CommunityHub
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace CommunityHub
    end
  end

  class CommunityHub::Community
    class << self

      def add(user_id, name, description)

        # TODO add i18n string
        raise StandardError.new "communities.missing_name" if name.blank?
        raise StandardError.new "communities.missing_description" if description.blank?

        id = SecureRandom.hex(16)
        record = {id: id, name: name, description: description}

        communities = PluginStore.get(PLUGIN_NAME, STORE_NAME)
        communities = Hash.new if replies == nil

        communities[id] = record
        PluginStore.set(PLUGIN_NAME, STORE_NAME, communities)

        record
      end

      def all(user_id)
        communities = PluginStore.get(PLUGIN_NAME, STORE_NAME)

        return {} if communities.blank?

        communities.each do |id, value|
          value['cooked'] = PrettyText.cook(value['description'])
          value['usages'] = 0 unless value.key?('usages')
          communities[id] = value
        end
        #sort by usages
        communities =  communities.sort_by {|key, value| value['usages']}.reverse.to_h
      end

    end
  end

  CommunityHub::Engine.routes.draw do
    post "/" => "communities#create"
  end

  Discourse::Application.routes.append do
    mount ::CommunityHub::Engine, at: "/communities"
  end

  require_dependency 'application_controller'

  class CommunityHub::CommunitiesController < ::PostsController
    requires_plugin PLUGIN_NAME
    before_filter :ensure_logged_in, only: [:create]

    def create
      @params = create_params

      category = @params[:category] || ""
      guardian.ensure_community_hub_category!(category.to_i)

      @params[:raw] = ''
      @params[:skip_validations] = true
      @params[:post_type] ||= Post.types[:regular]
      @params[:first_post_checks] = true
      @params[:invalidate_oneboxes] = true

      manager = NewPostManager.new(current_user, @params)
      result = manager.perform

      if result.success?
        # result.post.topic.custom_fields = {  }
        # result.post.topic.save!
      end
      json = serialize_data(result, NewPostResultSerializer, root: false)
      backwards_compatible_json(json, result.success?)
    end

    private
    def create_params
      permitted = [
        :raw,
        :title,
        :topic_id,
        :archetype,
        :category,
        :auto_track,
        :typing_duration_msecs,
        :composer_open_duration_msecs
      ]

      result = params.permit(*permitted).tap do |whitelisted|
        whitelisted[:image_sizes] = params[:image_sizes]
        # TODO this does not feel right, we should name what meta_data is allowed
        whitelisted[:meta_data] = params[:meta_data]
      end

      PostRevisor.tracked_topic_fields.each_key do |f|
        params.permit(f => [])
        result[f] = params[f] if params.has_key?(f)
      end

      # Stuff we can use in spam prevention plugins
      result[:ip_address] = request.remote_ip
      result[:user_agent] = request.user_agent
      result[:referrer] = request.env["HTTP_REFERER"]

      result
    end

  end

  class ::Category
    after_save :reset_communities_categories_cache

    protected
    def reset_communities_categories_cache
      ::Guardian.reset_communities_categories_cache
    end
  end

  class ::Guardian

    @@allowed_communities_categories_cache = DistributedCache.new(SETTING_NAME)

    def self.reset_communities_categories_cache
      @@allowed_communities_categories_cache["allowed"] =
        begin
          Set.new(
            CategoryCustomField
              .where(name: SETTING_NAME, value: "true")
              .pluck(:category_id)
          )
        end
    end

    def communities_category?(category_id)
      self.class.reset_communities_categories_cache unless @@allowed_communities_categories_cache["allowed"]
      @@allowed_communities_categories_cache["allowed"].include?(category_id)
    end
  end

  add_to_serializer(:site, :communities_category_ids) { CategoryCustomField.where(name: SETTING_NAME, value: "true").pluck(:category_id) }

end
