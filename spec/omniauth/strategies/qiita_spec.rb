require 'spec_helper'

describe OmniAuth::Strategies::Qiita do
  let(:request) { double('Request', :params => {}, :cookies => {}, :env => {}) }
  let(:app) {
    lambda do |env|
      [200, {}, ['Hello.']]
    end
  }

  subject do
    args = [app, 'appid', 'secret', @options || {}].compact
    OmniAuth::Strategies::Qiita.new(*args).tap do |strategy|
      allow(strategy).to receive(:request) { request }
    end
  end

  describe 'client options' do
    it 'should have correct name' do
      expect(subject.options.name).to eq('qiita')
    end

    it 'should have correct site' do
      expect(subject.options.client_options.site).to eq('https://qiita.com')
    end

    it 'should have correct authorize url' do
      expect(subject.options.client_options.authorize_url).to eq('https://qiita.com/api/v2/oauth/authorize')
    end

    it 'should have correct token url' do
      expect(subject.options.client_options.token_url).to eq('/api/v2/access_tokens')
    end
  end

  describe '#set_scope' do
    it 'does nothing if a scope option is passed' do
      params = { scope: 'a b c' }
      subject.set_scope(params)

      expect(params[:scope]).to eq 'a b c'
    end

    it 'sets read_qiita as default scope to scope in params' do
      params = {}
      subject.set_scope(params)

      expect(params[:scope]).to eq 'read_qiita'
    end
  end

  describe '#build_params_for_access_token' do
    it "returns obtained code, client id and client secret" do
      expect(subject.request).to receive(:params).and_return({ 'code' => '12345' })
      expect(subject.build_params_for_access_token).to eq({ code: '12345', client_id: 'appid', client_secret: 'secret' })
    end
  end

  describe '#build_request_option_for_access_token' do
    it "returns request options for json request and response" do
      params = { code: '12345', client_id: 'appid', client_secret: 'secret' }
      response_option = { parse: :json }

      expect(subject).to receive(:build_params_for_access_token).and_return(params)
      expect(subject).to receive(:options).and_return({ 'token_params' => response_option })

      expect(subject.build_request_option_for_access_token).to eq( {
          headers: { 'Content-Type' => 'application/json' },
          body:   MultiJson.dump(params)
        }.merge(response_option)
      )
    end
  end

  describe '#urls' do
    it "returns facebook url if facebook_id is in raw_info" do
      expect(subject.urls({ 'facebook_id' => 'test'})).to eq({'Facebook' => 'https://www.facebook.com/test'})
    end
    it "returns github url if github_login_name is in raw_info" do
      expect(subject.urls({ 'github_login_name' => 'test'})).to eq({'Github' => 'https://github.com/test'})
    end
    it "returns linkedin url if linkedin_id is in raw_info" do
      expect(subject.urls({ 'linkedin_id' => 'test'})).to eq({'LinkedIn' => 'https://www.linkedin.com/in/test'})
    end
    it "returns twitter url if twitter_screen_name is in raw_info" do
      expect(subject.urls({ 'twitter_screen_name' => 'test'})).to eq({'Twitter' => 'https://twitter.com/test'})
    end
    it "returns website url if website_url is in raw_info" do
      expect(subject.urls({ 'website_url' => 'http://test.com'})).to eq({'Website' => 'http://test.com'})
    end
  end

  describe '#callback_phase' do
    before do
      @options = { provider_ignores_state: true }
      stub_request(:post, 'https://qiita.com/api/v2/access_tokens')
        .to_return(status: 200, body: { token: 'token' }.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    context 'when the API response is 200' do
      let(:authenticated_user) do
        {
          'id' => 'yaotti',
          'name' => 'Hiroshige Umino',
          'location' => 'Tokyo, Japan',
          'profile_image_url' => 'https://si0.twimg.com/profile_images/2309761038/1ijg13pfs0dg84sk2y0h_normal.jpeg',
          'description' => 'Hello, world.'
        }
      end

      before do
        stub_request(:get, "https://qiita.com/api/v2/authenticated_user")
          .to_return(body: authenticated_user.to_json, headers: { 'Content-Type' => 'application/json' })
        allow(subject).to receive(:env) { { 'rack.session' => {} } }
      end

      it 'should set the API response into raw_info' do
        subject.callback_phase
        expect(subject.raw_info).to eq authenticated_user
      end
    end

    context 'when the API response is 403 ( the user is in the team only mode )' do
      before do
        stub_request(:get, 'https://qiita.com/api/v2/authenticated_user')
          .to_return(status: 403)
        allow(subject).to receive(:fail!)
      end

      it 'should call fail!' do
        subject.callback_phase
        expect(subject).to have_received(:fail!).with(:no_authorization_team_mode, kind_of(OmniAuth::Qiita::NoAuthorizationTeamModeError))
      end
    end
  end
end
