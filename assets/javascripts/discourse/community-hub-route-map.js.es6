export default {
  resource: 'communities',
  map() {
    this.route('communities', { resetNamespace: true }, function() {
      this.route('index', { path: '/' });
    });
  }
};
