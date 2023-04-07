require 'rails_helper'
require 'rspec/expectations'

RSpec.describe 'users/show', type: :view do
  before do
    assign(:user, user)
    assign(:games, [FactoryBot.build(:game)])
    stub_template 'users/_game.html.erb' => 'tmp'
  end

  let(:user) { FactoryBot.create(:user, name: 'Макс') }

  context 'when your page' do
    before do
      sign_in user
      render
    end

    it 'renders user name' do
      expect(rendered).to match 'Макс'
    end

    it 'renders partial' do
      expect(rendered).to have_content 'tmp'
    end

    it 'renders link' do
      expect(rendered).to match 'Сменить имя и пароль'
    end
  end

  context "when someone else's page" do
    before { render }

    it 'not render link' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end
  end
end
