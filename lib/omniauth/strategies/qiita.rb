require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Qiita < OmniAuth::Strategies::OAuth2
      option :name, "qiita"

      DEFAULT_SCOPE = 'read_qiita'

      option :client_options, {
        :site => "https://qiita.com",
        :authorize_url => "https://qiita.com/api/v2/oauth/authorize",
        :token_url => '/api/v2/access_tokens'
      }

      option :token_params, {
        parse: :json
      }

      option :authorize_options, [:scope]

      uid { raw_info['id'] }

      info do
        {
          'nickname'    => raw_info['id'],
          'name'        => raw_info['name'],
          'location'    => raw_info['location'],
          'image'       => raw_info['profile_image_url'],
          'description' => raw_info['description'],
          'urls       ' => urls(raw_info)
        }
      end

      extra do
        { 'raw_info' => raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get('/api/v2/authenticated_user').parsed || {}
      end

      def urls(raw_info)
        hash = {}

        [
          ['Facebook', 'facebook_id',         ->(id){"https://www.facebook.com/#{id}"}],
          ['Github',   'github_login_name',   ->(id){"https://github.com/#{id}"}],
          ['LinkedIn', 'linkedin_id',         ->(id){"https://www.linkedin.com/in/#{id}"}],
          ['Twitter',  'twitter_screen_name', ->(id){"https://twitter.com/#{id}"}],
          ['Website',  'website_url',         ->(url){url},]
        ].each do |label, key, url_gen|
          if raw_info.key? key and raw_info[key] and raw_info[key].length > 0
            hash[label] = url_gen.call(raw_info[key])
          end
        end

        hash
      end

      def authorize_params
        super.tap do |params|
          params[:scope] = request.params['scope'] || DEFAULT_SCOPE
        end
      end

      def build_access_token
        params = {
          code:          request.params['code'],
          client_id:     client.id,
          client_secret: client.secret
        }

        opts = {
          headers: { 'Content-Type' => 'application/json' },
          body:    params.to_json,
        }.merge(options['token_params'])

        response = client.request(:post, client.token_url, opts).tap do |res|
          res.parsed['access_token'] = res.parsed.delete('token')
        end

        error = Error.new(response)
        fail(error) if client.options[:raise_errors] && !(response.parsed.is_a?(Hash) && response.parsed['access_token'])
        ::OAuth2::AccessToken.from_hash(client, response.parsed.merge(deep_symbolize(options.auth_token_params)))
      end
    end
  end
end
