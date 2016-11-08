# name: community-hub
# about: Community Hub plugin for Discourse
# version: 0.0.1
# authors: Vinoth Kannan (vinothkannan@vinkas.com)

enabled_site_setting :community_hub_enabled

register_custom_html extraNavItem: "<li id='communities-menu-item'><a href='/communities'>Communities</a></li>"

register_asset 'stylesheets/community-hub.scss'

PLUGIN_NAME ||= 'community-hub'.freeze
PLUGIN_STORE_NAME ||= 'community'.freeze

after_initialize do

  module ::CommunityHub
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace CommunityHub
    end
  end

  class CommunityHub::Community
    class << self

      def plugin_store_name
        PLUGIN_STORE_NAME
      end

      def add(name, slug, description, user)

        # TODO add i18n string
        raise StandardError.new "community.missing.name" if name.blank?
        raise StandardError.new "community.missing.slug" if slug.blank?
        raise StandardError.new "community.missing.description" if description.blank?

        id = SecureRandom.hex(16)
        record = {name: name, slug: slug, description: description, user_id: user.id}

        PluginStore.set(plugin_store_name, id, record)

        record
      end

      def all
        communities = Array.new
        result = PluginStoreRow.where(plugin_name: plugin_store_name)

        return communities if result.blank?

        result.each do |c|
          communities.push(PluginStore.cast_value(c.type_name, c.value))
        end

        communities
      end

      def findBySlug(slug)
        result = PluginStoreRow.where(plugin_name: plugin_store_name)
                               .where('value LIKE ?', ['%\"', slug,  '\"%'].join)

        result.each do |c|
          community = PluginStore.cast_value(c.type_name, c.value)
          return community if community['slug'].eql? slug
        end

        Array.new
      end

    end
  end

  CommunityHub::Engine.routes.draw do
    get "/communities" => "communities#index"
    post "/communities" => "communities#create"

    get "/m/:slug" => "communities#show"
  end

  Discourse::Application.routes.append do
    mount ::CommunityHub::Engine, at: "/"
  end

  require_dependency 'application_controller'

  class CommunityHub::CommunitiesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_filter :ensure_logged_in, only: [:create, :index]

    def show
      slug = params.require(:slug)
      community = CommunityHub::Community.findBySlug(slug)
      begin
        render json: community
      rescue StandardError => e
        render_json_error e.message
      end
    end

    def create
      name = params.require(:name)
      slug = params.require(:slug)
      description = params.require(:description)
      begin
        record = CommunityHub::Community.add(name, slug, description, current_user)
        render json: record
      rescue StandardError => e
        render_json_error e.message
      end
    end

    def index

      begin
        communities = CommunityHub::Community.all()
        render json: {communities: communities}
      rescue StandardError => e
        render_json_error e.message
      end
    end

  end

end
