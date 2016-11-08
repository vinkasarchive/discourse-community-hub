import { ajax } from 'discourse/lib/ajax';

const Community = Discourse.Model.extend({
});

Community.reopenClass({
  findAll(opts) {
    return ajax("/communities.json", { data: opts }).then(function (communities){
      return communities;
    });
  }
});

export default Community;
