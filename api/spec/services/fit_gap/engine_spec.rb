# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FitGap::Engine do
  subject(:report) do
    described_class.new(portfolio: portfolio, vacancy: vacancy, gemini_client: gemini_client).call
  end

  let(:gemini_client) do
    instance_double(
      Gemini::HttpClient,
      generate_content: {
        'culture_narrative' => 'Culture fit narrative.',
        'overall_narrative' => 'Overall fit narrative.'
      }
    )
  end
  let(:portfolio) { create(:portfolio) }
  let(:vacancy) { create(:vacancy) }

  it 'emits the expected level and flags skills without an override' do
    create(:vacancy_skill, vacancy: vacancy, skill_label: 'React', expected_level: 3)
    create(:portfolio_skill, portfolio: portfolio, skill_label: 'React', ai_level: 2)

    expect(report.skill_comparisons.first).to include(
      'expected_level' => 3,
      'candidate_level' => 2,
      'delta' => -1,
      'result' => 'gap',
      'is_override' => false
    )
  end

  it 'uses the override level and flags the comparison as overridden' do
    create(:vacancy_skill, vacancy: vacancy, skill_label: 'React', expected_level: 3)
    skill = create(:portfolio_skill, portfolio: portfolio, skill_label: 'React', ai_level: 2)
    create(:assessor_override, portfolio_skill: skill, ai_level: 2, override_level: 4)

    expect(report.skill_comparisons.first).to include(
      'candidate_level' => 4,
      'delta' => 1,
      'result' => 'exceed',
      'is_override' => true
    )
  end

  it 'marks missing skills as not assessed without an override flag' do
    create(:vacancy_skill, vacancy: vacancy, skill_label: 'Kubernetes', expected_level: 4)

    expect(report.skill_comparisons.first).to include(
      'expected_level' => 4,
      'candidate_level' => nil,
      'result' => 'not_assessed',
      'is_override' => false
    )
  end
end
