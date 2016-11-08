import showModal from 'discourse/lib/show-modal';
import { ajax } from 'discourse/lib/ajax';

export default Ember.Controller.extend({
  communities: [],

  actions: {
    newCommunity() {
      showModal('new-community');
    }
  }
});
