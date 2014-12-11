require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Qiita < OmniAuth::Strategies::OAuth2
      # Give your strategy a name.
      option :name, "qiita"

      DEFAULT_SCOPE = 'read_qiita'

      # This is where you pass the options you would pass when
      # initializing your consumer from the OAuth gem.
      option :client_options, {
        :site => "https://qiita.com",
        :authorize_url => "https://qiita.com/api/v2/oauth/authorize",
        :token_url => '/api/v2/access_tokens'
      }

      option :token_params, {
        :parse => :json
      }

      option :authorize_options, [:scope]

      # These are called after authentication has succeeded. If
      # possible, you should try to set the UID without making
      # additional calls (if the user id is returned with the token
      # or as a URI parameter). This may not be possible with all
      # providers.
      uid { raw_info['client_id'] }

      info do
        {
          :name => raw_info['name'],
          :email => raw_info['email']
        }
      end

      extra do
        {
          'raw_info' => raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get('/api/v2/authenticated_user').parsed || {}
      end

      def authorize_params
        super.tap do |params|
          params[:scope] = request.params['scope'] || DEFAULT_SCOPE
        end
      end

      def build_access_token
        verifier = request.params['code']
        params = {
          code:          verifier,
          client_id:     client.id,
          client_secret: client.secret,
          headers: { 'Content-Type' => 'application/json' }
        }

        get_token(params, deep_symbolize(options.auth_token_params))
      end

      def get_token(params, access_token_opts = {}, access_token_class = ::OAuth2::AccessToken)
        opts = {:raise_errors => client.options[:raise_errors], :parse => params.delete(:parse)}
        if client.options[:token_method] == :post
          headers = params.delete(:headers)
          opts[:body] = params.to_json
          opts[:headers] =  {'Content-Type' => 'application/x-www-form-urlencoded'}
          opts[:headers].merge!(headers) if headers
        else
          opts[:params] = params
        end
        response = client.request(client.options[:token_method], client.token_url, opts).tap do |res|
          res.parsed['access_token'] = res.parsed['token']
        end

        error = Error.new(response)
        fail(error) if client.options[:raise_errors] && !(response.parsed.is_a?(Hash) && response.parsed['access_token'])
        access_token_class.from_hash(client, response.parsed.merge(access_token_opts))
      end
    end
  end
end
