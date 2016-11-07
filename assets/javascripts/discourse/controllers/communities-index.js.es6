import showModal from 'discourse/lib/show-modal';

export default Ember.Controller.extend({
  actions: {
    newCommunity() {
      showModal('new-community');
    }
  }
});
