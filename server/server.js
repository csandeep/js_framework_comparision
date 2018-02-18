var jsonServer = require('json-server')
var _us = require('underscore')
var fs = require('fs')
var request = require('sync-request');

// Returns an Express server
var server = jsonServer.create()

// Allow CORS with localhost
server.all("*", function (req, res, next) {
  res.header("Access-Control-Allow-Origin", "*");
  return next();
});

// Add custom routes before JSON Server router
var db = JSON.parse(fs.readFileSync('db.json'))

server.get('/tmposts', function (req, res) {
  var page = req.query.page ? req.query.page : 1;

  ajax_res = request('GET', "https://themighty.com/wp-json/wp/v2/posts/?per_page=10&page=" + page);
  res.jsonp(JSON.parse(ajax_res.getBody('utf8')));
});

// Use default middleware (logger, static, cors and no-cache)
var middlewares = jsonServer.defaults();
server.use(middlewares);

// Use default router
var router = jsonServer.router('db.json');
server.use(router);

server.listen(3000, function () {
  console.log()
  console.log('  🚀  Serving on http://localhost:3000')
  console.log()
})