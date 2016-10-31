import property from 'ember-addons/ember-computed-decorators';
import Category from 'discourse/models/category';

export default {
  name: 'extend-settings-for-open-community',
  before: 'inject-discourse-objects',
  initialize() {

    Category.reopen({
      @property('custom_fields.suppress_category_listing')
      links_category: {
        get(enableField) {
          return enableField === "true";
        },
        set(value) {
          value = value ? "true" : "false";
          this.set("custom_fields.suppress_category_listing", value);
          return value;
        }
      }

    });
  }
};
