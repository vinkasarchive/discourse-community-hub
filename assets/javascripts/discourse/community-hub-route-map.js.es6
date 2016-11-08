
export default function() {

  this.route('communities', { path: '/communities', resetNamespace: true }, function() {
    this.route('index', { path: '/' });
  });

  this.route('community', { path: '/m/:slug', resetNamespace: true });

};
