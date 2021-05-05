const purgecss = require('@fullhuman/postcss-purgecss');

module.exports = {
  plugins: [
    require('tailwindcss'),
    require('autoprefixer'),
    purgecss({
      content: [
        '../lib/shoutouts_web/templates/**/*.html.eex',
        '../lib/shoutouts_web/live/**/*.html.leex',
      ],
      defaultExtractor: content => content.match(/[A-Za-z0-9\-_:\/]+/g) || []
    })
  ]
};
