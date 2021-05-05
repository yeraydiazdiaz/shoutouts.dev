/**
 * Remember production builds need `mix phx.digest`.
 */

const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const TerserPlugin = require('terser-webpack-plugin');
const OptimizeCSSAssetsPlugin = require('optimize-css-assets-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const CompressionPlugin = require("compression-webpack-plugin");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");

module.exports = (env, args) => {
  const config = {
    entry: {
      './js/app.js': './js/app.js'
    },
    output: {
      filename: 'js/app.js',
      path: path.resolve(__dirname, '../priv/static/'),
    },
    module: {
      rules: [
        {
          test: /\.js$/,
          exclude: /node_modules/,
          use: {
            loader: 'babel-loader'
          }
        },
        {
          test: /\.css$/,
          use: [
            MiniCssExtractPlugin.loader,
            'css-loader',
            'postcss-loader',  // see postcss.config.js
          ]
        },
        {
          test: /\.(eot|ttf|woff(2)?)(\?v=\d+\.\d+\.\d+)?/,
          loader: 'file-loader',
          options: {
            name: "[name].[ext]",
            outputPath: "fonts/",
            publicPath: "/fonts/"
          }
        },
        {
          test: /\.(svg)(\?v=\d+\.\d+\.\d+)?/,
          loader: 'url-loader',
        }
      ]
    },
    plugins: [
      new MiniCssExtractPlugin({
        filename: 'css/app.css',
        chunkFilename: 'css/app.css',
      }),
      new CopyWebpackPlugin([{ from: 'static/', to: '.' }]),
    ],
    optimization: {
      minimizer: [
        new TerserPlugin({ cache: true, parallel: true, sourceMap: false }),
        new OptimizeCSSAssetsPlugin({}),
      ]
    },
    devtool: "source-map",
  };

  if (args.mode === 'production') {
    config.plugins.unshift(new CleanWebpackPlugin()),
      config.plugins.push(
        // Create gzip and brotli compressed versions of our assets
        // Note the default compression ratio is 0.8 which may result
        // in some assets not generating compressed versions, like some PNG files
        new CompressionPlugin({
          test: /\.(js|css|png|jpg|svg|map)$/,
        }),
        new CompressionPlugin({
          filename: "[path].br",
          algorithm: "brotliCompress",
          test: /\.(js|css|png|jpg|svg|map)$/,
        }),
      );
  }

  return config;
};
