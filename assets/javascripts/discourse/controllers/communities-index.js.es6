import showModal from 'discourse/lib/show-modal';

export default Ember.Controller.extend({
  communities: [],

  actions: {
    newCommunity() {
      showModal('new-community');
    }
  }
});
