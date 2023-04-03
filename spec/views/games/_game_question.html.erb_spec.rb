require 'rails_helper'

RSpec.describe 'games/game_question', type: :view do
  let(:game_question) { FactoryBot.build_stubbed :game_question }

  before(:each) do
    allow(game_question).to receive(:text).and_return('Кому на Руси жить хорошо?')
    allow(game_question).to receive(:variants).and_return(
      { 'a' => 'Всем', 'b' => 'Никому', 'c' => 'Животным', 'd' => 'Людям' }
    )
  end

  it 'renders question text' do
    render_partial

    expect(rendered).to match 'Кому на Руси жить хорошо?'
  end

  context 'renders question variants' do
    before :each do
      render_partial
    end

    it 'a variant' do
      expect(rendered).to match 'Всем'
    end

    it 'b variant' do
      expect(rendered).to match 'Никому'
    end

    it 'c variant' do
      expect(rendered).to match 'Животным'
    end

    it 'd variant' do
      expect(rendered).to match 'Людям'
    end
  end

  context 'renders half variant if fifty-fifty used' do
    before :each do
      allow(game_question).to receive(:help_hash).and_return({ fifty_fifty: ['a', 'b'] })

      render_partial
    end

    it 'render a variant' do
      expect(rendered).to match 'Всем'
    end

    it 'render b variant' do
      expect(rendered).to match 'Никому'
    end

    it 'not render c variant' do
      expect(rendered).not_to match 'Животным'
    end

    it 'not render d variant' do
      expect(rendered).not_to match 'Людям'
    end
  end

  private

  def render_partial
    render partial: 'games/game_question', object: game_question
  end
end
