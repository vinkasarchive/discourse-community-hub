# name: community_hub
# about: Community Hub plugin for Discourse
# version: 0.0.1
# authors: Vinoth Kannan (vinothkannan@vinkas.com)

COMMUNITY_HUB = 'community_hub'.freeze

enabled_site_setting :community_hub_enabled

register_asset 'stylesheets/community_hub.scss'

after_initialize do

  module ::CommunityHub
    class Engine < ::Rails::Engine
      engine_name COMMUNITY_HUB
      isolate_namespace CommunityHub
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

  end

end
