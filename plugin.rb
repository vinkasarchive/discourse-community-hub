# name: community-hub
# about: Community Hub plugin for Discourse
# version: 0.0.1
# authors: Vinoth Kannan (vinothkannan@vinkas.com)

enabled_site_setting :community_hub_enabled

register_asset 'stylesheets/community-hub.scss'

PLUGIN_NAME ||= 'community_hub'.freeze
STORE_NAME ||= "communities".freeze

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
    get "/" => "communities#index"
    post "/" => "communities#create"
  end

  Discourse::Application.routes.append do
    mount ::CommunityHub::Engine, at: "/communities"
  end

  require_dependency 'application_controller'

  class CommunityHub::CommunitiesController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    before_filter :ensure_logged_in

    def create
      name   = params.require(:name)
      description = params.require(:description)
      user_id  = current_user.id

      begin
        record = CommunityHub::Community.add(user_id, name, description)
        render json: record
      rescue StandardError => e
        render_json_error e.message
      end
    end

    def index

      begin
        communities = CommunityHub::Community.all()
        render json: {replies: communities}
      rescue StandardError => e
        render_json_error e.message
      end
    end

  end

end
