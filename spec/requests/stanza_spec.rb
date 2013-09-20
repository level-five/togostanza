# coding: utf-8

require 'spec_helper'

feature '表示のカスタマイズ' do
  scenario 'デフォルトでは stanza.css が使われる' do
    visit stanza_path('protein_names', tax_id: "1111708", gene_id: 'slr1311')

    expect(find('link[rel=stylesheet]')[:href]).to match(%r(/stanza.css$))
  end

  scenario 'css_uri を指定すると、代わりにそれが使われる' do
    visit stanza_path('protein_names', tax_id: "1111708", gene_id: 'slr1311', css_uri: 'http://example.com/my.css')

    expect(find('link[rel=stylesheet]')[:href]).to eq('http://example.com/my.css')
  end
end
