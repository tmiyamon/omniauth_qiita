require 'omniauth/strategies/oauth2'
require 'multi_json'
require 'omniauth_qiita/no_authorization_team_mode_error'

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
          'urls'        => urls(raw_info)
        }
      end

      extra do
        { 'raw_info' => raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get('/api/v2/authenticated_user').parsed || {}
      rescue ::OAuth2::Error => origin_exception
        e = origin_exception.response.status == 403 ? OmniAuth::Qiita::NoAuthorizationTeamModeError : origin_exception
        raise e
      end

      def urls(raw_info)
        hash = {}

        [
          ['Facebook', 'facebook_id',         ->(id){"https://www.facebook.com/#{id}"}],
          ['Github',   'github_login_name',   ->(id){"https://github.com/#{id}"}],
          ['LinkedIn', 'linkedin_id',         ->(id){"https://www.linkedin.com/in/#{id}"}],
          ['Twitter',  'twitter_screen_name', ->(id){"https://twitter.com/#{id}"}],
          ['Website',  'website_url',         ->(url){url}]
        ].each do |label, key, url_gen|
          if raw_info.key? key and raw_info[key] and raw_info[key].length > 0
            hash[label] = url_gen.call(raw_info[key])
          end
        end

        hash
      end

      def authorize_params
        super.tap do |params|
          set_scope params
        end
      end

      def set_scope params
        params[:scope] ||= request.params['scope'] || DEFAULT_SCOPE
      end

      def build_params_for_access_token
        {
          code:          request.params['code'],
          client_id:     options.client_id,
          client_secret: options.client_secret
        }
      end

      def build_request_option_for_access_token
        {
          headers: { 'Content-Type' => 'application/json' },
          body:    MultiJson.dump(build_params_for_access_token),
        }.merge(options['token_params'])
      end

      def request_access_token
        client.request(:post, client.token_url, build_request_option_for_access_token).tap do |res|
          res.parsed['access_token'] = res.parsed.delete('token')
        end
      end

      def handle_access_token_response response
        error = Error.new(response)
        fail(error) if client.options[:raise_errors] && !(response.parsed.is_a?(Hash) && response.parsed['access_token'])
        ::OAuth2::AccessToken.from_hash(client, response.parsed.merge(deep_symbolize(options.auth_token_params)))
      end

      def build_access_token
        handle_access_token_response(request_access_token)
      end

      def callback_phase
        super
      rescue OmniAuth::Qiita::NoAuthorizationTeamModeError => e
        fail!(:no_authorization_team_mode, e)
      end
    end
  end
end
