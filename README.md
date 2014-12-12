# OmniAuth Qiita &nbsp;[![Build Status](https://secure.travis-ci.org/tmiyamon/omniauth_qiita.png?branch=master)](https://travis-ci.org/tmiyamon/omniauth_qiita)

**These notes are based on master, please see tags for README pertaining to specific releases.**

Qiita OAuth2 Strategy for OmniAuth.

Supports the OAuth 2.0 server-side and client-side flows. Read the Qiita docs for more details: https://qiita.com/api/v2/docs

## Installing

Add to your `Gemfile`:

```ruby
gem 'omniauth_qiita'
```

Then `bundle install`.

## Usage

`OmniAuth::Strategies::Qiita` is simply a Rack middleware. Read the OmniAuth docs for detailed instructions: https://github.com/intridea/omniauth.

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :qiita, ENV['QIITA_CLIENT_ID'], ENV['QIITA_CLIENT_SECRET']
end
```

## Configuring

You can configure scope option, which you pass in to the `provider` method via a `Hash`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :qiita, ENV['QIITA_CLIENT_ID'], ENV['QIITA_CLIENT_SECRET'],
    :scope => 'read_qiita read_qiita_team write_qiita write_qiita_team'
end
```

## Auth Hash

Here's an example *Auth Hash* available in `request.env['omniauth.auth']`:

```ruby
{
  :provider => "qiita",
  :uid => "tmiyamon",
  :info => {
    :nickname => "tmiyamon",
    :name => "Takuya Miyamoto",
    :location => "Tokyo, Japan",
    :image => "https://....",
    :description => "An awesome engineer",
    :urls => {
      :Facebook => "https://www.facebook.com/...",
      :Github => "https://github.com/tmiyamon",
      :Twitter => "https://twitter.com/..."
    }
  },
  :credentials => {
    :token => "abc...",
    :expires => false
  },
  :extra => {
    :raw_info => {
      :description => "An awesome engineer",
      :facebook_id => "...",
      :followers_count => 5,
      :followees_count => 0,
      :github_login_name => "tmiyamon",
      :id => "tmiyamon",
      :items_count => 3,
      :linkedin_id => "",
      :location => "Tokyo, Japan",
      :name => "Takuya Miyamoto",
      :organization => "",
      :profile_image_url => "https://...",
      :twitter_screen_name => "...",
      :website_url => "http://tmiyamon.github.io"
    }
  }
}
```

The precise information available may depend on the permissions which you request.

## Contributing

1. Fork it ( https://github.com/tmiyamon/omniauth_qiita/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This software is released under the MIT License, see LICENSE.txt.
