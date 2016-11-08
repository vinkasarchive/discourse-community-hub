import Community from 'discourse/plugins/community-hub/discourse/models/community';

export default Discourse.Route.extend({

  titleToken() {
    return I18n.t('communities.title');
  },

  model(params) {
    return Community.findAll(params);
  },

});
