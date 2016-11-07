import ModalFunctionality from 'discourse/mixins/modal-functionality';
import { ajax } from 'discourse/lib/ajax';

export default Ember.Controller.extend(ModalFunctionality, {
  name: "",
  slug: "",
  description: "",

  actions: {
    new: function() {
      const self = this;
      ajax("/communities", {
        type: "POST",
        data: {name: this.name, slug: this.slug, description: this.description}
      }).then(() => {
        self.send('closeModal');
      }).catch(e => {
        bootbox.alert(I18n.t("community.error.add") + ' ' + e.errorThrown);
      });
    }
  },
});
